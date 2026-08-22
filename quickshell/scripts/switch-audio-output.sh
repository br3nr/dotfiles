#!/usr/bin/env bash

set -u

sink_id="${1:-}"
if [[ ! "$sink_id" =~ ^[0-9]+$ ]]; then
    exit 2
fi

# Set the WirePlumber default so future playback streams use this output.
wpctl set-default "$sink_id" || exit 1

# PulseAudio-compatible clients keep their existing route when the default
# changes, so explicitly migrate every active playback stream as well.
while IFS=$'\t' read -r input_id _; do
    [[ "$input_id" =~ ^[0-9]+$ ]] || continue
    pactl move-sink-input "$input_id" @DEFAULT_SINK@
done < <(pactl list short sink-inputs)
