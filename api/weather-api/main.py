import os
from contextlib import asynccontextmanager

import sqlalchemy
from fastapi import FastAPI, HTTPException, Query
from google.cloud.sql.connector import Connector
from sqlalchemy import text

INSTANCE_CONNECTION_NAME = os.environ["INSTANCE_CONNECTION_NAME"]
DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "weather_app")
DB_PASSWORD = os.environ["DB_PASSWORD"]


connector = Connector(refresh_strategy="LAZY")


def get_connection():
    return connector.connect(
        INSTANCE_CONNECTION_NAME,
        "pg8000",
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
    )


engine = sqlalchemy.create_engine(
    "postgresql+pg8000://",
    creator=get_connection,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=2,
    pool_timeout=30,
    pool_recycle=1800,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    engine.dispose()
    connector.close()


app = FastAPI(
    title="Weather Stations API",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
def health():
    with engine.connect() as connection:
        result = connection.execute(text("SELECT 1 AS ok")).mappings().one()

    return {"status": "ok", "database": result["ok"] == 1}


@app.get("/live")
def live():
    return {"status": "ok"}


@app.get("/stations")
def get_stations():
    query = text(
        """
        SELECT
            station_id,
            station_name,
            city,
            country_code,
            region,
            active
        FROM weather_stations
        WHERE active = TRUE
        ORDER BY station_id
        """
    )

    with engine.connect() as connection:
        stations = connection.execute(query).mappings().all()

    return [dict(station) for station in stations]


@app.get("/stations/{station_id}")
def get_station(station_id: str):
    query = text(
        """
        SELECT
            station_id,
            station_name,
            city,
            country_code,
            region,
            active
        FROM weather_stations
        WHERE station_id = :station_id
        """
    )

    with engine.connect() as connection:
        station = (
            connection.execute(
                query,
                {"station_id": station_id},
            )
            .mappings()
            .first()
        )

    if station is None:
        raise HTTPException(status_code=404, detail="Station not found")

    return dict(station)


@app.get("/stations/{station_id}/observations")
def get_station_observations(
    station_id: str,
    limit: int = Query(default=20, ge=1, le=100),
):
    query = text(
        """
        SELECT
            observation_id,
            station_id,
            observed_at,
            temperature_celsius,
            humidity_percent,
            precipitation_mm,
            wind_speed_kmh
        FROM weather_observations
        WHERE station_id = :station_id
        ORDER BY observed_at DESC
        LIMIT :limit
        """
    )

    with engine.connect() as connection:
        observations = (
            connection.execute(
                query,
                {
                    "station_id": station_id,
                    "limit": limit,
                },
            )
            .mappings()
            .all()
        )

    return [dict(observation) for observation in observations]
