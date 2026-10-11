DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'weather_app'
    ) THEN
        CREATE ROLE weather_app LOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'datastream'
    ) THEN
        CREATE ROLE datastream LOGIN REPLICATION;
    END IF;
END
$$;


GRANT CONNECT ON DATABASE postgres TO weather_app;
GRANT USAGE ON SCHEMA public TO weather_app;

GRANT SELECT
ON weather_stations, weather_observations
TO weather_app;


GRANT CONNECT ON DATABASE postgres TO datastream;
GRANT USAGE ON SCHEMA public TO datastream;

GRANT SELECT
ON weather_stations, weather_observations
TO datastream;