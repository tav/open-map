<script src="/mosaic.js"></script>
% if tweet:
<script>
TWEET = ${tweet};
</script>
% endif
<%
    name, desc, tags, website, twitter, facebook, address = info
    name_len = len(name)
    desc_split = desc.split('\n')
    if desc_split[-1].strip().startswith('#'):
        desc = '\n'.join(desc_split[:-1])
    descs = "Could you let me know a) the operating system your using b) the version of wikihouse plugin (the original or latest version) and c) the error message (if any) that is displayed either as a popup or on the ruby console."
%>
<table id="profile"><tr>
<td id="profile-image">
% if display_image:
<img src="/image.view/${ident}/440" width="440px" height="${display_image}px">
% elif (name_len % 3) == 0:
<div id="profile-image-blank" style="height: 264px"></div>
% elif (name_len % 2) == 0:
<div id="profile-image-blank" style="height: 352px"></div>
% else:
<div id="profile-image-blank" style="height: 528px"></div>
% endif
</td>
<td id="profile-info">
<div id="profile-title" data-ident="${ident}">${name|h}</div>
% if desc:
<div>${desc|h}</div>
<br>
% endif
% if website:
<div><a href="${website}" class="link">${website}</a></div>
<br>
% endif
% if address:
<div>${address}</div>
<br><br>
% endif
% if facebook:
<div>
    <a href="${facebook}"><img src="/fixed/facebook.png" width="24px" height="24px" class="absmiddle"></a>
    &nbsp;<a href="${facebook}" class="link">Follow on Facebook</a>
</div>
<br>
% endif
% if tweet:
<div>
    <a href="https://twitter.com/${twitter_id}"><img src="/fixed/twitter.png" width="24px" height="24px" class="absmiddle"></a>
    &nbsp;<a href="https://twitter.com/${twitter_id}" class="link">Follow on Twitter</a>
    <br><br>
    <table id="tweet"><tr>
        <td id="tweet-user-wrap"><a id="tweet-user"></a></td>
        <td id="tweet-date-wrap"><a id="tweet-date"></a></td>
        <td><a id="tweet-message"></a></td>
    </tr></table>
</div>
% endif
</td></tr></table>
<table id="profile-related"><tr>
<td class="profile-scroll-control"><a id="scroll-left">&lt;</a></td>
<td><div id="profile-related-images"></div></td>
<td class="profile-scroll-control"><a id="scroll-right">&gt;</a></td>
</tr></table>
<div id="profile-tags" class="pad-content">
% for tag in sorted(tags):
<a rel="${tag}" class="profile-tag">#${tag}</a>
% endfor
</div>