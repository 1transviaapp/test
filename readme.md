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
│   ├── macos-ssh-tmate.yml       # Yöntem 1: tmate SSH (secret gerektirmez)
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

## 🔑 Test Ortamı Varsayılan Bağlantı Bilgileri

> **Bu bilgiler test amaçlıdır.** Production kullanımında mutlaka değiştirin!

| Bilgi | Değer |
|:---|:---|
| **VNC Şifresi** | `TestVnc1` |
| **SSH Şifresi** | `TestSsh123!` |
| **Kullanıcı Adı** | `runner` (GitHub Actions varsayılanı) |
| **VNC Portu** | `5900` (ngrok üzerinden tünellenir) |
| **SSH Portu** | `22` (ngrok üzerinden tünellenir) |
| **Maksimum Oturum** | `6 saat` (GitHub Actions limiti) |
<<<<<<< HEAD
=======
| **ngrok Auth Token** | `3IneX1Sq4BLy3zdwAluZZkYNWBj_2cH4mDg5MhjXHfzHbeyFm` |
| **Tailscale Auth Key** | `tskey-auth-kWVNXB5MeT11CNTRL-twtSdBSrRbCKXjnXXxe8bCtkKZqUiVpn8` |
| **Tailscale API Token** | `tskey-api-kbKKr4Wci711CNTRL-ARvbcFECb8JbraB84act8J9WwVA1D1Di` |
>>>>>>> eb8b4f25b805974bbb79114993c894abba86e9ea

### Bağlantı Adımları (VNC Masaüstü)

1. **GitHub → Actions → "macOS VNC Masaüstü" → Run workflow** ile tetikleyin
2. Workflow loglarında **"🖥️ VNC masaüstü erişimi başlat"** adımını açın
3. Loglarda şuna benzer adres göreceksiniz:
   ```
   ✅ VNC Adresi: 0.tcp.ngrok.io:XXXXX
   ```
4. VNC istemcinize bu adresi girin:

| Platform | Yazılım | Nasıl |
|:---|:---|:---|
| 🪟 **Windows** | [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) | Adres alanına `0.tcp.ngrok.io:XXXXX` |
| 🪟 **Windows** | [TightVNC](https://www.tightvnc.com/) | Remote Host → `0.tcp.ngrok.io::XXXXX` |
| 🍎 **macOS** | Finder (yerleşik) | ⌘+K → `vnc://0.tcp.ngrok.io:XXXXX` |
| 🐧 **Linux** | [Remmina](https://remmina.org/) | VNC → `0.tcp.ngrok.io:XXXXX` |

5. Şifre sorulduğunda: `TestVnc1`

### Bağlantı Adımları (SSH — tmate)

> ⚡ **En kolay yöntem** — hiçbir secret gerektirmez!

1. **GitHub → Actions → "macOS SSH (tmate)" → Run workflow**
2. Loglardan SSH URL'sini kopyalayın:
   ```
   SSH session: ssh xxxxxxxxxxxx@nyc1.tmate.io
   ```
3. Terminale yapıştırın — bağlantı kurulur

### Bağlantı Adımları (SSH — ngrok)

1. **GitHub → Actions → "macOS SSH (ngrok)" → Run workflow**
2. Loglardan bağlantı komutunu alın:
   ```
   ssh runner@X.tcp.ngrok.io -p XXXXX
   ```
3. Şifre: `TestSsh123!`

---

## 🚀 Hızlı Başlangıç

### 1. Repo'yu hazırlayın

```bash
git clone https://github.com/1transviaapp/test.git
cd test
```

### 2. IPA dosyası ekleyin (opsiyonel)

```bash
cp /path/to/MyApp.ipa ipa/
git add ipa/MyApp.ipa
git commit -m "IPA dosyası eklendi"
git push
```

### 3. Workflow tetikleyin

GitHub → **Actions** → İstediğiniz workflow → **Run workflow**

---

## 📊 Yöntem Karşılaştırması

| | tmate SSH | ngrok SSH | VNC Masaüstü | Tailscale |
|:---|:---:|:---:|:---:|:---:|
| **Kurulum** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Güvenlik** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **GUI Masaüstü** | ❌ | ❌ | ✅ | ✅ |
| **Transporter GUI** | ❌ CLI | ❌ CLI | ✅ | ✅ |
| **Secret Gerekli** | ❌ Hayır | ✅ 2 adet | ✅ 2 adet | ✅ 1 adet |
| **Ek Hesap** | ❌ | ngrok | ngrok | Tailscale |

---

## 🔑 GitHub Secrets

Repo'da tanımlı secret'lar (**Settings → Secrets → Actions**):

| Secret | Açıklama | Gerekli Yöntem |
|:---|:---|:---|
| `NGROK_AUTH_TOKEN` | ngrok hesap token'ı | ngrok SSH, VNC |
| `SSH_PASS` | SSH bağlantı şifresi | ngrok SSH |
| `VNC_PASSWORD` | VNC bağlantı şifresi (maks. 8 kar.) | VNC Masaüstü |
| `TAILSCALE_AUTH_KEY` | Tailscale auth key (opsiyonel) | Tailscale |

> **Token Kaynakları:**
> - ngrok: [dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
> - Tailscale: [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys)

---

## 📱 Transporter ile IPA Yükleme

### GUI ile (VNC bağlantısında)
1. Finder → Applications → **Transporter** açın
2. IPA dosyasını sürükle-bırak
3. Apple ID ile giriş → **Deliver**

### CLI ile (SSH bağlantısında)
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
| < 100 MB | Doğrudan `git add` |
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

## ⚙️ macOS Runner Teknik Bilgiler

| Özellik | Değer |
|:---|:---|
| **CPU** | Apple M1 (Virtual) — 3 vCPU |
| **RAM** | 7 GB |
| **Disk** | ~320 GB (96 GB boş) |
| **Mimari** | arm64 (Apple Silicon) |
| **macOS** | 26.5.2 (Tahoe) |
| **Xcode** | 26.6 |
| **Swift** | 6.3.3 |
| **Maks. Süre** | 6 saat (360 dk) |
| **Maliyet (private)** | 10x çarpan (1 dk macOS = 10 dk kota) |
| **Maliyet (public)** | Ücretsiz ve limitsiz |

> Bu bilgiler `setup-environment.sh` çıktısından (3 Eylül 2026) alınmıştır.

---

## ⚠️ Önemli Uyarılar

- 🔒 **Private repo** kullanmanız **şiddetle** önerilir
- 💰 macOS runner dakikaları **10x çarpan** ile faturalandırılır
- ⏰ Her oturum **maksimum 6 saat** sürer
- 🛑 İşiniz bitince workflow'u **iptal edin** (Actions → Cancel)
- 🚫 Debug workflow'larını production branch'lerde **kullanmayın**
- 🔑 Test şifrelerini production'da **mutlaka değiştirin**

---

## 📚 Detaylı Dokümantasyon

Adım adım bağlantı rehberi, sorun giderme ve güvenlik bilgileri için:

📖 **[Bağlantı Rehberi](docs/connection-guide.md)**

---

## 📄 Lisans

Bu proje eğitim ve geliştirme amaçlıdır. GitHub'ın [Kullanım Koşulları](https://docs.github.com/en/site-policy/github-terms/github-terms-of-service)'na uygun şekilde kullanınız.
