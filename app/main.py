# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

import logging
import sys

from json import loads as decode_json, dumps as encode_json
from re import compile as compile_regex
from traceback import format_exception

from config import (
    ADMIN_SECRET, GMAP_KEY, SITE_TITLE, DATA_SPREADSHEET,
    TYPEKIT_ID, TYPES_SPREADSHEET
    )

from weblite import Context, NotFound, Redirect, app, handle
from tavutil.crypto import secure_string_comparison
from tavutil.exception import html_format_exception

from google.appengine.api import images
from google.appengine.api import memcache
from google.appengine.api.urlfetch import fetch as urlfetch
from google.appengine.ext import blobstore
from google.appengine.ext import db

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------

DATA_URL = (
    'https://spreadsheets.google.com/feeds/list/%s/od6/public/values?alt=json'
    % DATA_SPREADSHEET
    )

TYPES_URL = (
    'https://spreadsheets.google.com/feeds/list/%s/od6/public/values?alt=json'
    % TYPES_SPREADSHEET
    )

find_hashtags = compile_regex(r"#(\w+)").findall

# -----------------------------------------------------------------------------
# Context Extensions
# -----------------------------------------------------------------------------

Context.gmap_key = GMAP_KEY
Context.page = None
Context.load_script = None
Context.site_title = SITE_TITLE
Context.typekit_id = TYPEKIT_ID

# -----------------------------------------------------------------------------
# Models
# -----------------------------------------------------------------------------

class Entry(db.Model):
    json = db.TextProperty()
    tags = db.StringListProperty()
    updated = db.StringProperty()

class Image(db.Model):
    blob = db.StringProperty(indexed=False)
    ctype = db.StringProperty(indexed=False)
    title = db.StringProperty(indexed=False)
    height = db.IntegerProperty(indexed=False)
    width = db.IntegerProperty(indexed=False)

class Meta(db.Model):
    json = db.TextProperty()
    updated = db.StringProperty(indexed=False)

# -----------------------------------------------------------------------------
# Spreadsheet Data
# -----------------------------------------------------------------------------

def get_data():
    logging.info("Fetching %s" % DATA_URL)
    resp = urlfetch(DATA_URL)
    if resp.status_code != 200:
        logging.error("Error fetching spreadsheet data: %s (%r)" % (
            resp.status_code, resp.content
            ))
        return
    return resp.content

def get_data():
    f = open('data.json', 'rb')
    data = f.read()
    return data

def norm_datetime(u):
    return 'd' + u.replace('-', '').replace(
        ':', ''
        ).replace('T', '').replace('Z', '').replace('.', '-')

def norm_id(s, valid_chars=set('abcdefghijklmnopqrstuvwxyz0123456789')):
    new = []; push = new.append
    dashed = 0
    for char in s:
        if char in valid_chars:
            dashed = 0
            push(char)
        elif dashed:
            continue
        else:
            dashed = 1
            push('-')
    return ''.join(new).strip('-')

def parse_data():
    types_data = memcache.get('types.data')
    if not types_data:
        types_data = Meta.get_by_key_name('types').json
    types = dict((k, v) for k, v, _, _ in decode_json(types_data))
    logging.info(repr(types))
    data = decode_json(get_data())
    updated = data['feed']['updated']['$t']
    brief = []; add_brief = brief.append
    full = []; add_full = full.append
    skipped = []
    i = 1
    entry = None
    def skip(reason, append=skipped.append):
        append((i, entry['content']['$t'], reason))
        return
    seen = set(); add_seen = seen.add
    for entry in data['feed']['entry']:
        i += 1
        name = entry['gsx$name']['$t'].strip()
        if not name:
            skip("The name cannot be empty")
            continue
        ident = norm_id(name.lower())
        if ident in seen:
            skip("There is already a record with the id %r" % ident)
            continue
        add_seen(ident)
        geo = entry['gsx$geo']['$t'].strip()
        if not geo:
            skip("The geo coordinates cannot be empty")
            continue
        geo_split = geo.split(',')
        if len(geo_split) != 2:
            skip("Invalid geo coordinates: %s" % repr(geo)[1:])
            continue
        try:
            geo_split = map(float, geo_split)
        except:
            skip("Invalid geo coordinates: %s" % repr(geo)[1:])
            continue
        lat, lng = geo_split
        if not (-90 <= lat <= 90):
            skip("Invalid latitude: %r" % lat)
            continue
        if not (-180 <= lng <= 180):
            skip("Invalid longitude: %r" % lng)
            continue
        type = entry['gsx$type']['$t'].strip()
        if type not in types:
            skip("Invalid record type: %s" % repr(type)[1:])
            continue
        img = entry['gsx$img']['$t'].strip()
        if img:
            try:
                imgx, imgy = map(int, img.split('x'))
            except Exception:
                skip("Invalid image value: %s" % repr(img)[1:])
                continue
        desc = entry['gsx$desc']['$t'].strip()
        add_brief((types[type], lat, lng, name, desc))
    return updated, brief, full, skipped

