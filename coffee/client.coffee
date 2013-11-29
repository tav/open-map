# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

define 'openmap', (exports, root) ->

    doc = root.document
    doc.$ = doc.getElementById

    gm = google.maps
    ge = gm.event

    map = null
    markers = []

    $atlas = doc.$ 'atlas'
    $controls = doc.$ 'controls'
    $filters = doc.$ 'filters'
    $zoomControls = doc.createElement 'div'

    $controls.style.display = 'none'

    for feature in ['JSON', 'XMLHttpRequest']
        if not root[feature]?
            $atlas.innerHTML = '<div id="browser-upgrade">Sorry, <a href="http://browsehappy.com/">please upgrade</a> to a more modern browser.</div>'
            return

    root.onresize = ->
        # $atlas.style.height = "#{doc.documentElement.clientHeight - 60}px"
        $atlas.style.height = "500px"
        $atlas.style.width = "#{doc.documentElement.clientWidth}px"
        # $atlas.style.width = "#{doc.documentElement.clientWidth - 300}px"

    root.onresize()

    filterCount = 0
    addFilter = (idx, name) ->
        $el = doc.createElement 'li'
        if idx is -1
            $el.innerText = 'All'
        else
            idx = parseInt idx, 10
            $el.innerText = "#{name}s"
            filterCount += 1
            if filterCount % 2
                $el.className = 'clear'
        $el.onclick = ->
            if idx is -1
                for marker in markers
                    marker.setMap map
            else
                for marker in markers
                    if marker.__typ is idx
                        marker.setMap map
                    else
                        marker.setMap null
            return
        $filters.appendChild $el
        return

    addFilter -1
    for idx, name of MARKER_TYPES
        addFilter idx, name
        console.log idx
        console.log name

    # $filters.appendChild
    # $controls.innerHTML = controlsInner

    # markerImages = {}
    # for k, v of MARKER_ICONS
    #     markerImages[k] =

    for [typ, lat, lng, name] in MARKERS
        marker = new google.maps.Marker
            position: new google.maps.LatLng(lat, lng)
            title: name
            # icon: "/markers/#{MARKER_ICONS[typ]}.png"
            icon: "/markers/marker-red-10px.png"
        marker.__typ = typ
        markers.push marker

    lowLayer = 'grey'
    highLayer = 'toner-lite'

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

    map = new gm.Map $atlas,
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
        if level >= 11
            map.setMapTypeId highLayer
        else
            map.setMapTypeId lowLayer
        if level is minZoom
            $zoomOut.style.visibility = 'hidden'
        else if level is (minZoom + 1)
            $zoomOut.style.visibility = 'visible'
        else if level is (maxZoom - 1)
            $zoomIn.style.visibility = 'visible'
        else if level is maxZoom
            $zoomIn.style.visibility = 'hidden'
        return

    ge.addListener map, 'bounds_changed', ->
        # console.log map.getBounds()
        console.log "new bounds"
        return

    map.controls[gm.ControlPosition.RIGHT_TOP].push $zoomControls

    for marker in markers
        marker.setMap(map)

    return
