
CREATE OR REPLACE FUNCTION layer_railway(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, tags hstore, class text, subclass text, network text) AS $$
    SELECT osm_id, geometry, NULLIF(name, '') AS name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    tags,
    railway_class(subclass, mapping_key) AS class, subclass,
    network
    FROM (
        SELECT * FROM osm_railway_station
            WHERE geometry && bbox
                AND zoom_level >= 12

        UNION ALL
        SELECT * FROM osm_railway_station_polygon
            WHERE geometry && bbox
                AND zoom_level >= 12
        ) as station_union
    ;
$$ LANGUAGE SQL IMMUTABLE;
