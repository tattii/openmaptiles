CREATE OR REPLACE FUNCTION railway_class(subclass TEXT, mapping_key TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN subclass IN ('station', 'halt', 'tram_stop', 'subway') THEN 'railway'
        ELSE subclass
    END;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION railway_network_class(railway TEXT, name TEXT, highspeed TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN highspeed = 'yes' THEN 'bullet'
        WHEN (railway = 'rail') AND (name LIKE 'JR%') THEN 'jr'
        WHEN railway = 'subway' THEN 'subway'
        ELSE 'railway'
    END;
$$ LANGUAGE SQL IMMUTABLE;
