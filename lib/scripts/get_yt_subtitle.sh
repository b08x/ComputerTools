#!/bin/bash

# ===================================================================================
#
#          FILE: download_subtitles.sh
#
#         USAGE: ./download_subtitles.sh <youtube_url> [language_code]
#
#   DESCRIPTION: Downloads subtitles of a YouTube video in SRT format.
#                It will try to download manual subtitles first, then fall back
#                to automatically generated ones. Defaults to English ('en').
#
#       OPTIONS: ---
#  REQUIREMENTS: yt-dlp (https://github.com/yt-dlp/yt-dlp)
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Gemini
#  ORGANIZATION:
#       CREATED: 2025-07-07
#      REVISION: 2.0
#
# ===================================================================================

# --- Check for Dependencies ---
# Ensure yt-dlp is installed and available in the system's PATH.
if ! command -v yt-dlp &> /dev/null
then
    echo "Error: yt-dlp is not installed or not in your PATH." >&2
    echo "Please install it to use this script." >&2
    echo "Installation instructions: https://github.com/yt-dlp/yt-dlp#installation" >&2
    exit 1
fi

# --- Argument Validation ---
# Check if a URL argument is provided. If not, print usage instructions and exit.
if [ -z "$1" ]; then
  echo "Usage: $0 <youtube_url> [language_code]"
  echo "Example: $0 https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  echo "Example with language: $0 https://www.youtube.com/watch?v=k52qvXAmXgg es"
  exit 1
fi

# --- Set Variables ---
YOUTUBE_URL="$1"
LANGUAGE_CODE="${2:-en}"

# --- Predict Filename ---
# First, get a sanitized version of the video title from yt-dlp.
VIDEO_TITLE=$(yt-dlp --get-title --restrict-filenames "$YOUTUBE_URL")
if [ -z "$VIDEO_TITLE" ]; then
    echo "Error: Could not retrieve video title. The URL may be invalid or the video is unavailable." >&2
    exit 1
fi
# Construct the exact filename we expect yt-dlp to create.
EXPECTED_FILENAME="${VIDEO_TITLE}.${LANGUAGE_CODE}.srt"


# --- Main Download Logic ---
echo "Starting subtitle download for URL: $YOUTUBE_URL"
echo "Language: $LANGUAGE_CODE"
echo "Attempting to download both manual and automatic subtitles..."

# Use yt-dlp with specific options to download only the subtitles.
#
# --write-subs:           Enables writing manually created subtitle files.
# --write-auto-subs:      (KEY CHANGE) Also write automatically generated subtitles if manual are unavailable.
# --sub-format srt:       Specifies the desired subtitle format (SRT).
# --sub-langs "$LANGUAGE_CODE": Downloads subtitles for the specified language.
# --skip-download:        Prevents downloading the actual video file.
# -o '%(title)s.%(language)s.%(ext)s': Sets a predictable output filename.
# --restrict-filenames:   Ensures the filename is safe for the filesystem.
yt-dlp \
    --write-subs \
    --write-auto-subs \
    --sub-format srt \
    --sub-langs "$LANGUAGE_CODE" \
    --skip-download \
    -o '%(title)s.%(language)s.%(ext)s' \
    --restrict-filenames \
    "$YOUTUBE_URL"

# --- Verification and Completion Message ---
# Check if the subtitle file was actually created.
if [ -f "$EXPECTED_FILENAME" ]; then
    echo "--------------------------------------------------"
    echo "✅ Success! Subtitle file downloaded:"
    echo "   $EXPECTED_FILENAME"
    echo "--------------------------------------------------"
else
    echo "--------------------------------------------------"
    echo "⚠️ Download finished, but no subtitle file was created."
    echo "This likely means no subtitles (manual or automatic) are available for this video in '$LANGUAGE_CODE'."
    echo "You can list all available subtitles by running:"
    echo "   yt-dlp --list-subs \"$YOUTUBE_URL\""
    echo "--------------------------------------------------"
fi
```

I've made the script more robust and communicative. Try running this new version with your URL, and it should successfully download the auto-generated subtitles for y