CREATE TABLE IF NOT EXISTS weather_stations (
    station_id VARCHAR(50) PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL,
    region VARCHAR(30) NOT NULL,
    latitude NUMERIC(9, 6) NOT NULL,
    longitude NUMERIC(9, 6) NOT NULL,
    operator_email VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT weather_stations_region_check
        CHECK (region IN ('EU', 'NORTH_AMERICA', 'ASIA'))
);


CREATE TABLE IF NOT EXISTS weather_observations (
    observation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_id VARCHAR(50) NOT NULL,
    observed_at TIMESTAMPTZ NOT NULL,
    temperature_celsius NUMERIC(5, 2),
    humidity_percent NUMERIC(5, 2),
    precipitation_mm NUMERIC(7, 2),
    wind_speed_kmh NUMERIC(6, 2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT weather_observations_station_fk
        FOREIGN KEY (station_id)
        REFERENCES weather_stations(station_id),

    CONSTRAINT weather_observations_station_time_unique
        UNIQUE (station_id, observed_at),

    CONSTRAINT humidity_percent_check
        CHECK (
            humidity_percent IS NULL
            OR humidity_percent BETWEEN 0 AND 100
        ),

    CONSTRAINT precipitation_mm_check
        CHECK (
            precipitation_mm IS NULL
            OR precipitation_mm >= 0
        ),

    CONSTRAINT wind_speed_kmh_check
        CHECK (
            wind_speed_kmh IS NULL
            OR wind_speed_kmh >= 0
        )
);