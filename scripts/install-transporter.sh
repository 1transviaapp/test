#!/bin/bash
# ============================================================================
# install-transporter.sh
# Apple Transporter uygulamasını macOS runner'a kurar
# Yedek olarak xcrun altool CLI'ı yapılandırır
# ============================================================================

set -euo pipefail

echo "============================================"
echo "  Apple Transporter Kurulum Scripti"
echo "============================================"
echo ""

# --- Renk kodları ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# ============================================================================
# 1. Homebrew Kontrolü
# ============================================================================
print_info "Homebrew kontrol ediliyor..."

if command -v brew &>/dev/null; then
    print_status "Homebrew mevcut: $(brew --version | head -n 1)"
else
    print_warning "Homebrew bulunamadı, kuruluyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Apple Silicon PATH ayarı
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    print_status "Homebrew kuruldu"
fi

# ============================================================================
# 2. mas (Mac App Store CLI) Kurulumu
# ============================================================================
print_info "mas (Mac App Store CLI) kontrol ediliyor..."

if command -v mas &>/dev/null; then
    print_status "mas mevcut: $(mas version)"
else
    print_info "mas kuruluyor..."
    brew install mas
    print_status "mas kuruldu: $(mas version)"
fi

# ============================================================================
# 3. Transporter Kurulumu
# ============================================================================
TRANSPORTER_APP_ID="1450874784"
TRANSPORTER_PATH="/Applications/Transporter.app"
TRANSPORTER_CLI="${TRANSPORTER_PATH}/Contents/itms/bin/iTMSTransporter"

print_info "Transporter uygulaması kontrol ediliyor..."

if [ -d "$TRANSPORTER_PATH" ]; then
    print_status "Transporter zaten yüklü: ${TRANSPORTER_PATH}"
else
    print_info "Transporter yüklenmeye çalışılıyor (App ID: ${TRANSPORTER_APP_ID})..."
    
    # Mac App Store giriş kontrolü
    if mas account &>/dev/null 2>&1; then
        print_status "Mac App Store hesabı aktif"
        
        if mas install "$TRANSPORTER_APP_ID"; then
            print_status "Transporter başarıyla yüklendi!"
        else
            print_warning "mas install başarısız oldu"
        fi
    else
        print_warning "Mac App Store'a giriş yapılmamış"
        print_warning "mas ile CLI üzerinden otomatik yükleme yapılamıyor (CI/CD ortamlarında normaldir)"
        print_info "VNC ile masaüstüne bağlandığınızda App Store'dan Transporter'ı indirebilir veya xcrun altool kullanabilirsiniz"
    fi
fi

# ============================================================================
# 4. Transporter Doğrulama
# ============================================================================
echo ""
print_info "Transporter durumu kontrol ediliyor..."

if [ -d "$TRANSPORTER_PATH" ]; then
    print_status "Transporter.app: ✅ MEVCUT"
    
    if [ -f "$TRANSPORTER_CLI" ]; then
        print_status "iTMSTransporter CLI: ✅ MEVCUT"
        print_info "CLI Yolu: ${TRANSPORTER_CLI}"
        
        # Versiyon bilgisi
        "$TRANSPORTER_CLI" -version 2>/dev/null || print_warning "Versiyon bilgisi alınamadı"
    else
        print_warning "iTMSTransporter CLI bulunamadı (beklenen: ${TRANSPORTER_CLI})"
    fi
else
    print_warning "Transporter.app yüklenemedi"
    print_info "Yedek yöntem: xcrun altool kullanılabilir"
fi

# ============================================================================
# 5. xcrun altool / notarytool Doğrulama (Yedek Yöntem)
# ============================================================================
echo ""
print_info "Alternatif araçlar kontrol ediliyor..."

if command -v xcrun &>/dev/null; then
    # altool kontrolü
    if xcrun altool --help &>/dev/null 2>&1; then
        print_status "xcrun altool: ✅ MEVCUT (IPA doğrulama ve yükleme için)"
    else
        print_warning "xcrun altool: Mevcut değil veya Xcode gerekli"
    fi
    
    # notarytool kontrolü
    if xcrun notarytool --help &>/dev/null 2>&1; then
        print_status "xcrun notarytool: ✅ MEVCUT (notarization için)"
    fi
else
    print_warning "xcrun bulunamadı — Xcode Command Line Tools gerekli"
fi

# ============================================================================
# 6. Kullanım Bilgileri
# ============================================================================
echo ""
echo "============================================"
echo "  Transporter Kullanım Rehberi"
echo "============================================"

if [ -d "$TRANSPORTER_PATH" ]; then
    cat << 'EOF'

📱 GUI Kullanımı (VNC ile bağlanıldığında):
   Finder → Applications → Transporter

💻 CLI Kullanımı (SSH ile):
   # IPA doğrulama:
   /Applications/Transporter.app/Contents/itms/bin/iTMSTransporter \
     -m verify \
     -f /path/to/your.ipa \
     -u YOUR_APPLE_ID \
     -p YOUR_APP_SPECIFIC_PASSWORD

   # IPA yükleme:
   /Applications/Transporter.app/Contents/itms/bin/iTMSTransporter \
     -m upload \
     -f /path/to/your.ipa \
     -u YOUR_APPLE_ID \
     -p YOUR_APP_SPECIFIC_PASSWORD

EOF
fi

cat << 'EOF'

🔧 xcrun altool ile IPA Yükleme (Alternatif):
   # Doğrulama:
   xcrun altool --validate-app -t ios -f /path/to/your.ipa \
     --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>

   # Yükleme:
   xcrun altool --upload-app -t ios -f /path/to/your.ipa \
     --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>

EOF

print_status "Transporter kurulum scripti tamamlandı!"
