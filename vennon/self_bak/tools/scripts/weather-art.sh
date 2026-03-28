#!/usr/bin/env bash
# weather-art.sh — Fetch weather data + render ASCII art per condition
# Sources into bootstrap.sh. Exports: WEATHER_ART[], WEATHER_NOW, WEATHER_TODAY, WEATHER_WEEK[]
# NOTE: no set -euo pipefail — this is sourced, must be tolerant

WS="${WORKSPACE:-/workspace}"
WEATHER_CACHE="$WS/.ephemeral/.weather-full-cache"
WEATHER_LOCATION="${WEATHER_LOCATION:-São Paulo}"

R='\033[0m' B='\033[1m' DIM='\033[2m'
CYAN='\033[36m' GREEN='\033[32m' YELLOW='\033[33m' RED='\033[31m'
ORANGE='\033[38;5;208m' BLUE='\033[38;5;33m' WHITE='\033[97m'
GRAY='\033[38;5;245m'

# ── Fetch (cached 30min) ────────────────────────────────────────
_weather_json=""
now_ts=$(date +%s)

if [[ -f "$WEATHER_CACHE" ]]; then
  cache_age=$(( now_ts - $(stat -c %Y "$WEATHER_CACHE" 2>/dev/null || echo 0) ))
  if [[ $cache_age -le 1800 ]]; then
    _weather_json=$(cat "$WEATHER_CACHE")
  fi
fi

if [[ -z "$_weather_json" ]]; then
  _weather_loc=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$WEATHER_LOCATION" 2>/dev/null || echo "$WEATHER_LOCATION")
  _weather_json=$(curl -s --connect-timeout 5 "wttr.in/${_weather_loc}?format=j1" 2>/dev/null || echo "")
  if [[ -n "$_weather_json" ]] && echo "$_weather_json" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    echo "$_weather_json" > "$WEATHER_CACHE" 2>/dev/null || true
  else
    _weather_json=""
  fi
fi

# ── Parse with Python ───────────────────────────────────────────
# Defaults
WEATHER_CAT="cloudy"; WEATHER_TEMP="--"; WEATHER_FEELS="--"; WEATHER_DESC="indisponível"
WEATHER_HUMIDITY=""; WEATHER_WIND=""; WEATHER_TMAX=""; WEATHER_TMIN=""
WEATHER_SUNRISE=""; WEATHER_SUNSET=""; WEATHER_HOUR_COUNT=0; WEATHER_WEEK_COUNT=0

if [[ -n "$_weather_json" ]]; then
  eval "$(echo "$_weather_json" | python3 -c "
import json, sys

d = json.load(sys.stdin)
cc = d['current_condition'][0]
temp = cc['temp_C']
feels = cc['FeelsLikeC']
desc = cc['weatherDesc'][0]['value']
code = int(cc['weatherCode'])
humidity = cc['humidity']
wind = cc['windspeedKmph']

# Weather condition category from code
# https://www.worldweatheronline.com/weather-api/api/docs/weather-icons.aspx
def categorize(code):
    if code in (113,):
        return 'sunny'
    elif code in (116,):
        return 'partly_cloudy'
    elif code in (119, 122):
        return 'cloudy'
    elif code in (143, 248, 260):
        return 'foggy'
    elif code in (176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359):
        return 'rainy'
    elif code in (179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377):
        return 'snowy'
    elif code in (200, 386, 389, 392, 395):
        return 'stormy'
    else:
        return 'cloudy'

cat = categorize(code)

# Today
today = d['weather'][0]
tmax = today['maxtempC']
tmin = today['mintempC']
sunrise = today['astronomy'][0]['sunrise'].replace(' ', '')
sunset = today['astronomy'][0]['sunset'].replace(' ', '')

# Today hourly summary (pick key hours: 9, 12, 15, 18)
today_hours = []
for h in today['hourly']:
    hr = int(h['time']) // 100
    if hr in (9, 12, 15, 18):
        htemp = h['tempC']
        hrain = h['chanceofrain']
        hcode = int(h['weatherCode'])
        hcat = categorize(hcode)
        icons = {'sunny':'☀','partly_cloudy':'⛅','cloudy':'☁','foggy':'🌫','rainy':'🌧','snowy':'❄','stormy':'⛈'}
        hicon = icons.get(hcat, '☁')
        rain_str = f' {hrain}%☔' if int(hrain) > 0 else ''
        today_hours.append(f'{hr:02d}h {htemp}°{hicon}{rain_str}')

