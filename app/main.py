# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

from weblite import app, handle

@handle('/')
def root(ctx):
    return "Hello world"