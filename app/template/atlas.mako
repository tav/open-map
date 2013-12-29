<script src="//maps.googleapis.com/maps/api/js?libraries=places&key=${ctx.gmap_key}&sensor=false"></script>
<script>
    ATLAS_DATA = ${atlas_data};
    TYPES_DATA = ${types_data};
    IMAGES = ${images};
</script>
<div id="map-container">
    <div id="map"></div>
    <div id="map-filters"></div>
</div>
<div class="float-right">
    <input type="text" id="places" placeholder="" autofocus>
</div>
<div id="atlas-info">
    <a href="/new" id="new-link">Add Entry</a>
    <div id="type-info">
        <div id="type-quote"></div>
        <div><span id="type-name"></span> <span id="type-desc"></span></div>
    </div>
    <div id="atlas-entry">
        <div id="atlas-photo"></div>
        <div id="atlas-text"></div>
    </div>
</div>
