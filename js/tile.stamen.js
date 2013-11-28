(function(exports) {

/*
 * tile.stamen.js v1.2.4
 */

var SUBDOMAINS = " a. b. c. d.".split(" "),
    MAKE_PROVIDER = function(layer, type, minZoom, maxZoom) {
        return {
            "url":          ["http://{S}tile.stamen.com/", layer, "/{Z}/{X}/{Y}.", type].join(""),
            "type":         type,
            "subdomains":   SUBDOMAINS.slice(),
            "minZoom":      minZoom,
            "maxZoom":      maxZoom,
            "attribution":  [
                'Map tiles by <a href="http://stamen.com">Stamen</a>.',
                'Data by <a href="http://openstreetmap.org">OpenStreetMap</a>.'
            ].join(" ")
        };
    },
    PROVIDERS =  {
        "toner":        MAKE_PROVIDER("toner", "png", 0, 20),
        "terrain":      MAKE_PROVIDER("terrain", "jpg", 4, 18),
        "watercolor":   MAKE_PROVIDER("watercolor", "jpg", 1, 18)
    };

// set up toner and terrain flavors
setupFlavors("toner", ["hybrid", "labels", "lines", "background", "lite"]);
// toner 2010
setupFlavors("toner", ["2010"]);
// toner 2011 flavors
setupFlavors("toner", ["2011", "2011-lines", "2011-labels", "2011-lite"]);
setupFlavors("terrain", ["background"]);
setupFlavors("terrain", ["labels", "lines"], "png");

/*
 * Export stamen.tile to the provided namespace.
 */
exports.stamen = exports.stamen || {};
exports.stamen.tile = exports.stamen.tile || {};
exports.stamen.tile.providers = PROVIDERS;
exports.stamen.tile.getProvider = getProvider;

/*
 * A shortcut for specifying "flavors" of a style, which are assumed to have the
 * same type and zoom range.
 */
function setupFlavors(base, flavors, type) {
    var provider = getProvider(base);
    for (var i = 0; i < flavors.length; i++) {
        var flavor = [base, flavors[i]].join("-");
        PROVIDERS[flavor] = MAKE_PROVIDER(flavor, type || provider.type, provider.minZoom, provider.maxZoom);
    }
}

/*
 * Get the named provider, or throw an exception if it doesn't exist.
 */
function getProvider(name) {
    if (name in PROVIDERS) {
        return PROVIDERS[name];
    } else {
        throw 'No such provider (' + name + ')';
    }
}

/*
 * StamenMapType for Google Maps API V3
 * <https://developers.google.com/maps/documentation/javascript/>
 */
if (typeof google === "object" && typeof google.maps === "object") {
    google.maps.StamenMapType = function(name) {
        var provider = getProvider(name),
            subdomains = provider.subdomains;
        return google.maps.ImageMapType.call(this, {
            "getTileUrl": function(coord, zoom) {
                var numTiles = 1 << zoom,
                    wx = coord.x % numTiles,
                    x = (wx < 0) ? wx + numTiles : wx,
                    y = coord.y,
                    index = (zoom + x + y) % subdomains.length;
                return provider.url
                    .replace("{S}", subdomains[index])
                    .replace("{Z}", zoom)
                    .replace("{X}", x)
                    .replace("{Y}", y);
            },
            "tileSize": new google.maps.Size(256, 256),
            "name":     name,
            "minZoom":  provider.minZoom,
            "maxZoom":  provider.maxZoom
        });
    };
    // FIXME: is there a better way to extend classes in Google land?
    google.maps.StamenMapType.prototype = new google.maps.ImageMapType("_");
}

})(typeof exports === "undefined" ? this : exports);