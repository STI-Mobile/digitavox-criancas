#!/bin/sh
# Derives the dev flavor launcher icons from the production icons by adding a
# "DEV" band. Run again whenever the production icons change. Requires
# ImageMagick. See docs/adr/0005-apps-separados-dev-prod.md.
set -eu

cd "$(dirname "$0")/.."

font=assets/fonts/open_sans/OpenSans-Bold.ttf

add_dev_band() {
  source_icon="$1"
  target_icon="$2"
  width=$(identify -format '%w' "$source_icon")
  height=$(identify -format '%h' "$source_icon")
  band_height=$((height * 30 / 100))

  mkdir -p "$(dirname "$target_icon")"
  convert "$source_icon" \
    \( -size "${width}x${band_height}" xc:'#B3261E' \
      -fill white -font "$font" -gravity center \
      -pointsize $((band_height * 70 / 100)) -annotate +0+0 'DEV' \) \
    -gravity south -compose over -composite "$target_icon"
}

for source_icon in android/app/src/main/res/mipmap-*/ic_launcher.png; do
  density_dir=$(basename "$(dirname "$source_icon")")
  add_dev_band "$source_icon" "android/app/src/dev/res/$density_dir/ic_launcher.png"
done

ios_icons=ios/Runner/Assets.xcassets/AppIcon.appiconset
ios_dev_icons=ios/Runner/Assets.xcassets/AppIcon-dev.appiconset
for source_icon in "$ios_icons"/*.png; do
  add_dev_band "$source_icon" "$ios_dev_icons/$(basename "$source_icon")"
done
cp "$ios_icons/Contents.json" "$ios_dev_icons/Contents.json"
