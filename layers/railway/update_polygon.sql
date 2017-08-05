DROP TRIGGER IF EXISTS trigger_flag ON osm_railway_station_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON railway.updates;

-- etldoc:  osm_railway_station_polygon ->  osm_railway_station_polygon

CREATE OR REPLACE FUNCTION convert_railway_station() RETURNS VOID AS $$
BEGIN
  UPDATE osm_railway_station_polygon
  SET geometry =
           CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
           THEN ST_Centroid(geometry)
           ELSE ST_PointOnSurface(geometry)
    END
  WHERE ST_GeometryType(geometry) <> 'ST_Point';
  ANALYZE osm_railway_station_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT convert_railway_station();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS railway_station;

CREATE TABLE IF NOT EXISTS railway_station.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION railway_station.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO railway_station.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION railway_station.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh railway_station';
    PERFORM convert_railway_station();
    DELETE FROM railway_station.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_railway_station_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE railway_station.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON railway_station.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE railway_station.refresh();
