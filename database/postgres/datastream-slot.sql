-- ============================================================================
-- Datastream logical replication slot
-- Database: postgres
--
-- Run separately from publication creation.
-- The executing user must have REPLICATION privileges.
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_replication_slots
        WHERE slot_name = 'weather_datastream_slot'
    ) THEN
        PERFORM *
        FROM pg_create_logical_replication_slot(
            'weather_datastream_slot',
            'pgoutput'
        );
    END IF;
END
$$;


SELECT
    slot_name,
    plugin,
    slot_type,
    database,
    active
FROM pg_replication_slots
WHERE slot_name = 'weather_datastream_slot';