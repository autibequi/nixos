#!/bin/bash
# Nyan Tulpa — Portal 2 test chamber animation
orange="\033[38;5;208m"
blue="\033[38;5;33m"
white="\033[97m"
dim="\033[2m"
bold="\033[1m"
reset="\033[0m"

dia=$(date +"%d/%m")
hora=$(date +"%H:%M")

# Weather (quick fetch, fallback graceful)
weather=$(curl -s --connect-timeout 2 "wttr.in/São+Paulo?format=%c+%t&lang=pt" 2>/dev/null | tr -d '+' || echo "")
[[ "$weather" =~ "Unknown" || "$weather" =~ "Sorry" || -z "$weather" ]] && weather="--"

frames=(
"
  ${white}┌──────────────────────────────────────────┐${reset}
  ${white}│${reset}  ${orange}(o)${reset}                          ${blue}(o)${reset}       ${white}│${reset}
  ${white}│${reset}   ${orange}\\\\${reset}   APERTURE SCIENCE         ${blue}/${reset}       ${white}│${reset}
  ${white}│${reset}    ${orange}\\\\${reset}  ─────────────────       ${blue}/${reset}        ${white}│${reset}
  ${white}│${reset}  ${dim}test chamber active${reset}                      ${white}│${reset}
  ${white}│${reset}                                            ${white}│${reset}
  ${white}│${reset}  ${bold}T U L P A${reset}   ${dim}${dia} ${hora}${reset}              ${white}│${reset}
  ${white}│${reset}  ${dim}${weather}${reset}
  ${white}│${reset}                                            ${white}│${reset}
  ${white}└──────────────────────────────────────────┘${reset}
"
"
  ${white}┌──────────────────────────────────────────┐${reset}
  ${white}│${reset}  ${orange}(O)${reset}                          ${blue}(O)${reset}       ${white}│${reset}
  ${white}│${reset}   ${orange}|${reset}   APERTURE SCIENCE          ${blue}|${reset}       ${white}│${reset}
  ${white}│${reset}   ${orange}|${reset}   ─────────────────         ${blue}|${reset}       ${white}│${reset}
  ${white}│${reset}  ${dim}// running diagnostics //${reset}               ${white}│${reset}
  ${white}│${reset}                                            ${white}│${reset}
  ${white}│${reset}  ${bold}T U L P A${reset}   ${dim}${dia} ${hora}${reset}              ${white}│${reset}
  ${white}│${reset}  ${dim}${weather}${reset}
  ${white}│${reset}                                            ${white}│${reset}
  ${white}└──────────────────────────────────────────┘${reset}
"
"
  ${white}┌──────────────────────────────────────────┐${reset}
  ${white}│${reset}  ${orange}(o)${reset}                          ${blue}(o)${reset}       ${white}│${reset}
  ${white}│${reset}   ${orange}/${reset}   APERTURE SCIENCE          ${blue}\\\\${reset}      ${white}│${reset}
  ${white}│${reset}  ${orange}/${reset}    ─────────────────          ${blue}\\\\${reset}     ${white}│${reset}
  ${white}│${reset}  ${dim}portal link established${reset}                  ${white}│${reset}
  ${white}│${reset}                                            ${white}│${reset}
  ${white}│${reset}  ${bold}T U L P A${reset}   ${dim}${dia} ${hora}${reset}              ${white}│${reset}
  ${white}│${reset}  ${dim}${weather}${reset}
  ${white}│${reset}                                            ${white}│${reset}
  ${white}└──────────────────────────────────────────┘${reset}
"
)

trap 'printf "\033[?25h"; exit' INT TERM
printf '\033[?25l'

for cycle in $(seq 1 6); do
  for f in 0 1 2; do
    printf '\033[2J\033[H'
    printf "${frames[$f]}\n"
    sleep 0.3
  done
done

printf '\033[2J\033[H'
printf '\033[?25h'
echo ""
printf "  ${orange}${bold}(o)${reset} ${white}${bold}APERTURE SCIENCE${reset} ${blue}${bold}(o)${reset}\n"
printf "  ${bold}T U L P A${reset}  ${dim}personal dev agent${reset}\n"
printf "  ${dim}${dia} ${hora}  ${weather}${reset}\n"
echo ""
