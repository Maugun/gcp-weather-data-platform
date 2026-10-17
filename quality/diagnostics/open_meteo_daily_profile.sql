-- Profile daily Open-Meteo records and check stable value relationships.
-- Temperature min/max values are reported as ranges, not hard-coded thresholds.
SELECT
  COUNT(*) AS row_count,
  COUNTIF(location_id IS NULL) AS missing_location_ids,
  COUNTIF(observation_date IS NULL) AS missing_dates,
  COUNTIF(
    temperature_2m_min IS NOT NULL
    AND temperature_2m_max IS NOT NULL
    AND temperature_2m_min > temperature_2m_max
  ) AS min_greater_than_max_rows,
  COUNTIF(
    temperature_2m_mean IS NOT NULL
    AND temperature_2m_min IS NOT NULL
    AND temperature_2m_max IS NOT NULL
    AND (
      temperature_2m_mean < temperature_2m_min
      OR temperature_2m_mean > temperature_2m_max
    )
  ) AS mean_outside_daily_range_rows,
  MIN(temperature_2m_min) AS min_temperature_celsius,
  MAX(temperature_2m_max) AS max_temperature_celsius,
  COUNTIF(precipitation_sum < 0) AS negative_precipitation_rows,
  COUNTIF(rain_sum < 0) AS negative_rain_rows,
  COUNTIF(wind_speed_10m_max < 0) AS negative_wind_rows
FROM `de-gcp-lab.weather_curated.fct_weather_daily_open_meteo`;
