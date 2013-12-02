# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

define 'openmap', (exports, root) ->

    doc = root.document
    doc.$ = doc.getElementById

    for feature in ['JSON', 'XMLHttpRequest', 'addEventListener']
        if not root[feature]?
            doc.body.innerHTML = '<div id="browser-upgrade">Sorry, <a href="http://browsehappy.com/">please upgrade</a> to a more modern browser.</div>'
            return

    exports.loadAtlas = ->

        gm = google.maps
        ge = gm.event

        map = null
        markers = []

        $atlasInfo = doc.$ 'atlas-info'

        $typeInfo = doc.$ 'type-info'
        $typeDesc = doc.$ 'type-desc'
        $typeName = doc.$ 'type-name'
        $typeQuote = doc.$ 'type-quote'

        $map = doc.$ 'map'
        $mapContainer = doc.$ 'map-container'
        $filters = doc.$ 'map-filters'
        $zoomControls = doc.createElement 'div'

        root.onresize = ->
            innerWidth = doc.documentElement.clientWidth - (2 * (80 + 30))
            # $atlas.style.height = "#{doc.documentElement.clientHeight - 60}px"
            $map.style.height = "500px"
            $mapContainer.style.height = "500px"
            $mapContainer.style.width = "#{innerWidth}px"
            $atlasInfo.style.width = "#{innerWidth - 300 - 20}px"
            # $atlas.style.width = "#{doc.documentElement.clientWidth - 300}px"

        root.onresize()

        addFilter = (idx, name, desc, quote) ->
            $el = doc.createElement 'a'
            if idx is -1
                $el.innerText = 'All'
            else
                idx = parseInt idx, 10
                $el.innerText = "##{name}"
            $el.onclick = ->
                if $el.className is 'selected-filter'
                    for marker in markers
                        marker.setMap map
                    $el.className = ''
                    $typeInfo.style.display = 'none'
                else
                    for marker in markers
                        if marker.__typ is idx
                            marker.setMap map
                        else
                            marker.setMap null
                    for el in $filters.childNodes
                        el.className = ''
                    $el.className = 'selected-filter'
                    $typeQuote.innerText = quote
                    $typeName.innerText = "##{name}"
                    $typeDesc.innerText = desc
                    $typeInfo.style.display = 'block'
                return
            $el.__typ = idx
            $filters.appendChild $el
            return

        icons = []
        for [name, idx, desc, quote] in TYPES_DATA
            addFilter idx, name, desc, quote
            icons[idx] = name.toLowerCase()

        for [typ, lat, lng, name] in ATLAS_DATA
            marker = new google.maps.Marker
                position: new google.maps.LatLng(lat, lng)
                title: name
                icon: "/fixed/#{icons[typ]}.png"
            marker.__typ = typ
            markers.push marker

        lowLayer = 'grey'
        highLayer = 'toner-lite'

        plusVisible = true
        minusVisible = false

        minZoom = 2
        maxZoom = 20
        zoomLevel = 2

        zoomControl = (text, handler) ->
            el = doc.createElement 'div'
            el.innerHTML = text
            if text is '-'
                el.className = 'zoom-control pad-more'
                el.style.visibility = 'hidden'
            else
                el.className = 'zoom-control'
            $zoomControls.appendChild el
            ge.addDomListener el, 'click', handler
            return el

        $zoomIn = zoomControl '+', ->
            level = map.getZoom()
            if level is maxZoom
                return
            map.setZoom(level + 1)
            return

        $zoomOut = zoomControl '-', ->
            level = map.getZoom()
            if level is minZoom
                return
            map.setZoom(level - 1)
            return

        grey = [{
            featureType: 'all'
            elementType: 'all'
            stylers: [
                saturation: -100
            ]}, {
            featureType: 'water'
            stylers: [
                lightness: 100
            ]}, {
            featureType: 'water'
            elementType: 'labels'
            stylers: [
                visibility: 'off'
            ]}, {
            featureType: 'administrative.province'
            elementType: 'labels'
            stylers: [
                visibility: 'off'
            ]}
        ]

        map = new gm.Map $map,
            center: new gm.LatLng(15, 0)
            disableDefaultUI: true
            mapTypeId: lowLayer
            mapTypeControlOptions:
                mapTypeIds: [lowLayer, highLayer]
            minZoom: minZoom
            maxZoom: maxZoom
            zoom: zoomLevel
            scrollwheel: false
            backgroundColor: '#ffffff'

        map.mapTypes.set lowLayer, new gm.StyledMapType(grey, name: 'grey')
        map.mapTypes.set highLayer, new gm.StamenMapType(highLayer)

        ge.addListener map, 'zoom_changed', ->
            level = map.getZoom()
            if level >= 10
                map.setMapTypeId highLayer
            else
                map.setMapTypeId lowLayer
            if level is minZoom
                if minusVisible
                    $zoomOut.style.visibility = 'hidden'
                    minusVisible = false
            else if level is maxZoom
                if plusVisible
                    $zoomIn.style.visibility = 'hidden'
                    plusVisible = false
            else
                if not plusVisible
                    $zoomIn.style.visibility = 'visible'
                    plusVisible = true
                if not minusVisible
                    $zoomOut.style.visibility = 'visible'
                    minusVisible = true
            return

        ge.addListener map, 'bounds_changed', ->
            return

        map.controls[gm.ControlPosition.RIGHT_TOP].push $zoomControls

        for marker in markers
            marker.setMap(map)

        topLeft = new google.maps.LatLng(-90, -180)
        bottomRight = new google.maps.LatLng(90, 180)
        noBounds = new google.maps.LatLngBounds topLeft, bottomRight

        places = new google.maps.places.Autocomplete doc.$('places'), bounds: noBounds
        ge.addListener places, 'place_changed', ->
            place = places.getPlace()
            if place.geometry?
                if place.geometry.viewport?
                    map.fitBounds place.geometry.viewport
                else
                    map.setCenter place.geometry.location
                    map.setZoom 16
                    # bounds = new google.maps.LatLngBounds()
                    # bounds.extend place.geometry.location
                    # map.fitBounds bounds
                    # ge.addListenerOnce map, 'idle', ->
                    #     map.setZoom 16
            return

        return

    return