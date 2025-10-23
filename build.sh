#!/bin/bash

FOLLOW_UP_SCRIPT="/home/befrog/call_speaker.sh"

# Ordner mit deinen WAV-Dateien
AUDIO_DIR="./audio"
TMP_DIR="./converted_tmp"
OUTPUT_FILE="alarm_final_output.wav"

# Schlüsselwörter (alle lowercase)
KEYWORDS=("probealarm" "alarm" "einsatz" "gasaustritt" "gasgeruch" "arbeit" "fbma" "fgebäudey" "fgebäude" "ptür" "rücken" "hlf" "dlk" "lf10" "kats" "rw" "vupkw" "vulkw" "vu-ecall" "vu" "pkw")

# Textinput (1. Parameter)
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
  echo "Kein Eingabetext angegeben."
  exit 1
fi

# Input Text komplett klein machen
INPUT_TEXT=$(echo "$1" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/Ä/ä/g' -e 's/Ö/ö/g' -e 's/Ü/ü/g')

# Erstelle temp-Ordner
mkdir -p "$TMP_DIR"

# Startdatei immer als erstes
FILE_LIST=("$AUDIO_DIR/alarm-bs.wav")

# Suche nach Schlüsselwörtern in Eingabetext (Reihenfolge beibehalten)
for word in $INPUT_TEXT; do
  LOWER_WORD=$(echo "$word" | tr '[:upper:]' '[:lower:]')
  for key in "${KEYWORDS[@]}"; do
    if [[ "$LOWER_WORD" == *"$key"* ]]; then
      FILE="$AUDIO_DIR/${key}.wav"
      if [ -f "$FILE" ]; then
        FILE_LIST+=("$FILE")
      else
        echo "Datei fehlt für Schlüsselwort: $key ($FILE)"
      fi
      break
    fi
  done
done

# Konvertiere alle Dateien zu gleichem Format (44100 Hz, mono)
CONVERTED_FILES=()
i=0
for file in "${FILE_LIST[@]}"; do
  OUT="$TMP_DIR/conv_$i.wav"
  sox -V0 "$file" -r 44100 -c 1 "$OUT"
  CONVERTED_FILES+=("$OUT")
  ((i++))
done

# Dateien zusammenfügen
echo "Füge ${#CONVERTED_FILES[@]} Dateien zusammen..."
sox "${CONVERTED_FILES[@]}" "$OUTPUT_FILE" && echo "Erfolgreich zusammengefügt: $OUTPUT_FILE"

#Ändere die Sample-Date auf 48000
ffmpeg -i /home/befrog/audio_builder/alarm_final_output.wav -ar 48000 /home/befrog/audio_builder/alarm_final_output_tmp.wav
mv /home/befrog/audio_builder/alarm_final_output_tmp.wav /home/befrog/audio_builder/alarm_final_output.wav

if [ $? -eq 0 ]; then
  echo "Erfolgreich zusammengefügt: $OUTPUT_FILE"

  if [ -x "$FOLLOW_UP_SCRIPT" ]; then
    echo "Starte Folge-Skript: $FOLLOW_UP_SCRIPT"
    "$FOLLOW_UP_SCRIPT"
  else
    echo "Folge-Skript nicht ausführbar oder nicht gefunden: $FOLLOW_UP_SCRIPT"
  fi
else
  echo "Fehler beim Zusammenfügen"
fi
