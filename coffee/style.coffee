# Public Domain (-) 2013 The Open Map Authors.
# See the Open Map UNLICENSE file for details.

module.exports = (api) ->

    controlsHeight = 200
    controlsPadding = 20
    controlsWidth = 300

    api.add

        html:
            height: '100%'

        body:
            background: '#fff'
            fontFamily: 'proxima-nova'
            fontSize: '16px'
            height: '100%'
            margin: 0
            padding: 0

        a:
            color: '#f9002c'
            ':hover':
                textDecoration: 'none'

        '#atlas':
            height: "#{controlsHeight}px"
            width: '100%'

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

        '#content':
            margin: '20px auto'
            width: '800px'

        '#controls':
            background: '#f8f8f8'
            background: '#fff'
            float: 'left'
            height: "#{controlsHeight}px"
            padding: "#{controlsPadding}px"
            width: "#{controlsWidth - (2 * controlsPadding)}px"

        '#filters':
            listStyleType: 'none'
            margin: 0
            padding: 0

            li:
                cursor: 'pointer'
                float: 'left'
                marginBottom: '12px'
                marginRight: '10px'
                width: "#{((controlsWidth - (2 * controlsPadding)) - 20)/2}px"

        '#nav':
            fontFamily: 'museo'
            fontSize: '20px'
            lineHeight: '20px'
            padding: '20px'
            textAlign: 'center'

            a:
                color: '#000'
                textDecoration: 'none'
                padding: '20px'
                ':hover':
                    background: '#1a1a1a'
                    color: '#fff'

        '.admin-success':
            fontSize: '40px'
            marginBottom: '20px'

        '.button':
            background: '#ec5354'
            color: '#fff'
            display: 'block'
            margin: '20px auto'
            padding: '20px'
            width: '60%'
            textAlign: 'left'
            textDecoration: 'none'

        '.clear':
            clear: 'both'

        '.pad-more':
            paddingTop: '4px !important'

        '.skip-entry':
            background: '#f8f8ff'
            fontFamily: 'Monaco, monospace'
            fontSize: '14px'
            margin: '20px 0'

        '.skip-reason':
            color: '#f9002c'

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
