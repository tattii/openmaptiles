
CREATE OR REPLACE VIEW poi_point AS (
    SELECT osm_id, geometry, name, name_en, name_de, tags, subclass, mapping_key, station
    FROM osm_poi_point
    WHERE (subclass != 'school') OR (subclass = 'school' AND (name LIKE '%小学校' OR name LIKE '%中学校' OR name LIKE '%高等学校'))
);

CREATE OR REPLACE VIEW poi_polygon_z12 AS (
    SELECT osm_id, geometry, name, name_en, name_de, tags, subclass, mapping_key, station
    FROM osm_poi_polygon_gen2
    WHERE (subclass != 'school') OR (subclass = 'school' AND (name LIKE '%小学校' OR name LIKE '%中学校' OR name LIKE '%高等学校'))
);

CREATE OR REPLACE VIEW poi_polygon_z13 AS (
    SELECT osm_id, geometry, name, name_en, name_de, tags, subclass, mapping_key, station
    FROM osm_poi_polygon_gen1
    WHERE (subclass != 'school') OR (subclass = 'school' AND (name LIKE '%小学校' OR name LIKE '%中学校' OR name LIKE '%高等学校'))
);

CREATE OR REPLACE VIEW poi_polygon_z14 AS (
    SELECT osm_id, geometry, name, name_en, name_de, tags, subclass, mapping_key, station
    FROM osm_poi_polygon
    WHERE (subclass != 'school') OR (subclass = 'school' AND (name LIKE '%小学校' OR name LIKE '%中学校' OR name LIKE '%高等学校'))
);


-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, name_de text, tags hstore, class text, subclass text, "rank" int) AS $$
    SELECT osm_id, geometry, NULLIF(name, '') AS name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    poi_class(subclass, mapping_key) AS class, subclass,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 100 * pixel_width)
            ORDER BY CASE WHEN name = '' THEN 2000 ELSE poi_class_rank(poi_class(subclass, mapping_key)) END ASC
        )::int AS "rank"
    FROM (
        -- etldoc: osm_poi_point ->  layer_poi:z14_
        SELECT * FROM poi_point
            WHERE geometry && bbox
                AND zoom_level >= 14
        UNION ALL
        -- etldoc: osm_poi_polygon ->  layer_poi:z14_
        SELECT * FROM poi_polygon_z14
            WHERE geometry && bbox
                AND zoom_level >= 14
        UNION ALL

        SELECT * FROM poi_polygon_z13
            WHERE geometry && bbox
                AND zoom_level = 13
        UNION ALL

        SELECT * FROM poi_polygon_z12
            WHERE geometry && bbox
                AND zoom_level = 12
        ) as poi_union
    ORDER BY "rank"
    ;
$$ LANGUAGE SQL IMMUTABLE;
