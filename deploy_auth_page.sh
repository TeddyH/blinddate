#!/bin/bash

# Hearty 이메일 인증 페이지 배포 스크립트
# 사용법: ./deploy_auth_page.sh

set -e

echo "🚀 Hearty 이메일 인증 페이지 배포 시작..."

# 현재 스크립트 위치 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_AUTH_DIR="$SCRIPT_DIR/web_auth"

echo "📁 웹 인증 디렉토리: $WEB_AUTH_DIR"

# web_auth 디렉토리 존재 확인
if [ ! -d "$WEB_AUTH_DIR" ]; then
    echo "❌ web_auth 디렉토리를 찾을 수 없습니다: $WEB_AUTH_DIR"
    exit 1
fi

# index.html 파일 존재 확인
if [ ! -f "$WEB_AUTH_DIR/index.html" ]; then
    echo "❌ index.html 파일을 찾을 수 없습니다: $WEB_AUTH_DIR/index.html"
    exit 1
fi

echo "✅ 인증 페이지 파일 확인 완료"

# Azure 서버 정보
AZURE_USER="honghyungseok"
AZURE_HOST="52.141.58.118"
AZURE_KEY="~/.ssh/mud2_deploy"
TEMP_PATH="~/hearty-auth-temp"
WEB_PATH="/var/www/html/hearty-auth"

echo "🔄 Azure 서버에 배포 중..."
echo "   서버: $AZURE_USER@$AZURE_HOST"
echo "   임시 경로: $TEMP_PATH"
echo "   최종 경로: $WEB_PATH"

# 임시 디렉토리에 업로드
echo "📁 임시 디렉토리 생성..."
ssh -i "$AZURE_KEY" "$AZURE_USER@$AZURE_HOST" "rm -rf $TEMP_PATH && mkdir -p $TEMP_PATH"

# 파일 업로드 (임시 위치로)
echo "📤 파일 업로드 중..."
scp -i "$AZURE_KEY" -r "$WEB_AUTH_DIR"/* "$AZURE_USER@$AZURE_HOST:$TEMP_PATH/"

# sudo 권한으로 웹 디렉토리에 이동 및 권한 설정
echo "🔐 웹 디렉토리로 이동 및 권한 설정..."
ssh -i "$AZURE_KEY" "$AZURE_USER@$AZURE_HOST" "
    sudo rm -rf $WEB_PATH &&
    sudo mkdir -p $WEB_PATH &&
    sudo cp -r $TEMP_PATH/* $WEB_PATH/ &&
    sudo chown -R www-data:www-data $WEB_PATH &&
    sudo chmod -R 755 $WEB_PATH &&
    rm -rf $TEMP_PATH
"

echo "✅ 배포 완료!"
echo ""
echo "🌐 인증 페이지가 배포되었습니다."
echo "📋 다음 단계:"
echo "   1. 서버 URL 확인"
echo "   2. Supabase 대시보드에서 Site URL 업데이트"
echo "   3. 이메일 템플릿에서 확인 URL 업데이트"
echo ""
echo "🔗 접근 URL: http://52.141.58.118/hearty-auth/"