#!/usr/bin/env bash
# GLaDOS TTS — variação de pitch por palavra via SSML (técnica: ArtBIT/glados.sh)
# Uso: glados-speak.sh [-v voz] [-l lang] [-p pitch] [-s speed] "<texto>"

random_pitch() {
    local delta=${1:-50}
    local value=$(( (RANDOM % delta) - delta/2 ))
    printf '%+d' "$value"
}

pitch=70
speed=180
lang=pt-br
voice=f3
text=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--voice)   voice="$2"; shift 2 ;;
        -l|--lang)    lang="$2";  shift 2 ;;
        -p|--pitch)   pitch="$2"; shift 2 ;;
        -s|--speed)   speed="$2"; shift 2 ;;
        --)           shift; break ;;
        *)            text="$1";  shift ;;
    esac
done

if [[ -z "$text" ]]; then
    echo "Uso: glados-speak.sh [flags] \"<texto>\"" >&2
    exit 1
fi

prosody_data=""
read -ra words <<< "$text"
for word in "${words[@]}"; do
    wp=$(random_pitch 50)
    prosody_data+="<prosody pitch=\"${wp}\">${word}</prosody> "
done

espeak "${prosody_data}" -m -p "${pitch}" -s "${speed}" -v "${lang}+${voice}"
