-- Profile point observations by source. Counts and ranges are descriptive;
-- they are not fixed expected row counts and may change as source data grows.
SELECT
  source_system,
  COUNT(*) AS row_count,
  COUNTIF(source_location_key IS NULL) AS missing_source_location_keys,
  COUNTIF(location_id IS NULL) AS missing_canonical_location_ids,
  COUNTIF(observed_at IS NULL) AS missing_timestamps,
  COUNTIF(temperature_celsius IS NULL) AS null_temperatures,
  MIN(temperature_celsius) AS min_temperature_celsius,
  MAX(temperature_celsius) AS max_temperature_celsius,
  COUNTIF(humidity_percent IS NULL) AS null_humidity,
  MIN(humidity_percent) AS min_humidity_percent,
  MAX(humidity_percent) AS max_humidity_percent,
  COUNTIF(humidity_percent < 0 OR humidity_percent > 100) AS humidity_outside_range,
  COUNTIF(precipitation_mm < 0) AS negative_precipitation_rows,
  COUNTIF(wind_speed_kmh < 0) AS negative_wind_rows
FROM `de-gcp-lab.weather_curated.fct_weather_observation`
GROUP BY source_system
ORDER BY source_system;
