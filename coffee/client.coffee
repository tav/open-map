# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

define 'openmap', (exports, root) ->

    doc = root.document
    doc.$ = doc.getElementById

    for feature in ['JSON', 'XMLHttpRequest', 'addEventListener']
        if not root[feature]?
            doc.body.innerHTML = '<div id="browser-upgrade">Sorry, <a href="http://browsehappy.com/">please upgrade</a> to a more modern browser.</div>'
            return

    validChars = {'1': 1, '0': 1, '3': 1, '2': 1, '5': 1, '4': 1, '7': 1, '6': 1, '9': 1, '8': 1, 'a': 1, 'c': 1, 'b': 1, 'e': 1, 'd': 1, 'g': 1, 'f': 1, 'i': 1, 'h': 1, 'k': 1, 'j': 1, 'm': 1, 'l': 1, 'o': 1, 'n': 1, 'q': 1, 'p': 1, 's': 1, 'r': 1, 'u': 1, 't': 1, 'w': 1, 'v': 1, 'y': 1, 'x': 1, 'z': 1}

    genID = (name) ->
        name = name.toLowerCase()
        id = []
        dashed = false
        for i in [0...name.length]
            char = name.charAt i
            if validChars[char]
                dashed = false
                id.push char
            else if dashed
                continue
            else
                dashed = true
                id.push '-'
        return id.join ''

    hide = (el) ->
        el.style.display = 'none'
        return

    show = (el) ->
        el.style.display = 'block'
        return

    exports.loadAtlas = ->

        gm = google.maps
        ge = gm.event

        map = null
        markers = []

        $atlasInfo = doc.$ 'atlas-info'
        $newLink = doc.$ 'new-link'
        $atlasEntry = doc.$ 'atlas-entry'
        $atlasPhoto = doc.$ 'atlas-photo'
        $atlasText = doc.$ 'atlas-text'

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
            innerHeight = doc.documentElement.clientHeight - 300
            if innerHeight > 500
                innerHeight = 500
            else if innerHeight < 200
                innerHeight = 200
            $map.style.height = "#{innerHeight}px"
            $mapContainer.style.height = "#{innerHeight}px"
            $mapContainer.style.width = "#{innerWidth}px"
            $atlasInfo.style.width = "#{innerWidth - 220}px"

        root.onresize()

        typeSelected = false
        addFilter = (idx, name, desc, quote) ->
            $el = doc.createElement 'a'
            if idx is -1
                $el.innerText = 'All'
            else
                idx = parseInt idx, 10
                $el.innerText = "##{name}"
            $el.onclick = ->
                hide $atlasEntry
                if $el.className is 'selected-filter'
                    typeSelected = false
                    for marker in markers
                        marker.setMap map
                    $el.className = ''
                    hide $typeInfo
                    show $newLink
                else
                    typeSelected = true
                    for marker in markers
                        if marker.__typ is idx
                            marker.setMap map
                        else
                            marker.setMap null
                    for el in $filters.childNodes
                        el.className = ''
                    $el.className = 'selected-filter'
                    hide $newLink
                    $typeQuote.innerText = quote
                    $typeName.innerText = "##{name}"
                    $typeDesc.innerText = desc
                    show $typeInfo
                return
            $el.__typ = idx
            $filters.appendChild $el
            return

        icons = []
        for [name, idx, desc, quote] in TYPES_DATA
            addFilter idx, name, desc, quote
            icons[idx] = name.toLowerCase()

        addMarkerInfo = (marker, name, desc) ->
            id = genID name
            if xy = IMAGES[id]
                x = xy[0]
                y = xy[1]
            else
                x = y = 0
            ge.addListener marker, 'click', ->
                doc.location = "/profile/#{id}"
                return
            ge.addListener marker, 'mouseover', ->
                if x is 0
                    nl = name.length
                    $atlasPhoto.innerHTML = '&nbsp;'
                    if (nl % 3) is 0
                        $atlasPhoto.style.width = '200px'
                    else if (nl % 2) is 0
                        $atlasPhoto.style.width = '150px'
                    else
                        $atlasPhoto.style.width = '100px'
                else
                    photoWidth = Math.round(x / (y / 120))
                    $atlasPhoto.style.width = "#{photoWidth}px"
                    $atlasPhoto.innerHTML = "<img src='/image.view/#{id}/0/120' height='120px' width='#{photoWidth}px'>"
                hide $typeInfo
                hide $newLink
                show $atlasEntry
                ndesc = desc.replace('\r\n', '<br><br>').replace('\n\r', '<br><br>').replace('\r', '<br><br>').replace('\n', '<br><br>')
                $atlasText.innerHTML = "<strong>#{name}</strong><br><br>#{ndesc}"
                return
            ge.addListener marker, 'mouseout', ->
                hide $atlasEntry
                if typeSelected
                    show $typeInfo
                else
                    show $newLink
                return
            return

        for [typ, lat, lng, name, desc] in ATLAS_DATA
            marker = new google.maps.Marker
                position: new google.maps.LatLng(lat, lng)
                title: name
                icon: "/fixed/#{icons[typ]}.png"
            marker.__typ = typ
            markers.push marker
            addMarkerInfo marker, name, desc

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

    exports.loadMosaic = ->
        console.log MOSAIC_DATA
        return

    exports.loadProfile = ->
        loadTweet()
        all = []
        seen = {}
        curTags = []
        curIdent = doc.$('profile-title').getAttribute('data-ident')
        addCtrl = (elem, tag) ->
            elem.onmouseover = ->
                for [el, _, tags] in all
                    if tags.indexOf(tag) is -1
                        el.className = 'dim'
                    else
                        el.className = ''
                return
            elem.onmouseout = ->
                for [el, _, _] in all
                    el.className = ''
                return
            return
        for elem in document.getElementsByClassName('profile-tag')
            tag = elem.rel
            curTags.push tag
            addCtrl elem, tag
        for [name, tags] in MOSAIC_DATA
            ident = genID name
            if ident is curIdent
                continue
            for placeTag in tags
                for tag in curTags
                    if tag == placeTag
                        if (match = seen[ident])
                            seen[ident][2].push tag
                        else
                            elem = doc.createElement 'a'
                            if (aspect = IMAGES[ident])
                                [x, y] = aspect
                                width = Math.round((x/y) * 90)
                                elem.style.background = "url('/image.view/#{ident}/0/120')"
                            else
                                nl = name.length
                                if (nl % 3) is 0
                                    width = 150
                                else if (nl % 2) is 0
                                    width = 112
                                else
                                    width = 75
                            elem.href = "/profile/#{ident}"
                            elem.title = name
                            elem.style.width = "#{width}px"
                            elem.innerHTML = "<div>#{name}</div>"
                            val = [elem, name, [tag]]
                            seen[ident] = val
                            all.push val
                        break
        all.sort((a, b) ->
            a2 = a[2].length
            b2 = b[2].length
            if a2 > b2
                return -1
            if a2 < b2
                return 1
            a1 = a[1]
            b1 = b[1]
            if a1 > b1
                return 1
            if a1 < b1
                return -1
            return 0
        )
        parent = doc.$ 'profile-related-images'
        root.onresize = ->
            innerWidth = doc.documentElement.clientWidth - (2 * (80 + 30))
            parent.style.width = "#{innerWidth}px"
            return
        root.onresize()
        for [elem, _, _] in all
            parent.appendChild elem
        $left = doc.$ 'scroll-left'
        $right = doc.$ 'scroll-right'
        parent.onscroll = ->
            maxScroll = parent.scrollWidth - parent.clientWidth
            if maxScroll is 0
                hide $left
                hide $right
                return
            left = parent.scrollLeft
            if left is 0
                hide $left
            else
                show $left
            if left is maxScroll
                hide $right
            else
                show $right
            return
        $left.onclick = ->
            parent.scrollLeft -= parent.clientWidth
            return
        $right.onclick = ->
            parent.scrollLeft += parent.clientWidth
            return
        parent.onscroll()
        return

    loadTweet = ->

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

        return

    exports.loadSlides = ->

        loadTweet()
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