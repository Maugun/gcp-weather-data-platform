import json
import logging
import os
import sys
import uuid
from datetime import UTC, datetime, timedelta
from zoneinfo import ZoneInfo

import requests
from google.cloud import storage
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

BUCKET_NAME = os.environ["BUCKET_NAME"]
LATITUDE = float(os.getenv("LATITUDE", "48.8566"))
LONGITUDE = float(os.getenv("LONGITUDE", "2.3522"))
LOCATION_NAME = os.getenv("LOCATION_NAME", "Paris")
LOCAL_TIMEZONE = os.getenv("TIMEZONE", "Europe/Paris")
TARGET_DATE = os.getenv("TARGET_DATE")


logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
)


def log_event(message: str, **kwargs) -> None:
    """Emit structured logs that are easy to read in Cloud Logging."""
    payload = {"message": message, **kwargs}
    logging.info(json.dumps(payload, ensure_ascii=False))


def get_target_date() -> str:
    """
    By default ingest yesterday in the configured local timezone.
    TARGET_DATE=YYYY-MM-DD can override this for a backfill/test run.
    """
    if TARGET_DATE:
        return TARGET_DATE

    local_now = datetime.now(ZoneInfo(LOCAL_TIMEZONE))
    return (local_now.date() - timedelta(days=1)).isoformat()


def build_http_session() -> requests.Session:
    """
    Retry only transient failures.
    429 respects Retry-After when the API sends it.
    """
    retry = Retry(
        total=4,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
        respect_retry_after_header=True,
    )

    session = requests.Session()
    session.mount("https://", HTTPAdapter(max_retries=retry))
    return session


def fetch_weather(target_date: str) -> dict:
    params = {
        "latitude": LATITUDE,
        "longitude": LONGITUDE,
        "start_date": target_date,
        "end_date": target_date,
        "timezone": LOCAL_TIMEZONE,
        "daily": ",".join(
            [
                "temperature_2m_max",
                "temperature_2m_min",
                "temperature_2m_mean",
                "precipitation_sum",
                "rain_sum",
                "wind_speed_10m_max",
                "weather_code",
            ]
        ),
    }

    log_event(
        "Calling Open-Meteo",
        target_date=target_date,
        latitude=LATITUDE,
        longitude=LONGITUDE,
    )

    session = build_http_session()
    response = session.get(OPEN_METEO_URL, params=params, timeout=20)
    response.raise_for_status()

    payload = response.json()
    daily = payload.get("daily")

    if not daily or not daily.get("time"):
        raise ValueError("Open-Meteo response does not contain daily weather data")

    return payload


def normalize_weather(payload: dict, target_date: str, run_id: str) -> dict:
    """
    Convert Open-Meteo's column-oriented response into one row for BigQuery.
    """
    daily = payload["daily"]

    if target_date not in daily["time"]:
        raise ValueError(f"Target date {target_date} not found in API response")

    index = daily["time"].index(target_date)

    return {
        "date": target_date,
        "location_name": LOCATION_NAME,
        "latitude": payload["latitude"],
        "longitude": payload["longitude"],
        "timezone": payload["timezone"],
        "temperature_2m_max": daily["temperature_2m_max"][index],
        "temperature_2m_min": daily["temperature_2m_min"][index],
        "temperature_2m_mean": daily["temperature_2m_mean"][index],
        "precipitation_sum": daily["precipitation_sum"][index],
        "rain_sum": daily["rain_sum"][index],
        "wind_speed_10m_max": daily["wind_speed_10m_max"][index],
        "weather_code": daily["weather_code"][index],
        "_ingested_at": datetime.now(UTC).isoformat(),
        "_source": "open_meteo",
        "_run_id": run_id,
    }


def upload_to_gcs(record: dict, target_date: str) -> str:
    """
    Same date => same GCS object path.
    Re-running the same day overwrites the object instead of creating
    a second RAW file, which makes the file-level ingestion idempotent.
    """
    object_name = f"open_meteo/dt={target_date}/weather.jsonl"

    client = storage.Client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(object_name)

    ndjson = json.dumps(record, ensure_ascii=False) + "\n"
    blob.upload_from_string(
        ndjson,
        content_type="application/x-ndjson",
    )

    return f"gs://{BUCKET_NAME}/{object_name}"


def main() -> None:
    target_date = get_target_date()
    run_id = str(uuid.uuid4())

    log_event(
        "Starting weather ingestion",
        run_id=run_id,
        target_date=target_date,
    )

    payload = fetch_weather(target_date)
    record = normalize_weather(payload, target_date, run_id)
    gcs_uri = upload_to_gcs(record, target_date)

    log_event(
        "Weather ingestion completed",
        run_id=run_id,
        target_date=target_date,
        gcs_uri=gcs_uri,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        logging.exception(
            json.dumps(
                {
                    "message": "Weather ingestion failed",
                    "error": str(exc),
                },
                ensure_ascii=False,
            )
        )
        # Non-zero exit => Cloud Run Job marks the task as failed
        # and can retry it according to --max-retries.
        sys.exit(1)
