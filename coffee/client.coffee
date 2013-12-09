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

    exports.loadSlides = ->

        if TWEET?

            $tweetUser = doc.$ 'tweet-user'
            $tweetDate = doc.$ 'tweet-date'
            $tweetMessage = doc.$ 'tweet-message'

            tweetLink = "https://twitter.com/#{TWEET[0]}"

            $tweetUser.href = tweetLink
            $tweetDate.href = tweetLink
            $tweetMessage.href = tweetLink

            $tweetUser.innerHTML = "@#{TWEET[0]}"
            $tweetDate.innerHTML = TWEET[1]
            $tweetMessage.innerHTML = TWEET[2]

        $slides = doc.$ 'slides-container'

        direction = 'right'
        ctrls = []
        loaders = []
        slides = []
        curIdx = 0

        loadSlide = (idx) ->
            ->
                if idx is curIdx
                    return
                $cur = slides[curIdx]
                $next = slides[idx]
                $next.className = 'slide'
                $next.style.display = 'block'
                if idx > curIdx
                    $next.style.display = 'block'
                    if (idx - curIdx) > 1
                        i = curIdx + 1
                        while i < idx
                            slides[i].style.display = 'none'
                            i++
                    $next.style.left = "#{$next.__left}px"
                    $cur.className = 'slide slide-anim'
                    $cur.style.left = "#{$cur.__left + $cur.__width}px"
                else
                    if (curIdx - idx) > 1
                        i = idx + 1
                        while i < curIdx
                            slides[i].style.display = 'none'
                            i++
                    $next.style.left = "#{$next.__left + $next.__width}px"
                    $next.className = 'slide slide-anim'
                    setTimeout(->
                        $next.style.left = "#{$next.__left}px"
                        return
                    , 0)
                ctrls[idx].className = 'slide-ctrl slide-ctrl-cur'
                ctrls[curIdx].className = 'slide-ctrl'
                curIdx = idx
                if curIdx is (slides.length - 1)
                    direction = 'left'
                else if curIdx is 0
                    direction = 'right'
                return

        nextSlide = ->
            if direction is 'right'
                loaders[curIdx+1]()
            else
                loaders[curIdx-1]()
            return

        root.onresize = ->
            $slides.innerHTML = ''
            $nav = doc.createElement 'div'
            $nav.id = 'slides-nav'
            idx = 0
            curIdx = 0
            direction = 'right'
            ctrls = []
            loaders = []
            slides = []
            screenWidth = doc.documentElement.clientWidth
            slideHeight = SLIDE_HEIGHT
            last = SLIDES.length - 1
            for [slide, width, height] in SLIDES
                $el = doc.createElement 'img'
                $el.src = "/image.view/#{slide}"
                $el.__idx = idx
                if width <= screenWidth
                    factor = screenWidth / width
                    height *= factor
                    width = screenWidth
                if height <= slideHeight
                    factor = slideHeight / height
                    width *= factor
                    height = slideHeight
                if height > slideHeight
                    diff = (height - slideHeight) / 2
                    $el.style.top = "-#{diff}px"
                if width > screenWidth
                    diff = (width - screenWidth) / 2
                    $el.style.left = "-#{diff}px"
                    left = -(diff)
                else
                    $el.style.left = '0px'
                    left = 0
                $el.style.zIndex = 100 - idx
                $el.width = width
                $el.height = height
                if idx isnt curIdx
                    $el.style.display = 'none'
                $el.onclick = nextSlide
                $el.__width = width
                $el.__left = left
                $el.className = 'slide'
                $slides.appendChild $el
                $ctrl = doc.createElement 'div'
                if idx is curIdx
                    $ctrl.className = 'slide-ctrl slide-ctrl-cur'
                else
                    $ctrl.className = 'slide-ctrl'
                $ctrl.innerHTML = '&bull;'
                loader = loadSlide idx
                idx += 1
                $ctrl.onclick = loader
                loaders.push loader
                ctrls.push $ctrl
                $nav.appendChild $ctrl
                slides.push $el
            $slides.appendChild $nav
            return

        root.onresize()

        return

    return