# Week (3 days)
week = []
days_pt = {'Monday':'Seg','Tuesday':'Ter','Wednesday':'Qua','Thursday':'Qui','Friday':'Sex','Saturday':'Sáb','Sunday':'Dom'}
import datetime
for w in d['weather']:
    dt = datetime.date.fromisoformat(w['date'])
    day_name = days_pt.get(dt.strftime('%A'), dt.strftime('%a'))
    wmin = w['mintempC']
    wmax = w['maxtempC']
    # Use midday hour for description
    midday = w['hourly'][4] if len(w['hourly']) > 4 else w['hourly'][0]
    wdesc = midday['weatherDesc'][0]['value']
    wcode = int(midday['weatherCode'])
    wcat = categorize(wcode)
    # emoji-like indicator
    icons = {'sunny':'☀','partly_cloudy':'⛅','cloudy':'☁','foggy':'🌫','rainy':'🌧','snowy':'❄','stormy':'⛈'}
    icon = icons.get(wcat, '☁')
    week.append(f'{day_name} {wmin}-{wmax}° {icon} {wdesc[:14]}')

print(f'WEATHER_CAT=\"{cat}\"')
print(f'WEATHER_TEMP=\"{temp}\"')
print(f'WEATHER_FEELS=\"{feels}\"')
print(f'WEATHER_DESC=\"{desc}\"')
print(f'WEATHER_HUMIDITY=\"{humidity}\"')
print(f'WEATHER_WIND=\"{wind}\"')
print(f'WEATHER_TMAX=\"{tmax}\"')
print(f'WEATHER_TMIN=\"{tmin}\"')
print(f'WEATHER_SUNRISE=\"{sunrise}\"')
print(f'WEATHER_SUNSET=\"{sunset}\"')

# Today hours
for i, h in enumerate(today_hours):
    print(f'WEATHER_HOUR_{i}=\"{h}\"')
print(f'WEATHER_HOUR_COUNT={len(today_hours)}')

# Week
for i, w in enumerate(week):
    print(f'WEATHER_WEEK_{i}=\"{w}\"')
print(f'WEATHER_WEEK_COUNT={len(week)}')
" 2>/dev/null)" || {
    WEATHER_CAT="cloudy"
    WEATHER_TEMP="--"
    WEATHER_DESC="indisponível"
  }
else
  WEATHER_CAT="cloudy"
  WEATHER_TEMP="--"
  WEATHER_DESC="indisponível"
fi

# ── ASCII Art per weather ───────────────────────────────────────
# 8 lines each, ~20 chars wide, using safe chars (no block ░█▀▄)

declare -a WEATHER_ART

case "${WEATHER_CAT:-cloudy}" in
  sunny)
    WEATHER_ART=(
      "        .        "
      "    '  .  .  '   "
      "      .-=:-.     "
      "  .  | (\`) |  .  "
      "      '-:-'      "
      "    .  ' '  .    "
      "        '        "
      "                 "
    )
    ;;
  partly_cloudy)
    WEATHER_ART=(
      "        .  '     "
      "    '  .-.       "
      "   .  (\`)  ) .   "
      "       '-'       "
      "   .---.         "
      "  (     ).       "
      "  (_______)      "
      "                 "
    )
    ;;
  cloudy)
    WEATHER_ART=(
      "                 "
      "      .---.      "
      "   .-(     ).    "
      "  (___________)  "
      "                 "
      "    .---.        "
      "   (     )       "
      "   '-----'       "
    )
    ;;
  foggy)
    WEATHER_ART=(
      "                 "
      "   _ - _ - _ -   "
      "    _ - _ - _    "
      "   _ - _ - _ -   "
      "  .---.          "
      " (     ).        "
      " (________)      "
      "   - _ - _ -     "
    )
    ;;
  rainy)
    WEATHER_ART=(
      "      .---.      "
      "   .-(     ).    "
      "  (___________)  "
      "   / / / / /     "
      "  / / / / /      "
      "   / / / /       "
      "  / / / /        "
      "                 "
    )
    ;;
  stormy)
    WEATHER_ART=(
      "      .---.      "
      "   .-(     ).    "
      "  (___________)  "
      "    /_/ /_/ /    "
      "   / /_/ / /     "
      "     _/          "
      "    /     _/     "
      "         /       "
    )
    ;;
  snowy)
    WEATHER_ART=(
      "      .---.      "
      "   .-(     ).    "
      "  (___________)  "
      "    *  *  *  *   "
      "  *  *  *  *     "
      "    *  *  *  *   "
      "  *  *  *  *     "
      "                 "
    )
    ;;
  *)
    WEATHER_ART=(
      "      .---.      "
      "   .-(     ).    "
      "  (___________)  "
      "                 "
      "                 "
      "                 "
      "                 "
      "                 "
    )
    ;;
esac
