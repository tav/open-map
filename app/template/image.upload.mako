<form action="${upload_url}" enctype="multipart/form-data" method="POST">
    <input name="title" placeholder="Title" id="image-title" value="${title or ''|h}" autofocus required><br>
    <input name="file" type="file" required><br>
    <input type="submit" id="image-submit">
</form>