# ClaudeBar

<p align="center">
  <img src="../assets/claudebar-icon.png" alt="ClaudeBar Simgesi" width="128" height="128">
</p>

<p align="center">
  <strong>Claude kullanım limitlerini gerçek zamanlı izlemek için yerel bir macOS menü çubuğu uygulaması.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="Lisans">
</p>

<p align="center">
  <a href="../README.md">English</a> •
  <a href="README-TR.md">Türkçe</a> •
  <a href="README-ZH.md">中文</a> •
  <a href="README-HI.md">हिन्दी</a> •
  <a href="README-ES.md">Español</a> •
  <a href="README-FR.md">Français</a> •
  <a href="README-AR.md">العربية</a> •
  <a href="README-PT.md">Português</a> •
  <a href="README-JA.md">日本語</a> •
  <a href="README-RU.md">Русский</a> •
  <a href="README-IT.md">Italiano</a>
</p>

---

## Özellikler

- **Gerçek Zamanlı Kullanım İzleme** - Mevcut oturum ve haftalık kullanım limitlerini bir bakışta görün
- **Plan Rozeti** - Mevcut aboneliğinizi gösterir (Pro, Max, Team)
- **Ekstra Kullanım Desteği** - Etkinleştirildiğinde kullandıkça öde kredilerini takip edin
- **Özelleştirilebilir Bildirimler** - %50, %75, %100 veya sıfırlandığında bildirim alın
- **Otomatik Yenileme** - Yapılandırılabilir yenileme aralığı (30sn, 1dk, 2dk, 5dk)
- **Giriş Sırasında Başlat** - İsteğe bağlı olarak Mac'inizle birlikte başlatın
- **Menü Çubuğunda Yüzde** - Menü çubuğu simgesinin yanında yüzdeyi gösterin/gizleyin
- **Yerel Deneyim** - SwiftUI ile oluşturulmuş, macOS tasarım ilkelerini takip eder
- **Hafif** - Minimum kaynak kullanımı, Electron yok
- **Gizlilik Odaklı** - Analitik yok, telemetri yok

## Ekran Görüntüleri

<p align="center">
  <img src="../screenshots/claudebar-screenshot-general.png" alt="ClaudeBar Genel Görünüm" width="380">
</p>

<p align="center">
  <em>Plan rozeti ile gerçek zamanlı kullanım izleme</em>
</p>

<details>
<summary><strong>Daha Fazla Ekran Görüntüsü</strong></summary>

<br>

| Ayarlar | Bildirimler | Hakkında |
|:-------:|:-----------:|:--------:|
| <img src="../screenshots/claudebar-screenshot-settings.png" alt="Ayarlar" width="250"> | <img src="../screenshots/claudebar-screenshot-notifications.png" alt="Bildirimler" width="250"> | <img src="../screenshots/claudebar-screenshot-about.png" alt="Hakkında" width="250"> |

</details>

## Gereksinimler

- macOS 14.0 (Sonoma) veya üstü
- [Claude Code](https://claude.ai/code) kurulu ve giriş yapılmış olmalı
- Aktif bir Claude Pro, Max veya Team aboneliği

## Kurulum

### Önceden Derlenmiş Dosyayı İndirin

En son `.app` dosyasını [Releases](https://github.com/kemalasliyuksek/claudebar/releases) sayfasından indirin ve Uygulamalar klasörünüze sürükleyin.

### Kaynaktan Derleyin

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

Uygulama paketi `.build/release/ClaudeBar.app` konumunda oluşturulacaktır.

Kurmak için:
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## Kullanım

1. Claude Code'a giriş yaptığınızdan emin olun (terminalde `claude` komutu çalışmalı)
2. ClaudeBar'ı Uygulamalar veya Spotlight'tan başlatın
3. Kullanım limitlerini görmek için menü çubuğundaki gösterge simgesine tıklayın

### Ayarlar

Yapılandırmak için ⚙️ simgesine tıklayın:

| Ayar | Açıklama |
|------|----------|
| Girişte başlat | Oturum açtığınızda otomatik olarak başla |
| Menü çubuğunda % göster | Menü çubuğu simgesinin yanında yüzdeyi göster |
| Yenileme aralığı | Kullanım verilerinin ne sıklıkla çekileceği (30sn - 5dk) |
| %50'de bildir | %50 kullanımda bildirim gönder |
| %75'te bildir | %75 kullanımda bildirim gönder |
| Limite ulaşıldığında bildir | Limite ulaşıldığında bildirim gönder |
| Sıfırlandığında bildir | Limit sıfırlandığında bildirim gönder |

### Hakkında

Uygulama bilgileri, kreditler ve bağlantılar için ⓘ simgesine tıklayın.

## Nasıl Çalışır

ClaudeBar, Claude Code'un giriş yaptığınızda sakladığı OAuth kimlik bilgilerini macOS Keychain'den okur. Ardından mevcut kullanım limitlerini almak için Anthropic API'sini sorgular.

### Mimari

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Tokenları saklar    │                           │
│   Claude Code   │─────────────────────▶│     macOS Keychain        │
│   (CLI giriş)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Tokenları okur
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘   Kullanım verisi    └───────────────────────────┘
```

## Önemli Notlar

### Anahtarlık Erişimi

İlk başlatmada macOS, ClaudeBar'ın Anahtarlık'a erişmesine izin vermenizi isteyebilir. Sorunsuz çalışma için **Her Zaman İzin Ver**'e tıklayın.

### Gizlilik

- Yalnızca Keychain'deki mevcut kimlik bilgilerini okur
- Tüm iletişim HTTPS kullanır
- Sistem Keychain'i dışında veri depolanmaz
- Analitik veya telemetri yok
- Tamamen açık kaynak

## Katkı

Katkılarınız memnuniyetle karşılanır! Pull Request göndermekten çekinmeyin.

1. Repoyu fork'layın
2. Feature branch'inizi oluşturun (`git checkout -b feature/harika-ozellik`)
3. Değişikliklerinizi commit'leyin (`git commit -m 'Harika özellik ekle'`)
4. Branch'e push yapın (`git push origin feature/harika-ozellik`)
5. Pull Request açın

## Lisans

Bu proje MIT Lisansı altında lisanslanmıştır - detaylar için [LICENSE](../LICENSE) dosyasına bakın.

## Yazar

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## Sorumluluk Reddi

Bu resmi olmayan bir topluluk projesidir ve Anthropic ile bağlantılı değildir, Anthropic tarafından resmi olarak bakılmaz veya desteklenmez. Kendi takdirinize bağlı olarak kullanın.
