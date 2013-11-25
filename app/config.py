# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

DEBUG = True
MAX_IMAGE_SIZE = 25165824 # 24MB

SECURE_COOKIE_DURATION = 30 * 86400

STATIC_HTTP_HOSTS = [
    "s1.open-map.appspot.com",
    "s2.open-map.appspot.com",
    "s3.open-map.appspot.com",
    ]

STATIC_HTTPS_HOSTS = ["open-map.appspot.com"]
STATIC_PATH = "/static/"

from secret import *