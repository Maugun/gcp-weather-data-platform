declare({
  database: dataform.projectConfig.defaultDatabase,
  schema: "weather_raw",
  name: "open_meteo",
});

declare({
  database: dataform.projectConfig.defaultDatabase,
  schema: "weather_raw",
  name: "public_weather_stations",
});

declare({
  database: dataform.projectConfig.defaultDatabase,
  schema: "weather_raw",
  name: "public_weather_observations",
});

declare({
  database: dataform.projectConfig.defaultDatabase,
  schema: "weather_raw",
  name: "s3_historical_weather",
});
