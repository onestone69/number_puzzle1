#!/bin/sh
# 렌더링한 PNG를 플레이 스토어 규격으로 변환한다.
# (먼저 flutter test tool/render_store_assets_test.dart --update-goldens 실행)
#
# 결과: store_assets/play/
#   icon_512.png                         고해상도 아이콘 (512x512, PNG)
#   feature_graphic.jpg                  그래픽 이미지 (1024x500, JPEG)
#   screenshots/{en,ko}/NN_*.jpg         설명 문구 + 기기 틀 (1080x1920)
#   screenshots_plain/{en,ko}/NN_*.jpg   앱 화면 그대로 (1080x1920)
set -e
cd "$(dirname "$0")/.."
OUT=store_assets/play
rm -rf "$OUT"
mkdir -p "$OUT"

sips -z 512 512 assets/icon/app_icon.png --out "$OUT/icon_512.png" >/dev/null
sips -s format jpeg -s formatOptions 95 store_assets/feature_graphic.png \
  --out "$OUT/feature_graphic.jpg" >/dev/null

for lang in en ko; do
  mkdir -p "$OUT/screenshots/$lang" "$OUT/screenshots_plain/$lang"
  for f in store_assets/framed/$lang/*.png; do
    sips -s format jpeg -s formatOptions 92 "$f" \
      --out "$OUT/screenshots/$lang/$(basename "${f%.png}").jpg" >/dev/null
  done
  for f in store_assets/raw/$lang/*.png; do
    sips -s format jpeg -s formatOptions 92 "$f" \
      --out "$OUT/screenshots_plain/$lang/$(basename "${f%.png}").jpg" >/dev/null
  done
done
echo "done: $OUT"