# -----------------------------------------------------------------------------
# Type Info
# -----------------------------------------------------------------------------

def get_types_data():
    logging.info("Fetching %s" % TYPES_URL)
    resp = urlfetch(TYPES_URL)
    if resp.status_code != 200:
        raise IOError("Error fetching spreadsheet data: %s (%r)" % (
            resp.status_code, resp.content
            ))
    return resp.content

def parse_types_data():
    data = decode_json(get_types_data())
    updated = data['feed']['updated']['$t']
    skipped = []
    i = 1
    entry = None
    def skip(reason, append=skipped.append):
        append((i, entry['content']['$t'], reason))
        return
    seen = set(); add_seen = seen.add
    types = []
    for entry in data['feed']['entry']:
        i += 1
        if entry['gsx$inuse']['$t'].strip() != 'Y':
            skip("This type is no longer in use")
            continue
        name = entry['gsx$name']['$t'].strip()
        if not name:
            skip("The name cannot be empty")
            continue
        if name in seen:
            skip("The type %s is already defined" % name)
            continue
        add_seen(name)
        desc = entry['gsx$desc']['$t'].strip()
        # if not desc:
        #     skip("The description cannot be empty")
        #     continue
        quote = entry['gsx$quote']['$t'].strip()
        types.append([name, i-1, desc, quote])
    types.sort()
    return updated, types, skipped

# -----------------------------------------------------------------------------
# Admin Access
# -----------------------------------------------------------------------------

def is_auth(ctx, key):
    if secure_string_comparison(key, ADMIN_SECRET):
        ctx.auth_key = key
        return
    raise NotFound

# -----------------------------------------------------------------------------
# Handlers
# -----------------------------------------------------------------------------

@handle('/')
def root(ctx):
    raise Redirect('/atlas')

@handle('apps', ['apps', 'site'])
def apps(ctx):
    ctx.page = 'apps'
    return

@handle('atlas', ['atlas', 'site'])
def atlas(ctx):
    ctx.load_script = 'loadAtlas'
    ctx.page = 'atlas'
    data = memcache.get_multi('atlas.data', 'types.data')
    if 'atlas.data' in data:
        atlas_data = data['atlas.data']
    else:
        atlas_data = Meta.get_by_key_name('atlas').json
        memcache.add('atlas.data', atlas_data, 60)
    if 'types.data' in data:
        types_data = data['types.data']
    else:
        types_data = Meta.get_by_key_name('types').json
        memcache.add('types.data', types_data, 60)
    return {'atlas_data': atlas_data, 'types_data': types_data}

@handle('invitation', ['invitation', 'site'])
def invitation(ctx):
    ctx.page = 'invitation'
    return

@handle('manifesto', ['manifesto', 'site'])
def manifesto(ctx):
    ctx.page = 'manifesto'
    return

@handle('movement', ['movement', 'site'])
def movement(ctx):
    ctx.page = 'movement'
    return

# -----------------------------------------------------------------------------
# Admin Handlers
# -----------------------------------------------------------------------------

@handle('admin', ['admin'])
def admin(ctx, key=''):
    is_auth(ctx, key)

@handle('image.delete', ['image.delete', 'admin'])
def image_upload(ctx, key='', ref=None):
    is_auth(ctx, key)
    image = Image.get_by_key_name(ref)
    if not image:
        raise NotFound
    title = image.title
    image.delete()
    return {'title': title}

