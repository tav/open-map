<!doctype html>
<meta charset=utf-8>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no">
<title>${ctx.site_title|h}</title>
<link rel="stylesheet" href="${STATIC("site.css")}">
<script src="//use.typekit.net/${ctx.typekit_id}.js"></script>
<script>
    try{Typekit.load();}catch(e){}
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    ga('create', 'UA-46017594-1', 'open.co');
    ga('send', 'pageview');
</script>
<body>
<div id="nav">
    <a class="${ctx.page == 'manifesto' and 'selected-nav' or ''}" href="/manifesto">Manifesto</a>
    <a class="${ctx.page == 'atlas' and 'selected-nav' or ''}" href="/atlas">Atlas</a>
    <a class="${ctx.page == 'movement' and 'selected-nav' or ''}" href="/movement">Movement</a>
    <a class="${ctx.page == 'apps' and 'selected-nav' or ''}" href="/apps">Apps</a>
    <a class="${ctx.page == 'invitation' and 'selected-nav' or ''}" href="/invitation">Invitation</a>
</div>
${content}
<script src="${STATIC('client.js')}"></script>
% if ctx.load_script:
<script>openmap.${ctx.load_script}()</script>
% endif