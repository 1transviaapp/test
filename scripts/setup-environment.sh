#!/bin/bash
# ============================================================================
# setup-environment.sh
# macOS runner ortamını hazırlar
# Temel araçları kurar, sistem bilgisini raporlar
# ============================================================================

set -euo pipefail

echo "============================================"
echo "  macOS Ortam Hazırlık Scripti"
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
# 1. Sistem Bilgisi Raporu
# ============================================================================
echo -e "${CYAN}── Sistem Bilgisi ──────────────────────────${NC}"
echo ""

print_info "macOS Sürümü : $(sw_vers -productVersion) (Build: $(sw_vers -buildVersion))"
print_info "Hostname      : $(hostname)"
print_info "CPU           : $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)"
print_info "Mimari        : $(uname -m)"
print_info "Çekirdek Sayısı: $(sysctl -n hw.ncpu)"
print_info "RAM           : $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) GB"
print_info "Kullanıcı     : $(whoami)"
print_info "Çalışma Dizini: $(pwd)"

echo ""
echo -e "${CYAN}── Disk Alanı ──────────────────────────────${NC}"
df -h / | tail -1 | awk '{print "  Toplam: "$2"  Kullanılan: "$3"  Boş: "$4"  Kullanım: "$5}'

echo ""

# ============================================================================
# 2. Homebrew Kontrolü ve Güncelleme
# ============================================================================
echo -e "${CYAN}── Homebrew ────────────────────────────────${NC}"

if command -v brew &>/dev/null; then
    print_status "Homebrew mevcut: $(brew --version | head -n 1)"
    print_info "Homebrew güncelleniyor..."
    brew update --quiet
    print_status "Homebrew güncel"
else
    print_info "Homebrew kuruluyor..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
    print_status "Homebrew kuruldu"
fi

echo ""

# ============================================================================
# 3. Temel Araçların Kurulumu
# ============================================================================
echo -e "${CYAN}── Temel Araçlar ───────────────────────────${NC}"

# Kurulacak brew paketleri
BREW_PACKAGES=(
    "mas"      # Mac App Store CLI
    "wget"     # Dosya indirme aracı
    "jq"       # JSON işleme aracı
    "tree"     # Dizin yapısı görüntüleme
)

for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        print_status "${pkg} zaten yüklü"
    else
        print_info "${pkg} kuruluyor..."
        brew install --quiet "$pkg"
        print_status "${pkg} kuruldu"
    fi
done

echo ""

# ============================================================================
# 4. Xcode Command Line Tools Kontrolü
# ============================================================================
echo -e "${CYAN}── Xcode Araçları ──────────────────────────${NC}"

if xcode-select -p &>/dev/null; then
    XCODE_PATH=$(xcode-select -p)
    print_status "Xcode CLT mevcut: ${XCODE_PATH}"
    
    # Xcode sürümü
    if command -v xcodebuild &>/dev/null; then
        XCODE_VERSION=$(xcodebuild -version 2>/dev/null | head -n 1 || echo "Bilinmiyor")
        print_info "Xcode Sürümü: ${XCODE_VERSION}"
    fi
    
    # Swift sürümü
    if command -v swift &>/dev/null; then
        SWIFT_VERSION=$(swift --version 2>/dev/null | head -n 1 || echo "Bilinmiyor")
        print_info "Swift: ${SWIFT_VERSION}"
    fi
else
    print_warning "Xcode Command Line Tools bulunamadı"
    print_info "Kurmak için: xcode-select --install"
fi

echo ""

# ============================================================================
# 5. IPA Klasörü Kontrolü
# ============================================================================
echo -e "${CYAN}── IPA Dosyaları ───────────────────────────${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IPA_DIR="${REPO_ROOT}/ipa"

if [ -d "$IPA_DIR" ]; then
    IPA_COUNT=$(find "$IPA_DIR" -name "*.ipa" -type f 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$IPA_COUNT" -gt 0 ]; then
        print_status "IPA klasörü mevcut — ${IPA_COUNT} adet IPA dosyası bulundu:"
        find "$IPA_DIR" -name "*.ipa" -type f -exec basename {} \; | while read -r f; do
            echo "         📦 ${f}"
        done
        
        # Boyut bilgisi
        TOTAL_SIZE=$(du -sh "$IPA_DIR" 2>/dev/null | cut -f1)
        print_info "Toplam boyut: ${TOTAL_SIZE}"
    else
        print_warning "IPA klasörü mevcut ama IPA dosyası yok"
        print_info "IPA dosyalarınızı '${IPA_DIR}' klasörüne ekleyin"
    fi
else
    print_warning "IPA klasörü bulunamadı: ${IPA_DIR}"
fi

echo ""

# ============================================================================
# 6. Ağ Bilgileri
# ============================================================================
echo -e "${CYAN}── Ağ Bilgileri ────────────────────────────${NC}"

# IP adresi
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "Bilinmiyor")
print_info "Lokal IP: ${LOCAL_IP}"

# Public IP
PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo "Alınamadı")
print_info "Public IP: ${PUBLIC_IP}"

echo ""

# ============================================================================
# 7. Özet
# ============================================================================
echo "============================================"
echo -e "${GREEN}  Ortam hazırlığı tamamlandı! ✅${NC}"
echo "============================================"
echo ""
print_info "Sonraki adım: Transporter kurulumu için 'scripts/install-transporter.sh' çalıştırın"
print_info "SSH/VNC bağlantısı kurulduktan sonra macOS ortamınız kullanıma hazır"
