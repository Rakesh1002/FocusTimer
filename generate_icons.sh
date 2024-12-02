#!/bin/bash

# Create iconset directory
rm -rf icon.iconset
mkdir icon.iconset

# Generate different icon sizes using magick
magick AppIcon.svg -background none -resize 16x16 icon.iconset/icon_16x16.png
magick AppIcon.svg -background none -resize 32x32 icon.iconset/icon_16x16@2x.png
magick AppIcon.svg -background none -resize 32x32 icon.iconset/icon_32x32.png
magick AppIcon.svg -background none -resize 64x64 icon.iconset/icon_32x32@2x.png
magick AppIcon.svg -background none -resize 128x128 icon.iconset/icon_128x128.png
magick AppIcon.svg -background none -resize 256x256 icon.iconset/icon_128x128@2x.png
magick AppIcon.svg -background none -resize 256x256 icon.iconset/icon_256x256.png
magick AppIcon.svg -background none -resize 512x512 icon.iconset/icon_256x256@2x.png
magick AppIcon.svg -background none -resize 512x512 icon.iconset/icon_512x512.png
magick AppIcon.svg -background none -resize 1024x1024 icon.iconset/icon_512x512@2x.png

# Create icns file
iconutil -c icns icon.iconset

# Clean up
rm -rf icon.iconset
