<table>
% for img in images:
<tr>
    <td>
        ${img.title|h} (${img.width}x${img.height}) &mdash;
        [<a href="/image.delete/${ctx.auth_key}/${img.key().name()}">Delete</a>]
    </td>
</tr>
<tr>
    <td>
        <blockquote>
            <a href="/image.view/${img.key().name()}"><img src="/image.view/${img.key().name()}/500"></a>
        </blockquote>
    </td>
</tr>
% endfor
</table>

% if cursor:
<a href="/images/${ctx.auth_key}/${cursor}">More &gt;</a>
% endif