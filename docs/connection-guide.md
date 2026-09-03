# Bağlantı Rehberi

GitHub Actions macOS runner'larına uzak erişim için adım adım rehber.

> **Repo:** `1transviaapp/test`

---

## 🔑 Test Ortamı Varsayılan Bilgiler

| Bilgi | Değer |
|:---|:---|
| **VNC Şifresi** | `TestVnc1` |
| **SSH Şifresi** | `TestSsh123!` |
| **Kullanıcı Adı** | `runner` |
| **macOS Sürümü** | 26.5.2 (Tahoe) — Apple M1 Virtual |

---

## 📋 Ön Hazırlık

### GitHub Secrets

Aşağıdaki secret'lar `1transviaapp/test` repo'sunda **zaten tanımlıdır:**

| Secret Adı | Durum | Gerekli Yöntem |
|:---|:---|:---|
| `NGROK_AUTH_TOKEN` | ✅ Tanımlı | ngrok SSH, VNC |
| `SSH_PASS` | ✅ Tanımlı (`TestSsh123!`) | ngrok SSH |
| `VNC_PASSWORD` | ✅ Tanımlı (`TestVnc1`) | VNC Masaüstü |
| `TAILSCALE_AUTH_KEY` | ❌ Tanımlı değil | Tailscale |

---

## 🔌 Yöntem 1: tmate ile SSH (En Kolay)

### Gereksinimler
- Hiçbir ek hesap veya secret gerekmez

### Adımlar

1. **Workflow'u tetikleyin:**
   - GitHub repo → **Actions** → **"macOS SSH (tmate)"** → **Run workflow**
   - macOS sürümü ve timeout seçin
   - **Run workflow** tıklayın

2. **Bağlantı bilgilerini alın:**
   - Çalışan workflow'a tıklayın
   - **"🔐 tmate SSH oturumu başlat"** adımını açın
   - Loglardan SSH URL'sini bulun:
     ```
     SSH session: ssh xxxxxxxxxxxx@nyc1.tmate.io
     ```

3. **Bağlanın:**
   ```bash
   ssh xxxxxxxxxxxx@nyc1.tmate.io
   ```

4. **IPA dosyalarına erişin:**
   ```bash
   ls -la ~/work/test/test/ipa/
   ```

---

## 🔌 Yöntem 2: ngrok ile SSH

