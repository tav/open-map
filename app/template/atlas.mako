<script src="//maps.googleapis.com/maps/api/js?libraries=places&key=${ctx.gmap_key}&sensor=false"></script>
<script>
    ATLAS_DATA = ${atlas_data};
    TYPES_DATA = ${types_data};
</script>
<div id="map-container">
    <div id="map"></div>
    <div id="map-filters"></div>
</div>
<div class="float-right">
    <input type="text" id="places" placeholder="" autofocus>
</div>
<div id="atlas-info">
    <div id="type-info">
        <div id="type-quote"></div>
        <div><span id="type-name"></span> <span id="type-desc"></span></div>
    </div>
</div>
