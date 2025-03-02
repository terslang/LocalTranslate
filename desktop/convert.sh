#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
  echo "Error: ImageMagick is not installed. Please install it to use this script."
  exit 1
fi

# Ensure localtranslate.png exists
if [ ! -f "localtranslate.png" ]; then
  echo "Error: localtranslate.png not found in the current directory."
  exit 1
fi

# Loop over directories that match the resolution pattern (e.g., 128x128)
for dir in *x*; do
  if [ -d "$dir" ]; then
    echo "Converting localtranslate.png to resolution $dir..."
    convert localtranslate.png -resize "$dir" "$dir/localtranslate.png"
  fi
done

echo "All conversions complete."
