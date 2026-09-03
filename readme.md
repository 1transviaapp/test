# 🍎 GitHub Actions macOS — Uzak Erişim

GitHub Actions üzerinden **macOS sanal makine** çalıştırarak **SSH** ve **VNC (masaüstü)** ile uzak bağlantı kurmanızı sağlayan workflow koleksiyonu.

> **Apple Transporter** desteği dahil — IPA dosyalarınızı doğrudan App Store Connect'e yükleyin.

---

## ✨ Özellikler

- 🔐 **4 farklı uzak erişim yöntemi** (tmate, ngrok, VNC, Tailscale)
- 📱 **Apple Transporter** otomatik kurulumu (GUI + CLI)
- 📦 **IPA klasörü** entegrasyonu — dosyalar otomatik runner'a aktarılır
- 🖥️ **Grafik masaüstü** desteği (VNC ile tam macOS deneyimi)
- ⚡ **Tek tık** ile workflow tetikleme (`workflow_dispatch`)
- 🛡️ **Güvenlik** — erişim kısıtlama, şifre koruması, WireGuard

---

## 📁 Proje Yapısı

```
├── .github/workflows/
│   ├── macos-ssh-tmate.yml       # Yöntem 1: tmate SSH
│   ├── macos-ssh-ngrok.yml       # Yöntem 2: ngrok SSH
│   ├── macos-vnc-desktop.yml     # Yöntem 3: VNC masaüstü
│   └── macos-tailscale.yml       # Yöntem 4: Tailscale ağı
├── ipa/                          # IPA dosyaları (runner'a aktarılır)
├── scripts/
│   ├── install-transporter.sh    # Transporter kurulum scripti
│   ├── setup-environment.sh      # Ortam hazırlık scripti
│   └── setup-vnc.sh              # VNC yapılandırma scripti
└── docs/
    └── connection-guide.md       # Detaylı bağlantı rehberi
```

---

## 🚀 Hızlı Başlangıç

### 1. Repo'yu hazırlayın

```bash
# Repo'yu clone edin
git clone <repo-url>
cd "GitHub Actions macOS"

# IPA dosyanızı ekleyin (opsiyonel)
cp /path/to/MyApp.ipa ipa/
git add ipa/MyApp.ipa
git commit -m "IPA dosyası eklendi"
git push
```

### 2. İlk deneme: tmate SSH (en kolay)

> Secret ayarı gerekmez — hemen kullanabilirsiniz!

1. GitHub → **Actions** → **"macOS SSH (tmate)"** → **Run workflow**
2. macOS sürümünü seçin → **Run workflow**
3. Loglardan SSH URL'sini kopyalayın
4. Terminal'de yapıştırın:
   ```bash
   ssh xxxxxxxxxxxx@nyc1.tmate.io
   ```

### 3. IPA dosyalarına erişin

```bash
# Runner üzerinde (SSH bağlantısından sonra)
ls -la ~/work/*/ipa/          # IPA dosyaları burada
```

---

## 📊 Yöntem Karşılaştırması

| | tmate SSH | ngrok SSH | VNC Masaüstü | Tailscale |
|:---|:---:|:---:|:---:|:---:|
| **Kurulum** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Güvenlik** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **GUI** | ❌ | ❌ | ✅ | ✅ |
| **Transporter GUI** | ❌ CLI | ❌ CLI | ✅ | ✅ |
| **Ek Hesap** | ❌ | ngrok | ngrok | Tailscale |
| **Ek Secret** | ❌ | 2 | 2 | 1 |

---

## 🔑 Secret Ayarları

Kullandığınız yönteme göre repo'nuzda secret tanımlayın:

**Settings → Secrets and variables → Actions → New repository secret**

| Secret | Yöntem | Kaynak |
|:---|:---|:---|
| `NGROK_AUTH_TOKEN` | ngrok SSH, VNC | [ngrok Dashboard](https://dashboard.ngrok.com/get-started/your-authtoken) |
| `SSH_PASS` | ngrok SSH | Kendiniz belirleyin |
| `VNC_PASSWORD` | VNC | Kendiniz belirleyin (maks. 8 kar.) |
| `TAILSCALE_AUTH_KEY` | Tailscale | [Tailscale Keys](https://login.tailscale.com/admin/settings/keys) |

---

## 📱 Transporter ile IPA Yükleme

### GUI (VNC bağlantısı ile)
1. Finder → Applications → **Transporter** açın
2. IPA dosyasını sürükle-bırak
3. Apple ID ile giriş → **Deliver**

### CLI (SSH bağlantısı ile)
```bash
# iTMSTransporter
/Applications/Transporter.app/Contents/itms/bin/iTMSTransporter \
  -m upload -f ~/work/*/ipa/app.ipa \
  -u APPLE_ID -p APP_SPECIFIC_PASSWORD

# veya xcrun altool
xcrun altool --upload-app -t ios \
  -f ~/work/*/ipa/app.ipa \
  --apiKey KEY_ID --apiIssuer ISSUER_ID
```

---

## 📦 IPA Dosyaları

`ipa/` klasörüne koyduğunuz `.ipa` dosyaları workflow çalıştığında otomatik olarak macOS runner'a aktarılır.

| Boyut | Yöntem |
|:---|:---|
| < 100 MB | Doğrudan `git add` ile |
| > 100 MB | [Git LFS](https://git-lfs.github.com) kullanın |

```bash
# Büyük IPA'lar için Git LFS
git lfs install
git lfs track "*.ipa"
git add .gitattributes ipa/BigApp.ipa
git commit -m "LFS ile IPA eklendi"
git push
```

---

## ⚙️ macOS Runner Özellikleri

| Özellik | Değer |
|:---|:---|
| CPU | 4 vCPU |
| RAM | 14 GB |
| Mimari | Apple Silicon (arm64) |
| Maks. Süre | 6 saat (360 dk) |
| Maliyet (private) | 10x çarpan (1 dk macOS = 10 dk kota) |
| Maliyet (public) | Ücretsiz |

---

## ⚠️ Önemli Notlar

- **Private repo** kullanmanız **şiddetle** önerilir
- macOS runner dakikaları **10x çarpan** ile faturalandırılır
- Her oturum **maksimum 6 saat** sürer
- İşiniz bitince workflow'u **iptal edin** (Actions → Cancel)
- Debug workflow'larını production branch'lerde **çalıştırmayın**

---

## 📚 Detaylı Dokümantasyon

Adım adım bağlantı rehberi, sorun giderme ve güvenlik bilgileri için:

📖 **[Bağlantı Rehberi](docs/connection-guide.md)**

---

## 📄 Lisans

Bu proje eğitim ve geliştirme amaçlıdır. GitHub'ın [Kullanım Koşulları](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service)'na uygun şekilde kullanınız.
