
CREATE OR REPLACE FUNCTION layer_railway(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, tags hstore, class text, subclass text, network text) AS $$
    -- station point
    SELECT osm_id, geometry, NULLIF(name, '') AS name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    tags,
    railway_class(subclass, mapping_key) AS class,
    subclass,
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

    UNION ALL

    -- railway linestring
    SELECT osm_id, geometry, name,
    name_en,
    ''::hstore AS tags,
    railway_network_class(railway, name, highspeed) AS class,
    railway AS subclass,
    network
    FROM (
	SELECT * FROM osm_railway_network_gen3
            WHERE geometry && bbox
                AND zoom_level = 9
        UNION ALL

	SELECT * FROM osm_railway_network_gen2
            WHERE geometry && bbox
                AND zoom_level BETWEEN 10 AND 11
        UNION ALL

	SELECT * FROM osm_railway_network_gen1
            WHERE geometry && bbox
                AND zoom_level = 12
        UNION ALL

	SELECT * FROM osm_railway_network
            WHERE geometry && bbox
                AND zoom_level >= 13
    ) as zoom_levels
    UNION ALL

    -- station building
    SELECT osm_id, geometry, ''::text AS name,
    ''::text AS name_en,
    ''::hstore AS tags,
    ''::text AS class,
    ''::text AS subclass,
    ''::text AS network
    FROM osm_station_building_polygon
            WHERE geometry && bbox
                AND zoom_level >= 14
    ;
$$ LANGUAGE SQL IMMUTABLE;
