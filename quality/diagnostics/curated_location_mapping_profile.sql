-- Summarize source-key coverage in the canonical location bridge.
-- Row counts may grow over time; missing keys and unmapped locations should stay at zero.
SELECT
  source_system,
  COUNT(*) AS row_count,
  COUNTIF(source_location_key IS NULL) AS missing_source_keys,
  COUNTIF(location_id IS NULL) AS unmapped_locations
FROM `de-gcp-lab.weather_curated.bridge_weather_source_location`
GROUP BY source_system
ORDER BY source_system;
