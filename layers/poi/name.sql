DO $$
BEGIN
  update osm_poi_point SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_poi_polygon SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;

-- name:ja
update osm_poi_point SET name = tags -> 'name:ja' WHERE tags ? 'name:ja';
update osm_poi_polygon SET name = tags -> 'name:ja' WHERE tags ? 'name:ja';
update osm_poi_polygon_gen1 SET name = tags -> 'name:ja' WHERE tags ? 'name:ja';
update osm_poi_polygon_gen2 SET name = tags -> 'name:ja' WHERE tags ? 'name:ja';

-- remove (...)
update osm_poi_point SET name = regexp_replace(name, '\(.*\)', '') WHERE name LIKE '%(%)';
update osm_poi_polygon SET name = regexp_replace(name, '\(.*\)', '') WHERE name LIKE '%(%)';
update osm_poi_polygon_gen1 SET name = regexp_replace(name, '\(.*\)', '') WHERE name LIKE '%(%)';
update osm_poi_polygon_gen2 SET name = regexp_replace(name, '\(.*\)', '') WHERE name LIKE '%(%)';
