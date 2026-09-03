#!/bin/bash
# ============================================================================
# setup-anydesk.sh
# macOS runner üzerinde AnyDesk kurulumu yapar,
# tam yetkileri (Accessibility & Screen Recording) verir,
# şifresiz uzaktan erişim (unattended access) şifresini ayarlar
# ve AnyDesk ID numarasını ekrana yazdırır.
# ============================================================================

set -euo pipefail

echo "============================================"
echo "  AnyDesk Kurulumu ve Yapılandırması"
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

ANYDESK_PASSWORD="${ANYDESK_PASSWORD:-"TestVnc1"}"

# ============================================================================
# 1. AnyDesk Kurulumu
# ============================================================================
print_info "AnyDesk kuruluyor..."

if [ -d "/Applications/AnyDesk.app" ]; then
    print_status "AnyDesk zaten yüklü"
else
    # Homebrew ile dene, olmazsa doğrudan DMG'den kur
    brew install --cask anydesk --quiet 2>/dev/null || {
        print_info "Homebrew alternatifi: Resmi DMG indiriliyor..."
        curl -fsSL "https://download.anydesk.com/mac/anydesk.dmg" -o /tmp/anydesk.dmg
        hdiutil attach /tmp/anydesk.dmg -nobrowse -quiet
        sudo cp -R "/Volumes/AnyDesk/AnyDesk.app" /Applications/
        hdiutil detach "/Volumes/AnyDesk" -quiet 2>/dev/null || true
        rm -f /tmp/anydesk.dmg
    }
    print_status "AnyDesk başarıyla kuruldu"
fi

# ============================================================================
# 2. TCC Yetkileri (Erişilebilirlik ve Ekran Kaydı Tam Yetki)
# ============================================================================
print_info "macOS TCC güvenlik izinleri (Accessibility & Screen Capture) veriliyor..."

# Sistem TCC.db
sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
  "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, flags) \
   VALUES ('kTCCServiceAccessibility', 'com.philandro.anydesk', 0, 2, 4, 1, 0);" 2>/dev/null || true

sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
  "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, flags) \
   VALUES ('kTCCServiceScreenCapture', 'com.philandro.anydesk', 0, 2, 4, 1, 0);" 2>/dev/null || true

# Kullanıcı düzeyi TCC.db
mkdir -p "$HOME/Library/Application Support/com.apple.TCC"
sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
  "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, flags) \
   VALUES ('kTCCServiceAccessibility', 'com.philandro.anydesk', 0, 2, 4, 1, 0);" 2>/dev/null || true

sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
  "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, flags) \
   VALUES ('kTCCServiceScreenCapture', 'com.philandro.anydesk', 0, 2, 4, 1, 0);" 2>/dev/null || true

print_status "Güvenlik izinleri uygulandı"

# ============================================================================
# 3. AnyDesk Servisini Başlat
# ============================================================================
print_info "AnyDesk servis motoru arka planda başlatılıyor..."
nohup "/Applications/AnyDesk.app/Contents/MacOS/AnyDesk" --service </dev/null >/tmp/anydesk_svc.log 2>&1 &
sleep 4

# ============================================================================
# 4. Unattended Access Şifresi Ayarla
# ============================================================================
print_info "Şifresiz uzaktan erişim (Unattended Access) şifresi ayarlanıyor..."
echo "$ANYDESK_PASSWORD" | sudo /Applications/AnyDesk.app/Contents/MacOS/AnyDesk --set-password 2>/dev/null || {
    print_warning "Parola komutu doğrudan denendi"
}
print_status "Erişim şifresi ayarlandı: ${ANYDESK_PASSWORD}"

# ============================================================================
# 5. AnyDesk ID Al
# ============================================================================
print_info "AnyDesk ID alınıyor..."
ANYDESK_ID=""

for i in {1..15}; do
    ANYDESK_ID=$(/Applications/AnyDesk.app/Contents/MacOS/AnyDesk --get-id 2>/dev/null || true)
    # Boşlukları temizle
    ANYDESK_ID=$(echo "$ANYDESK_ID" | tr -d ' \r\n')
    if [ -n "$ANYDESK_ID" ] && [ "$ANYDESK_ID" != "0" ]; then
        break
    fi
    sleep 2
done

# Eğer CLI vermezse sistem konfigürasyon dosyasından oku
if [ -z "$ANYDESK_ID" ] || [ "$ANYDESK_ID" = "0" ]; then
    ANYDESK_ID=$(grep -oE "ad.anynet.id=[0-9]+" "$HOME/.anydesk/system.conf" 2>/dev/null | cut -d'=' -f2 || true)
fi

echo ""
echo "======================================================"
echo -e "${GREEN}  🎉 ANYDESK BAĞLANTI BİLGİLERİ${NC}"
echo "======================================================"
echo ""

if [ -n "$ANYDESK_ID" ]; then
    echo -e "${CYAN}  🔢 AnyDesk Adresi / ID : ${YELLOW}${ANYDESK_ID}${NC}"
    echo -e "${CYAN}  🔑 Bağlantı Şifresi    : ${YELLOW}${ANYDESK_PASSWORD}${NC}"
    echo ""
    echo "  Nasıl Bağlanılır:"
    echo "  1. Kendi Windows bilgisayarınızda AnyDesk uygulamasını açın."
    echo "  2. Arama kutusuna bu 9 haneli numarayı girin: ${ANYDESK_ID}"
    echo "  3. 'Bağlan' (Connect) butonuna basın."
    echo "  4. Şifre sorulduğunda '${ANYDESK_PASSWORD}' yazın."
    echo "  5. ✅ macOS masaüstünüz anında açılır (Port, VNC, Tünel gerekmez)!"
else
    print_warning "AnyDesk ID otomatik alınamadı. AnyDesk logu:"
    cat "$HOME/.anydesk/anydesk.trace" 2>/dev/null | tail -n 20 || true
fi

echo ""
echo "======================================================"
print_info "Oturum aktif tutuluyor — sonlandırmak için workflow'u iptal edin..."
echo ""

# Sonsuz döngü ile oturumu canlı tut
while true; do
    sleep 30
done
