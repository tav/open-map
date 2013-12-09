# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

module.exports = (api) ->

    controlsHeight = 200
    controlsPadding = 20
    controlsWidth = 300

    colorAlt = '#94003a'
    colorMain = '#302755'
    colorMainLight = '#403765'
    innerMargin = 80

    api.add

        html:
            height: '100%'

        body:
            background: '#fff'
            fontFamily: 'museo'
            fontSize: '16px'
            height: '100%'
            margin: 0
            padding: 0

        a:
            color: '#f9002c'
            ':hover':
                textDecoration: 'none'

        '#atlas-info':
            marginLeft: "#{innerMargin + 30}px"
            marginTop: '40px'

        '#browser-upgrade':
            background: '#ec5354'
            color: '#fff'
            fontSize: '40px'
            padding: '20px'
            margin: '40px 0px'
            textAlign: 'center'
            width: '100%'

            a:
                color: '#fff'
                ':hover':
                    textDecoration: 'none'

        '#image-dimensions':
            border: 0
            fontSize: '26px'
            fontFamily: 'museo'
            marginLeft: '150px'
            marginTop: '40px'
            outline: 'none'

        '#image-submit':
            background: colorMain
            border: '0px'
            color: '#fff'
            fontSize: '16px'
            fontFamily: 'museo'
            marginLeft: '450px'
            marginTop: '20px'
            padding: '10px'

        '#image-title':
            border: '1px solid #ccc'
            fontSize: '16px'
            fontFamily: 'museo'
            marginBottom: '20px'
            padding: '10px'
            width: '500px'

        '#map':
            width: '100%'

        '#map-container':
            borderTop: '2px dotted #000'
            margin: '0 auto'
            position: 'relative'

        '#map-filters':
            background: 'rgba(255,255,255,0.8)'
            height: '20px'
            paddingTop: '3px'
            position: 'absolute'
            width: '100%'
            zIndex: 200
            bottom: 0

            a:
                color: colorMain
                cursor: 'pointer'
                fontSize: '14px'
                padding: '3px'

        '#nav':
            fontFamily: 'veneer'
            fontSize: '40px'
            lineHeight: '40px'
            margin: "0 #{innerMargin}px"
            padding: '30px'

            a:
                color: '#aaa'
                textDecoration: 'none'
                paddingRight: '40px'
                ':hover':
                    color: colorMain

        '#places':
            borderTop: 0
            borderLeft: 0
            borderRight: 0
            borderBottom: '2px dashed #5E5C6B'
            marginTop: '40px'
            marginRight: "#{innerMargin + 30}px"
            outline: 'none'
            width: '200px'

        '#slide-info':
            marginLeft: "#{innerMargin + 30}px"
            marginTop: '30px'

        '#slides-container':
            height: '450px'
            overflow: 'hidden'
            position: 'relative'
            width: '100%'

        '#slides-nav':
            background: 'rgba(255,255,255,0.8)'
            fontSize: '25px'
            lineHeight: '40px'
            height: '40px'
            paddingLeft: "#{innerMargin + 28}px"
            paddingTop: '0px'
            position: 'absolute'
            width: '100%'
            zIndex: 200
            bottom: 0

        '#tweet-date':
            color: '#aaa'
            marginRight: '5px'
            textDecoration: 'none'
            ':hover':
                textDecoration: 'underline'

        '#tweet-message':
            color: colorAlt
            lineHeight: '30px'
            marginRight: '5px'
            textDecoration: 'none'
            ':hover':
                textDecoration: 'underline'

        '#tweet-user':
            color: colorMain
            marginRight: '5px'
            textDecoration: 'none'
            ':hover':
                textDecoration: 'underline'

        '#type-desc':
            color: colorAlt

        '#type-name':
            color: colorAlt
            fontWeight: 700

        '#type-quote':
            color: colorMain
            fontFamily: 'veneer'
            fontSize: '32px'
            lineHeight: '32px'
            marginBottom: '20px'

        '.action':
            background: colorMain
            border: '0px'
            color: '#fff'
            display: 'block'
            fontSize: '16px'
            margin: '20px 10px 30px 470px'
            padding: '10px'
            textAlign: 'right'
            textDecoration: 'none'
            width: '150px'

        '.alert':
            fontSize: '40px'
            marginBottom: '20px'

        '.clear':
            clear: 'both'

        '.float-right':
            float: 'right'
            marginLeft: '20px'

        '.inner':
            margin: "0 #{innerMargin}px"

        '.inner-content':
            margin: "0 #{innerMargin}px"
            padding: '10px 30px'


        '.new-input':
            border: '1px solid #ccc'
            fontSize: '16px'
            fontFamily: 'museo'
            marginBottom: '20px'
            padding: '10px'
            width: '500px'

        '#new-submit':
            background: colorMain
            border: '0px'
            color: '#fff'
            fontSize: '16px'
            fontFamily: 'museo'
            marginLeft: '450px'
            marginTop: '20px'
            padding: '10px'


        '.pad-more':
            paddingTop: '4px !important'

        '.selected-filter':
            color: "#{colorAlt} !important"

        '.selected-nav':
            color: '#302755 !important'

        '.skip-entry':
            background: '#f8f8ff'
            fontFamily: 'Monaco, monospace'
            fontSize: '14px'
            margin: '20px 0'

        '.skip-reason':
            color: '#f9002c'

        '.slide':
            backgroundSize: 'contain'
            cursor: 'pointer'
            position: 'absolute'

        '.slide-anim':
            transition: 'left 1s'

        '.slide-ctrl':
            color: colorMain
            cursor: 'pointer'
            float: 'left'
            width: '40px'

        '.slide-ctrl-cur':
            color: "#{colorAlt} !important"

        '.zoom-control':
            background: '#1a1a1a'
            color: '#fff'
            cursor: 'pointer'
            display: 'block'
            fontFamily: 'Monaco, monospace !important'
            fontSize: '22px !important'
            fontWeight: 300
            lineHeight: '22px'
            height: '30px'
            margin: '20px'
            paddingTop: '3px'
            textAlign: 'center'
            MozUserSelect: 'none'
            MsUserSelect: 'none'
            WebkitUserSelect: 'none'
            userSelect: 'none'
            width: '30px'

    # api.import "#{__dirname}/../css/leaflet.css"
