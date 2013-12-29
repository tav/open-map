# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

import logging
import sys

from json import loads as decode_json, dumps as encode_json
from re import compile as compile_regex
from traceback import format_exception

from config import (
    ADMIN_SECRET, GMAP_KEY, SITE_TITLE, DATA_SPREADSHEET,
    TYPEKIT_ID, TYPES_SPREADSHEET, TWITTER_CONSUMER_KEY,
    TWITTER_CONSUMER_SECRET, TWITTER_ACCESS_TOKEN,
    TWITTER_ACCESS_SECRET, TWITTER_HOME_ACCOUNT
    )

from countries import COUNTRIES
from weblite import Context, NotFound, Redirect, app, handle
from tavutil.crypto import secure_string_comparison
from tavutil.exception import html_format_exception
from twitter import Client

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

create_key = db.Key.from_path
find_hashtags = compile_regex(r'(?i)(?<=\#)\w+').findall

ORDINALS = [
    '', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th',
    '8th', '9th', '10th', '11th', '12th', '13th', '14th',
    '15th', '16th', '17th', '18th', '19th', '20th', '21st',
    '22nd', '23rd', '24th', '25th', '26th', '27th', '28th',
    '29th', '30th', '31st'
    ]

MONTHS = {
    'Jan': 'January',
    'Feb': 'February',
    'Mar': 'March',
    'Apr': 'April',
    'May': 'May',
    'Jun': 'June',
    'Jul': 'July',
    'Aug': 'August',
    'Sep': 'September',
    'Oct': 'October',
    'Nov': 'November',
    'Dec': 'December'
}

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
    name = db.StringProperty(indexed=False)
    tags = db.StringListProperty()
    twitter = db.StringProperty(indexed=False)
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

def get_data2():
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
    return ''.join(new)

def parse_data():
    types_data = memcache.get('types.data')
    if not types_data:
        types_data = Meta.get_by_key_name('types').json
    types = dict((k, v) for k, v, _, _ in decode_json(types_data))
    logging.info(repr(types))
    data = decode_json(get_data())
    updated = data['feed']['updated']['$t']
    atlas = []; add_atlas = atlas.append
    mosaic = []; add_mosaic = mosaic.append
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
        web = entry['gsx$web']['$t'].strip()
        if web:
            if not (web.startswith('http://') or web.startswith('https://')):
                skip("Invalid website URL: %s" % repr(web)[1:])
                continue
            if web.count('http://') > 1:
                skip("Invalid website URL: %s" % repr(web)[1:])
                continue
            if ' ' in web:
                skip("Invalid website URL: %s" % repr(web)[1:])
                continue
        # established = entry['gsx$est']['$t'].strip()
        # if established:
        #     try:
        #         established = int(established)
        #     except:
        #         skip("Invalid Est. year: %s" % repr(web)[1:])
        #         continue
        # else:
        #     established = None
        desc = entry['gsx$desc']['$t'].strip()
        if desc:
            tags = find_hashtags(desc)
        else:
            tags = []
        if name == 'Fablab Kamakura':
            tags.append('Awesome')
        elif name == 'Special Place':
            logging.info("TAGS: %s" % tags)
            tags.append('Hackspace')
        ltags = [tag.lower() for tag in tags]
        ltype = type.lower()
        if ltype not in ltags:
            ltags.append(ltype)
            tags.append(type)
        twitter = entry['gsx$twitter']['$t'].strip()
        if twitter:
            if twitter.startswith('https://twitter.com/'):
                twitter_id = twitter[20:]
            elif twitter.startswith('https://www.twitter.com/'):
                twitter_id = twitter[24:]
            if '/' in twitter_id:
                skip("Invalid Twitter ID: %s" % repr(twitter)[1:])
                continue
            else:
                twitter = twitter_id
        facebook = entry['gsx$facebook']['$t'].strip()
        if facebook:
            if not (
                facebook.startswith('http://www.facebook.com') or
                facebook.startswith('https://www.facebook.com')
                ):
                skip("Invalid Facebook Link: %s" % repr(facebook)[1:])
                continue
        country = entry['gsx$country']['$t'].strip()
        if country and len(country) == 2:
            cupper = country.upper()
            if cupper in COUNTRIES:
                country = COUNTRIES[cupper]
        address = '<br>'.join(filter(None, [
            entry['gsx$address1']['$t'].strip(),
            entry['gsx$address2']['$t'].strip(),
            entry['gsx$address3']['$t'].strip(),
            entry['gsx$address4']['$t'].strip(),
            entry['gsx$postcode']['$t'].strip(),
            country,
        ]))
        add_atlas((types[type], lat, lng, name, desc))
        add_mosaic((name, tags))
        add_full((
            ident, name, ltags, twitter,
            encode_json((name, desc, tags, web, twitter, facebook, address))
            ))
    return updated, atlas, mosaic, full, skipped

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
        quote = entry['gsx$quote']['$t'].strip()
        types.append([name, i-1, desc, quote])
    types.sort()
    return updated, types, skipped

