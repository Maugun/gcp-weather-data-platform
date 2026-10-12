#!/usr/bin/env bash

export TF_VAR_open_meteo_image_tag="$(terraform output -raw open_meteo_image_tag)"
export TF_VAR_weather_api_image_tag="$(terraform output -raw weather_api_image_tag)"

echo "Open-Meteo: $TF_VAR_open_meteo_image_tag"
echo "Weather API: $TF_VAR_weather_api_image_tag"