### Gereksinimler
- [ngrok.com](https://ngrok.com) hesabı (ücretsiz)
- GitHub Secrets: `NGROK_AUTH_TOKEN`, `SSH_PASS`

### ngrok Hesap Kurulumu

1. [ngrok.com/signup](https://dashboard.ngrok.com/signup) adresinden kayıt olun
2. Dashboard → **Your Authtoken** → Token'ı kopyalayın
3. GitHub repo → Settings → Secrets → `NGROK_AUTH_TOKEN` olarak ekleyin
4. `SSH_PASS` secret'ını güçlü bir şifre ile oluşturun

### Adımlar

1. **Workflow'u tetikleyin:**
   - Actions → **"macOS SSH (ngrok)"** → **Run workflow**

2. **Bağlantı bilgilerini alın:**
   - **"🚀 ngrok SSH tüneli başlat"** adımındaki loglardan:
     ```
     ssh runner@X.tcp.ngrok.io -p XXXXX
     ```

3. **Bağlanın:**
   ```bash
   ssh runner@X.tcp.ngrok.io -p XXXXX
   # Şifre: TestSsh123!
   ```

---

## 🖥️ Yöntem 3: VNC ile Grafik Masaüstü

### Gereksinimler
- ngrok hesabı
- GitHub Secrets: `NGROK_AUTH_TOKEN`, `VNC_PASSWORD`
- VNC istemci yazılımı

### VNC İstemci Kurulumu

| Platform | Yazılım | Nasıl Bağlanılır |
|:---|:---|:---|
| **macOS** | Finder (yerleşik) | Finder → ⌘+K → `vnc://adres:port` |
| **Windows** | [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) | Adres alanına `host:port` yazın |
| **Windows** | [TightVNC](https://www.tightvnc.com/) | Remote Host → `host::port` |
| **Linux** | [Remmina](https://remmina.org/) | VNC → `host:port` |

### Adımlar

1. **Workflow'u tetikleyin:**
   - Actions → **"macOS VNC Masaüstü"** → **Run workflow**
   - "IPA dosyalarını masaüstüne kopyala" seçeneğini aktif bırakın

2. **Bağlantı bilgilerini alın:**
   - **"🖥️ VNC masaüstü erişimi başlat"** adımındaki loglardan VNC adresi

3. **Bağlanın:**
   - macOS: Finder → ⌘+K → `vnc://X.tcp.ngrok.io:XXXXX`
   - Windows: RealVNC Viewer → `X.tcp.ngrok.io:XXXXX`
   - Şifre: `TestVnc1`

4. **Masaüstünde:**
   - IPA dosyaları **Desktop/IPA_Dosyalari/** klasöründe
   - Transporter: Applications → Transporter

---

## 🔗 Yöntem 4: Tailscale ile Güvenli Ağ

### Gereksinimler
- [tailscale.com](https://tailscale.com) hesabı (ücretsiz — 3 kullanıcıya kadar)
- Kendi cihazınızda Tailscale kurulu olmalı
- GitHub Secret: `TAILSCALE_AUTH_KEY`

### Tailscale Kurulumu

1. **Hesap oluşturun:** [tailscale.com](https://tailscale.com)
2. **Kendi cihazınıza kurun:**
   - macOS: `brew install tailscale` veya [App Store](https://apps.apple.com/app/tailscale/id1475387142)
   - Windows: [tailscale.com/download](https://tailscale.com/download/windows)
   - Linux: `curl -fsSL https://tailscale.com/install.sh | sh`
3. **Auth Key oluşturun:**
   - [Admin Console → Settings → Keys](https://login.tailscale.com/admin/settings/keys)
   - **Generate auth key** → **Ephemeral** işaretli → Kopyalayın
4. **GitHub Secret'a ekleyin:** `TAILSCALE_AUTH_KEY`

### Adımlar

1. **Workflow'u tetikleyin:**
   - Actions → **"macOS Tailscale"** → **Run workflow**
   - SSH ve/veya VNC seçeneklerini aktif edin

2. **Bağlantı bilgilerini alın:**
   - Loglardan Tailscale IP adresini bulun:
     ```
     Tailscale IP: 100.x.y.z
     ```

3. **Bağlanın:**
   ```bash
   # SSH
   ssh runner@100.x.y.z
   
   # VNC (etkinse)
   # Finder → ⌘+K → vnc://100.x.y.z:5900
   ```

---

## 📱 Transporter Kullanımı

### GUI ile (VNC bağlantısında)

1. Finder → Applications → **Transporter** açın
2. **IPA dosyanızı** sürükleyip Transporter penceresine bırakın
3. Apple ID ile giriş yapın
4. **Deliver** butonuna tıklayın

### CLI ile (SSH bağlantısında)

```bash
# iTMSTransporter ile yükleme
/Applications/Transporter.app/Contents/itms/bin/iTMSTransporter \
  -m upload \
  -f ~/work/*/ipa/uygulamaniz.ipa \
  -u YOUR_APPLE_ID \
  -p YOUR_APP_SPECIFIC_PASSWORD

# Alternatif: xcrun altool ile
xcrun altool --upload-app -t ios \
  -f ~/work/*/ipa/uygulamaniz.ipa \
  --apiKey YOUR_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

> **Not:** App Store Connect API Key kullanmak 2FA sorunlarını önler.
> [App Store Connect → Users → Keys](https://appstoreconnect.apple.com/access/api) adresinden oluşturabilirsiniz.

---

## 📦 IPA Dosyalarını Kullanma

### IPA Dosyası Ekleme (Repo'ya)

```bash
# IPA dosyanızı ipa/ klasörüne kopyalayın
cp /path/to/MyApp.ipa ipa/

# Git'e ekleyin
git add ipa/MyApp.ipa
git commit -m "IPA dosyası eklendi"
git push
```

> **Uyarı:** GitHub'da dosya boyutu limiti 100 MB'dır.
> Daha büyük dosyalar için [Git LFS](https://git-lfs.github.com) kullanın:
> ```bash
> git lfs install
> git lfs track "*.ipa"
> git add .gitattributes
> git add ipa/MyApp.ipa
> git commit -m "LFS ile IPA eklendi"
> git push
> ```

### IPA Dosyalarının Runner'daki Konumu

| Yöntem | IPA Yolu |
|:---|:---|
| **Tümü** | `~/work/test/test/ipa/` |
| **VNC (masaüstüne kopyalanmışsa)** | `~/Desktop/IPA_Dosyalari/` |

---

## ⚠️ Güvenlik Uyarıları

1. **Private repo kullanın** — Public repo'larda secret'lar ifşa olabilir
2. **Şifreleri güçlü tutun** — En az 12 karakter, özel karakterli
3. **Oturumları kısa tutun** — İşiniz bitince workflow'u iptal edin
4. **Token'ları döndürün** — ngrok/Tailscale token'larını düzenli yenileyin
5. **Debug workflow'larını silin** — Kullanılmayan workflow'ları devre dışı bırakın

---

## 🔧 Sorun Giderme

| Sorun | Çözüm |
|:---|:---|
| tmate URL görünmüyor | Workflow loglarını yenileyin, birkaç saniye bekleyin |
| ngrok bağlanamıyor | `NGROK_AUTH_TOKEN` secret'ını kontrol edin |
| VNC siyah ekran | Farklı bir macOS sürümü deneyin (`macos-14` önerilir) |
| Tailscale IP alınamıyor | `TAILSCALE_AUTH_KEY`'in süresi dolmuş olabilir, yeni key oluşturun |
| Transporter kurulmuyor | CI runner'da App Store girişi olmayabilir, `xcrun altool` kullanın |
| IPA dosyaları bulunamıyor | `ipa/` klasörüne dosya commit edildiğinden emin olun |
| Bağlantı çok yavaş | Daha yakın bir ngrok bölgesi veya Tailscale kullanın |
| Workflow 6 saatte kapanıyor | GitHub limiti — yeni workflow başlatın |