# -----------------------------------------------------------------------------
# Tweets
# -----------------------------------------------------------------------------

client = Client(
    TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET, TWITTER_ACCESS_TOKEN,
    TWITTER_ACCESS_SECRET
    )

def get_tweet(id):
    key = 'tweet.%s' % id
    tweet = memcache.get(key)
    if tweet:
        return tweet
    try:
        tweets = client.statuses.user_timeline(
            screen_name=id, count=1, exclude_replies=True, include_rts=False
            )
    except Exception, err:
        logging.error("Got error fetching tweets for %r: %s" % (id, err))
        meta = Meta.get_by_key_name(key)
        if meta:
            memcache.set(key, meta.json, 600)
            return meta.json
        tweets = []
    if tweets:
        tweet = tweets[0]
        date = tweet['created_at'].split()
        info = [tweet['user']['screen_name']]
        info.append("%s %s %s" % (MONTHS[date[1]], ORDINALS[int(date[2])], date[-1]))
        info.append(tweet['text'])
        info = encode_json(info)
    else:
        info = 'null'
    meta = Meta.get_or_insert(key_name=key, json=info)
    meta.json = info
    meta.put()
    memcache.set(key, info, 600)
    return info

# -----------------------------------------------------------------------------
# Admin Access
# -----------------------------------------------------------------------------

def is_auth(ctx, key):
    if secure_string_comparison(key, ADMIN_SECRET):
        ctx.auth_key = key
        return
    raise NotFound

# -----------------------------------------------------------------------------
# Images
# -----------------------------------------------------------------------------

def get_images():
    images = Meta.get_or_insert('images')
    if (not images) or (not images.json):
        images_data = {}
        cursor = None
        while 1:
            query = Image.all()
            if cursor:
                query = query.with_cursor(cursor)
            cursor = None
            i = 0
            for img in query.fetch(limit=101):
                i += 1
                if i == 100:
                    cursor = query.cursor()
                images_data[img.key().name()] = [img.width, img.height]
            if not cursor:
                break
        images.json = encode_json(images_data)
        images.put()
    images = images.json
    memcache.add('images', images, 60)
    return images

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
    data = memcache.get_multi('atlas.data', 'types.data', 'images')
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
    if 'images' in data:
        images = data['images']
    else:
        images = get_images()
    return {
        'atlas_data': atlas_data, 'types_data': types_data,
        'images': images
        }

@handle('invitation', ['invitation', 'site'])
def invitation(ctx):
    ctx.page = 'invitation'
    return

@handle('manifesto', ['manifesto', 'site'])
def manifesto(ctx, profile=None):
    ctx.load_script = 'loadSlides'
    ctx.page = 'manifesto'
    prefix = 'manifesto-slide-'
    tweet_key = 'tweet.%s' % TWITTER_HOME_ACCOUNT
    data = memcache.get_multi('manifesto.slides', tweet_key)
    if 'manifesto.slides' in data:
        slides = data['manifesto.slides']
    else:
        slides = []
        for img in Image.all().filter(
            '__key__ >=', create_key('Image', prefix)
            ).fetch(limit=10):
            key = img.key().name()
            if not key.startswith(prefix):
                break
            slides.append([key, img.width, img.height])
        slides = encode_json(slides)
        memcache.set('manifesto.data', slides, 60)
    if tweet_key in data:
        tweet = data[tweet_key]
    else:
        tweet = get_tweet(TWITTER_HOME_ACCOUNT)
    return {'slides': slides, 'tweet': tweet}

