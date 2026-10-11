-- ============================================================================
-- Datastream publication
-- Database: postgres
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication
        WHERE pubname = 'weather_datastream_publication'
    ) THEN
        EXECUTE '
            CREATE PUBLICATION weather_datastream_publication
            FOR TABLE
                public.weather_stations,
                public.weather_observations
        ';
    ELSE
        EXECUTE '
            ALTER PUBLICATION weather_datastream_publication
            SET TABLE
                public.weather_stations,
                public.weather_observations
        ';
    END IF;
END
$$;


SELECT
    pubname,
    pubinsert,
    pubupdate,
    pubdelete,
    pubtruncate
FROM pg_publication
WHERE pubname = 'weather_datastream_publication';


SELECT
    pubname,
    schemaname,
    tablename
FROM pg_publication_tables
WHERE pubname = 'weather_datastream_publication'
ORDER BY schemaname, tablename;