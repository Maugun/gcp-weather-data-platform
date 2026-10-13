from datetime import UTC, datetime, timedelta
from pathlib import Path

import pandas as pd

STATIONS = [
    {
        "station_id": "PARIS_001",
        "station_name": "Paris Central",
        "city": "Paris",
        "country_code": "FR",
        "region": "EU",
        "latitude": 48.8566,
        "longitude": 2.3522,
    },
    {
        "station_id": "LYON_001",
        "station_name": "Lyon Central",
        "city": "Lyon",
        "country_code": "FR",
        "region": "EU",
        "latitude": 45.7640,
        "longitude": 4.8357,
    },
    {
        "station_id": "NYC_001",
        "station_name": "New York Central",
        "city": "New York",
        "country_code": "US",
        "region": "NORTH_AMERICA",
        "latitude": 40.7128,
        "longitude": -74.0060,
    },
]


def generate_month(year: int, month: int) -> pd.DataFrame:
    start = datetime(year, month, 1, 12, tzinfo=UTC)

    if month == 12:
        end = datetime(year + 1, 1, 1, 12, tzinfo=UTC)
    else:
        end = datetime(year, month + 1, 1, 12, tzinfo=UTC)

    rows = []
    current = start

    while current < end:
        for index, station in enumerate(STATIONS):
            rows.append(
                {
                    **station,
                    "observed_at": current,
                    "temperature_c": 18.0 + index + (current.day % 6),
                    "humidity_percent": 55 + index * 5,
                    "precipitation_mm": float(current.day % 4),
                    "wind_speed_kmh": 8.0 + index * 2,
                    "source_updated_at": current + timedelta(minutes=15),
                }
            )

        current += timedelta(days=1)

    return pd.DataFrame(rows)


for year, month in [(2026, 8), (2026, 9), (2026, 10)]:
    dataframe = generate_month(year, month)

    output_dir = Path(f".generated/weather-history/year={year}/month={month:02d}")
    output_dir.mkdir(parents=True, exist_ok=True)

    output_file = output_dir / f"weather_{year}_{month:02d}.parquet"

    dataframe.to_parquet(
        output_file,
        index=False,
        engine="pyarrow",
    )

    print(f"{output_file}: {len(dataframe)} rows")
