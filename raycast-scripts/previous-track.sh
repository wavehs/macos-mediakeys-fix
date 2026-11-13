#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Previous Track
# @raycast.mode silent
# @raycast.icon ⏮️
# @raycast.packageName Media

if [ -x "/Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix" ]; then
    /Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix --prev
elif command -v nowplaying-cli >/dev/null 2>&1; then
    nowplaying-cli previous
elif [ -x "/opt/homebrew/bin/nowplaying-cli" ]; then
    /opt/homebrew/bin/nowplaying-cli previous
fi
