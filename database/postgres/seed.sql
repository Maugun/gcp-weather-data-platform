INSERT INTO weather_stations (
    station_id,
    station_name,
    city,
    country_code,
    region,
    latitude,
    longitude,
    operator_email
)
VALUES
    (
        'PARIS_001',
        'Paris Montsouris',
        'Paris',
        'FR',
        'EU',
        48.821400,
        2.337800,
        'paris.operator@example.com'
    ),
    (
        'LYON_001',
        'Lyon Centre',
        'Lyon',
        'FR',
        'EU',
        45.764000,
        4.835700,
        'lyon.operator@example.com'
    ),
    (
        'NYC_001',
        'New York Central',
        'New York',
        'US',
        'NORTH_AMERICA',
        40.782900,
        -73.965400,
        'nyc.operator@example.com'
    ),
    (
        'SF_001',
        'San Francisco Downtown',
        'San Francisco',
        'US',
        'NORTH_AMERICA',
        37.774900,
        -122.419400,
        'sf.operator@example.com'
    ),
    (
        'TOKYO_001',
        'Tokyo Central',
        'Tokyo',
        'JP',
        'ASIA',
        35.676200,
        139.650300,
        'tokyo.operator@example.com'
    ),
    (
        'SINGAPORE_001',
        'Singapore Central',
        'Singapore',
        'SG',
        'ASIA',
        1.352100,
        103.819800,
        'singapore.operator@example.com'
    )
ON CONFLICT (station_id) DO NOTHING;


INSERT INTO weather_observations (
    station_id,
    observed_at,
    temperature_celsius,
    humidity_percent,
    precipitation_mm,
    wind_speed_kmh
)
VALUES
    ('PARIS_001', '2026-10-10 12:00:00+02', 17.4, 67, 0.0, 12.5),
    ('PARIS_001', '2026-10-11 12:00:00+02', 16.8, 72, 1.2, 15.3),

    ('LYON_001', '2026-10-10 12:00:00+02', 19.1, 60, 0.0, 10.8),
    ('LYON_001', '2026-10-11 12:00:00+02', 18.7, 64, 0.0, 9.6),

    ('NYC_001', '2026-10-10 12:00:00-04', 20.3, 58, 0.0, 18.1),
    ('NYC_001', '2026-10-11 12:00:00-04', 21.0, 61, 0.4, 14.7),

    ('SF_001', '2026-10-10 12:00:00-07', 18.2, 71, 0.0, 22.5),
    ('SF_001', '2026-10-11 12:00:00-07', 17.9, 73, 0.0, 19.8),

    ('TOKYO_001', '2026-10-10 12:00:00+09', 23.6, 69, 2.1, 13.4),
    ('TOKYO_001', '2026-10-11 12:00:00+09', 22.9, 74, 4.8, 16.2),

    ('SINGAPORE_001', '2026-10-10 12:00:00+08', 30.1, 78, 3.6, 8.4),
    ('SINGAPORE_001', '2026-10-11 12:00:00+08', 29.7, 81, 8.3, 7.9)

ON CONFLICT (station_id, observed_at) DO NOTHING;