@handle('image.save', blob=True)
def image_save(ctx, key='', title=None, file=None):
    is_auth(ctx, key)
    try:
        if file.content_type not in ('image/jpeg', 'image/png', 'image/jpg'):
            raise TypeError("Uploaded image needs to be JPEG or PNG.")
        title = title.strip()
        if not title:
            raise ValueError("Title cannot be empty")
        blobref = str(file.key())
        img = images.Image(blob_key=blobref)
        img.im_feeling_lucky()
        img.execute_transforms(parse_source_metadata=True, output_encoding=images.JPEG, quality=1)
        ent = Image(key_name=norm_id(title.lower()))
        ent.ctype = file.content_type
        ent.title = title
        ent.blob = blobref
        ent.width = img.width
        ent.height = img.height
        ent.put()
    except Exception, err:
        file.delete()
        raise Redirect(ctx.compute_url('image.saved', key=key, error=str(err)))
    raise Redirect(ctx.compute_url(
        'image.saved', key=key, title=title,
        data='%sx%s' % (ent.width, ent.height)
        ))

@handle('image.saved', ['image.saved', 'admin'])
def image_saved(ctx, key='', data=None, error=None, title=None):
    is_auth(ctx, key)
    return {'error': error, 'data': data, 'title': title}

@handle('image.upload', ['image.upload', 'admin'])
def image_upload(ctx, key=''):
    is_auth(ctx, key)
    path = '/image.save/%s' % ctx.auth_key
    return {
        'upload_url': blobstore.create_upload_url(path)
    }

@handle('image.view')
def image_view(ctx, ref, width=0, height=0, quality=85):
    img = Image.get_by_key_name(ref)
    if not img:
        raise NotFound
    if width or height:
        img = images.Image(blob_key=img.blob)
        img.resize(width=int(width), height=int(height))
        thumbnail = img.execute_transforms(
            output_encoding=images.JPEG, quality=int(quality)
            )
        ctx.response_headers['content-type'] = 'image/jpeg'
        return thumbnail
    ctx.response_headers['content-type'] = img.ctype
    ctx.response_headers['X-AppEngine-BlobKey'] = img.blob
    return

@handle('images', ['images', 'admin'])
def image_list(ctx, key='', cursor=None):
    is_auth(ctx, key)
    q = Image.all()
    if cursor:
        q = q.with_cursor(cursor)
    cursor = None
    images = []
    N = 2
    last = N - 1
    for idx, img in enumerate(q.run(limit=N+1)):
        if idx == N:
            break
        images.append(img)
        if idx == last:
            cursor = q.cursor()
    if idx != N:
        cursor = None
    return {'images': images, 'cursor': cursor}

@handle('data.refresh', ['refresh', 'admin'])
def data_refresh(ctx, key=''):
    is_auth(ctx, key)
    try:
        updated, brief, full, skipped = parse_data()
        meta = Meta.get_or_insert('atlas')
        meta.updated = norm_datetime(updated)
        meta.json = encode_json(brief, separators=(',', ':'))
        meta.put()
        memcache.set('atlas.data', meta.json, 60)
    except Exception, err:
        logging.critical(''.join(format_exception(*sys.exc_info())))
        traceback = ''.join(html_format_exception())
        return {
            'alert': "Error updating data: <div class='skip-entry'>%s</div>" % traceback,
            'skipped': []
            }
    return {'alert': 'Data successfully updated!', 'skipped': skipped}

@handle('types.refresh', ['refresh', 'admin'])
def types_refresh(ctx, key=''):
    is_auth(ctx, key)
    try:
        updated, data, skipped = parse_types_data()
        meta = Meta.get_or_insert('types')
        meta.updated = norm_datetime(updated)
        meta.json = encode_json(data, separators=(',', ':'))
        meta.put()
        memcache.set('types.data', meta.json, 60)
    except Exception, err:
        logging.critical(''.join(format_exception(*sys.exc_info())))
        traceback = ''.join(html_format_exception())
        return {
            'alert': "Error updating types: <div class='skip-entry'>%s</div>" % traceback,
            'skipped': []
            }
    return {'alert': 'Types successfully updated!', 'skipped': skipped}
