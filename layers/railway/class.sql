CREATE OR REPLACE FUNCTION railway_class(subclass TEXT, mapping_key TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN subclass IN ('station', 'halt', 'tram_stop', 'subway') THEN 'railway'
        ELSE subclass
    END;
$$ LANGUAGE SQL IMMUTABLE;
