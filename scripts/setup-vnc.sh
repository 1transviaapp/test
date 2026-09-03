#!/bin/bash
# ============================================================================
# setup-vnc.sh
# macOS runner üzerinde VNC (Screen Sharing) erişimini yapılandırır
# ngrok TCP tüneli ile dışarıdan bağlantı sağlar
# ============================================================================

set -euo pipefail

echo "============================================"
echo "  macOS VNC Masaüstü Erişim Yapılandırması"
echo "============================================"
echo ""

# --- Renk kodları ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# ============================================================================
# 1. Parametreler
# ============================================================================
VNC_PASSWORD="${VNC_PASSWORD:-""}"
NGROK_AUTH_TOKEN="${NGROK_AUTH_TOKEN:-""}"

if [ -z "$VNC_PASSWORD" ]; then
    print_error "VNC_PASSWORD ortam değişkeni ayarlanmamış!"
    print_info "Kullanım: VNC_PASSWORD=sifre123 NGROK_AUTH_TOKEN=xxx ./setup-vnc.sh"
    exit 1
fi

if [ -z "$NGROK_AUTH_TOKEN" ]; then
    print_error "NGROK_AUTH_TOKEN ortam değişkeni ayarlanmamış!"
    exit 1
fi

# VNC şifresi maksimum 8 karakter olabilir
if [ ${#VNC_PASSWORD} -gt 8 ]; then
    print_warning "VNC şifresi 8 karaktere kısaltıldı (VNC protokol limiti)"
    VNC_PASSWORD="${VNC_PASSWORD:0:8}"
fi

# ============================================================================
# 2. Kullanıcı Şifresi Ayarla
# ============================================================================
print_info "Kullanıcı şifresi ayarlanıyor..."

CURRENT_USER=$(whoami)
echo "${VNC_PASSWORD}" | sudo dscl . -passwd /Users/"${CURRENT_USER}" 2>/dev/null || {
    # Alternatif yöntem
    sudo sysadminctl -resetPasswordFor "${CURRENT_USER}" -newPassword "${VNC_PASSWORD}" 2>/dev/null || {
        print_warning "Şifre ayarlanamadı, mevcut şifre kullanılacak"
    }
}
print_status "Kullanıcı şifresi ayarlandı"

# ============================================================================
# 3. Screen Sharing / Remote Management Etkinleştir
# ============================================================================
print_info "macOS Screen Sharing etkinleştiriliyor..."

# ARDAgent (Apple Remote Desktop Agent) yapılandırması
KICKSTART="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"

if [ -f "$KICKSTART" ]; then
    # Remote Management'ı etkinleştir
    sudo "$KICKSTART" -activate -configure \
        -allowAccessFor -allUsers \
        -privs -all \
        -clientopts -setmenuextra -menuextra yes \
        2>/dev/null || true
    
    print_status "Remote Management etkinleştirildi"
else
    print_warning "kickstart bulunamadı, Screen Sharing servisi deneniyor..."
    
    # Alternatif: launchctl ile
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
fi

# Screen Sharing servisinin çalıştığını doğrula
sleep 2
if sudo launchctl list | grep -q "com.apple.screensharing"; then
    print_status "Screen Sharing servisi çalışıyor"
else
    print_warning "Screen Sharing servisi başlatılamadı — alternatif VNC sunucusu deneniyor..."
    
    # Alternatif: open-source VNC server (x11vnc veya benzeri)
    if command -v brew &>/dev/null; then
        brew install tiger-vnc 2>/dev/null || true
    fi
fi

# ============================================================================
# 4. ngrok Kurulumu ve Yapılandırması
# ============================================================================
print_info "ngrok kontrol ediliyor..."

if ! command -v ngrok &>/dev/null; then
    print_info "ngrok kuruluyor..."
    
    if command -v brew &>/dev/null; then
        brew install ngrok
    else
        # Manuel kurulum
        ARCH=$(uname -m)
        if [[ "$ARCH" == "arm64" ]]; then
            NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.zip"
        else
            NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip"
        fi
        
        curl -fsSL "$NGROK_URL" -o /tmp/ngrok.zip
        unzip -o /tmp/ngrok.zip -d /usr/local/bin/
        rm /tmp/ngrok.zip
    fi
    print_status "ngrok kuruldu"
else
    print_status "ngrok zaten mevcut: $(ngrok --version)"
fi

# ngrok auth
print_info "ngrok kimlik doğrulama yapılıyor..."
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"
print_status "ngrok yapılandırıldı"

# ============================================================================
# 5. ngrok TCP Tüneli Başlat (VNC portu: 5900)
# ============================================================================
VNC_PORT=5900

print_info "ngrok TCP tüneli başlatılıyor (port ${VNC_PORT})..."

# ngrok'u arka planda başlat
ngrok tcp "$VNC_PORT" --log=stdout --log-format=json > /tmp/ngrok_vnc.log 2>&1 &
NGROK_PID=$!

# ngrok'un başlamasını bekle
sleep 5

# Tünel URL'sini al
TUNNEL_URL=""
for i in {1..10}; do
    TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | \
        python3 -c "import sys,json; t=json.load(sys.stdin)['tunnels']; print(t[0]['public_url'] if t else '')" 2>/dev/null || true)
    
    if [ -n "$TUNNEL_URL" ]; then
        break
    fi
    sleep 2
done

# ============================================================================
# 6. Bağlantı Bilgileri
# ============================================================================
echo ""
echo "============================================"
echo -e "${GREEN}  VNC Bağlantı Bilgileri${NC}"
echo "============================================"
echo ""

if [ -n "$TUNNEL_URL" ]; then
    # tcp://X.tcp.ngrok.io:XXXXX formatından adresi ayıkla
    VNC_HOST=$(echo "$TUNNEL_URL" | sed 's|tcp://||')
    
    print_status "VNC Adresi: ${VNC_HOST}"
    echo ""
    echo -e "${CYAN}  Bağlantı Yöntemleri:${NC}"
    echo ""
    echo "  🍎 macOS: Finder → ⌘+K → vnc://${VNC_HOST}"
    echo "  🪟 Windows: RealVNC/TightVNC → ${VNC_HOST}"
    echo "  🐧 Linux: Remmina → VNC → ${VNC_HOST}"
    echo ""
    echo "  👤 Kullanıcı: ${CURRENT_USER}"
    echo "  🔑 Şifre: (VNC_PASSWORD secret'ında tanımlı)"
    echo ""
    print_info "ngrok PID: ${NGROK_PID}"
    print_info "ngrok Dashboard: http://localhost:4040"
else
    print_error "ngrok tünel URL'si alınamadı!"
    print_info "ngrok loglarını kontrol edin: cat /tmp/ngrok_vnc.log"
fi

echo ""
print_warning "Bağlantıyı sonlandırmak için: kill ${NGROK_PID}"
echo "============================================"

# Oturumu canlı tut
print_info "VNC oturumu aktif — sonlandırmak için Ctrl+C"
echo ""

# Sonsuz döngü ile oturumu canlı tut
while true; do
    if ! kill -0 "$NGROK_PID" 2>/dev/null; then
        print_error "ngrok sonlandı!"
        exit 1
    fi
    sleep 30
done
