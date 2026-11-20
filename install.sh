#!/bin/zsh
# 빌드한 WakeUp.app을 /Applications에 설치한다. (이미 실행 중이면 종료 후 교체)
set -euo pipefail
cd "$(dirname "$0")"

[[ -d build.noindex/WakeUp.app ]] || ./build.sh

pkill -x WakeUp 2>/dev/null || true
sleep 1
rm -rf /Applications/WakeUp.app
cp -R build.noindex/WakeUp.app /Applications/WakeUp.app

echo "설치 완료: /Applications/WakeUp.app"
echo "Launchpad나 응용프로그램 폴더에서 WakeUp을 열면 메뉴바에 올라갑니다."
