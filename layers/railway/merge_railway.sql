DROP TRIGGER IF EXISTS trigger_flag ON osm_railway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON railway.updates;

DROP MATERIALIZED VIEW IF EXISTS osm_railway_network CASCADE;


CREATE INDEX IF NOT EXISTS osm_railway_linestring_geometry_idx ON osm_railway_linestring2 USING gist(geometry);


CREATE MATERIALIZED VIEW osm_railway_network AS (
    SELECT
        (ST_Dump(geometry)).geom AS geometry,
        NULL::bigint AS osm_id,
        name,
        ''::text AS name_en,
        get_basic_names(delete_empty_keys(hstore(ARRAY['name',name])), geometry)
            || delete_empty_keys(hstore(ARRAY['name',name]))
            AS "tags",
        railway,
        network,
        highspeed
    FROM (
      SELECT
          ST_LineMerge(ST_Collect(geometry)) AS geometry,
          name,
          railway,
          network,
          highspeed
      FROM osm_railway_linestring2
      WHERE (name <> '') 
          AND ((railway = 'rail' AND usage = 'main') OR (railway != 'rail'))
      group by name, railway, network, highspeed
    ) AS railway_union
);
CREATE INDEX IF NOT EXISTS osm_railway_network_geometry_idx ON osm_railway_network USING gist(geometry);





-- Handle updates

CREATE SCHEMA IF NOT EXISTS railway;

CREATE TABLE IF NOT EXISTS railway.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION railway.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO railway.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION railway.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh railway';
    REFRESH MATERIALIZED VIEW osm_railway_network;
    DELETE FROM railway.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;


CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_railway_linestring
    FOR EACH STATEMENT
    EXECUTE PROCEDURE railway.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON railway.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE railway.refresh();

