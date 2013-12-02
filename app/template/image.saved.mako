% if error:
<div class="alert">
    Error saving image:
    <div class="skip-entry">
        ${error|h}
    </div>
</div>
% else:
<div class="alert">${title|h} image successfully saved!</div>
<p>Please copy/paste the following into the appropriate spreadsheet cell:</p>
<input value="${data}" id="image-dimensions" autofocus>
% endif

<div>
    <br><br>
    <a href="/image.upload/${ctx.auth_key}">Upload another image</a>
</div>