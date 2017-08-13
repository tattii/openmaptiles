DROP TRIGGER IF EXISTS trigger_flag ON osm_airport_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON airport.updates;


CREATE OR REPLACE FUNCTION convert_airport() RETURNS VOID AS $$
BEGIN
  INSERT INTO osm_aeroway_airport (osm_id, aeroway, name, geometry)
  (SELECT osm_id, aeroway, name, 
    CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
      THEN ST_Centroid(geometry)
      ELSE ST_PointOnSurface(geometry)
    END AS geometry
  FROM osm_aeroway_airport_polygon as polygon
  WHERE NOT EXISTS (SELECT 1 from osm_aeroway_airport as point WHERE point.name = polygon.name));
END;
$$ LANGUAGE plpgsql;

SELECT convert_airport();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS airport;

CREATE TABLE IF NOT EXISTS airport.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION airport.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO airport.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION airport.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh airport';
    PERFORM convert_airport();
    DELETE FROM airport.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_aeroway_airport
    FOR EACH STATEMENT
    EXECUTE PROCEDURE airport.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON airport.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE airport.refresh();