@handle('mosaic.js')
def mosaic_js(ctx):
    data = memcache.get_multi('mosaic.data', 'images')
    if 'mosaic.data' in data:
        mosaic_data = data['mosaic.data']
    else:
        mosaic = Meta.get_by_key_name('mosaic')
        mosaic_data = mosaic.json
        memcache.add('mosaic.data', mosaic_data, 60)
    if 'images' in data:
        images = data['images']
    else:
        images = get_images()
    ctx.response_headers['Content-Type'] = 'text/javascript; charset=utf-8'
    # ctx.cache_response(63)
    return "MOSAIC_DATA=%s;IMAGES=%s;" % (mosaic_data, images)

@handle('movement', ['movement', 'site'])
def movement(ctx):
    ctx.load_script = 'loadMosaic'
    ctx.page = 'movement'

@handle('new', ['new', 'site'])
def new(ctx):
    ctx.page = 'movement'
    return

@handle('profile', ['profile', 'site'])
def profile(ctx, id):
    ctx.load_script = 'loadProfile'
    ctx.page = 'movement'
    entry = Entry.get_by_key_name(id)
    if not entry:
        raise NotFound
    info = decode_json(entry.json)
    # related = {}
    # for tag in entry.tags:
    #     for e in Entry.all().filter('tags =', tag).run(limit=1000):
    #         ename = e.name
    #         if ename not in related:
    #             related[ename] = []
    #         related[ename].append(tag)
    tweet = None
    if entry.twitter:
        tweet = get_tweet(entry.twitter)
    # tweet = get_tweet('wikihouse')
    images = memcache.get('images')
    if not images:
        images = get_images()
    ident = entry.key().name()
    display_image = None
    images_data = decode_json(images)
    if ident in images_data:
        x, y = images_data[ident]
        display_image = int(y / (x/440.))
    ctx.norm_id = norm_id
    # ctx.cache_response(63)
    return {
        'display_image': display_image,
        'ident': ident,
        'info': info,
        'tweet': tweet,
        'twitter_id': entry.twitter
    }

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
        atlas_images = Meta.get_by_key_name('images')
        if atlas_images:
            atlas_images.json = ''
            atlas_images.put()
            memcache.delete('images')
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
def image_upload(ctx, key='', title=None):
    is_auth(ctx, key)
    path = '/image.save/%s' % ctx.auth_key
    return {
        'title': title,
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
        ctx.cache_response()
        return thumbnail
    ctx.response_headers['content-type'] = img.ctype
    ctx.response_headers['X-AppEngine-BlobKey'] = img.blob
    ctx.cache_response()
    return

@handle('images', ['images', 'admin'])
def image_list(ctx, key='', cursor=None):
    is_auth(ctx, key)
    q = Image.all()
    if cursor:
        q = q.with_cursor(cursor)
    images = []
    N = 50
    last = N - 1
    idx = None
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
        updated, atlas_data, mosaic_data, full, skipped = parse_data()
        updated = norm_datetime(updated)
        batch = []; add_entry = batch.append
        i = 0
        for ident, name, tags, twitter, json in full:
            entry = Entry(key=create_key('Entry', ident))
            entry.json = json
            entry.name = name
            entry.tags = tags
            entry.twitter = twitter
            entry.updated = updated
            i += 1
            add_entry(entry)
            if i == 100:
                db.put(batch)
                del batch[:]
                i = 0
        if batch:
            db.put(batch)
        atlas = Meta.get_or_insert('atlas')
        atlas.updated = updated
        atlas.json = encode_json(atlas_data, separators=(',', ':'))
        mosaic = Meta.get_or_insert('mosaic')
        mosaic.updated = updated
        mosaic.json = encode_json(mosaic_data, separators=(',', ':'))
        db.put([atlas, mosaic])
        memcache.set_multi({
            'atlas.data': atlas.json,
            'mosaic.data': mosaic.json,
            }, 60)
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
