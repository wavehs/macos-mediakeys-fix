#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title Next Track
# @raycast.mode silent
# @raycast.icon ⏭️
# @raycast.packageName Media

if [ -x "/Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix" ]; then
    /Applications/MediaKeysFix.app/Contents/MacOS/MediaKeysFix --next
elif command -v nowplaying-cli >/dev/null 2>&1; then
    nowplaying-cli next
elif [ -x "/opt/homebrew/bin/nowplaying-cli" ]; then
    /opt/homebrew/bin/nowplaying-cli next
fi
