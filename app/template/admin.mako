<!doctype html>
<meta charset=utf-8>
<title>${ctx.site_title|h}</title>
<link rel="stylesheet" href="${STATIC("site.css")}">
<script src="//use.typekit.net/${ctx.typekit_id}.js"></script>
<script>
    try{Typekit.load();}catch(e){}
</script>
<body>
<div id="nav">
    <a href="/">Home</a><a class="selected-nav" href="/admin/${ctx.auth_key}">Admin</a>
</div>
<div class="inner-content">
% if content:
    ${content}
% else:
    Welcome!
    <ul>
        <br>
        <li><a href="/data.refresh/${ctx.auth_key}">Refresh Data</a></li>
        <br>
        <li><a href="/types.refresh/${ctx.auth_key}">Refresh Type Info</a></li>
        <br>
        <li><a href="/image.upload/${ctx.auth_key}">Upload Image</a></li>
        <br>
        <li><a href="/images/${ctx.auth_key}">Image List</a></li>
    </ul>
% endif
</div>