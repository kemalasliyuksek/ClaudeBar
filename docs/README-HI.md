# ClaudeBar

<p align="center">
  <img src="../assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="ClaudeBar आइकन" width="128" height="128">
</p>

<p align="center">
  <strong>Claude उपयोग सीमाओं की रीयल-टाइम निगरानी के लिए एक नेटिव macOS मेनू बार ऐप।</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="लाइसेंस">
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

> **नोट:** यह अनुवाद AI द्वारा किया गया है और इसमें त्रुटियाँ या अशुद्धियाँ हो सकती हैं। सुधारों के लिए Pull Request सबमिट करें।

---

## विशेषताएँ

- **रीयल-टाइम उपयोग निगरानी** - वर्तमान सत्र और साप्ताहिक उपयोग सीमाएँ एक नज़र में देखें
- **प्लान बैज** - आपकी वर्तमान सदस्यता दिखाता है (Pro, Max, Team)
- **अतिरिक्त उपयोग सहायता** - सक्षम होने पर पे-एज़-यू-गो क्रेडिट ट्रैक करें
- **रंग-कोडित प्रगति बार** - उपयोग प्रतिशत के अनुसार हरा, पीला, नारंगी, लाल
- **बहुभाषी समर्थन** - अंग्रेज़ी, तुर्की, चीनी, स्पेनिश, रूसी और ऐप में भाषा चयन
- **अनुकूलन योग्य सूचनाएँ** - 50%, 75%, 100% या रीसेट पर सूचना प्राप्त करें
- **स्वचालित रिफ्रेश** - कॉन्फ़िगर करने योग्य रिफ्रेश अंतराल (30s, 1m, 2m, 5m)
- **लॉगिन पर लॉन्च** - वैकल्पिक रूप से अपने Mac के साथ शुरू करें
- **मेनू बार प्रतिशत** - मेनू बार आइकन के बगल में प्रतिशत दिखाएँ/छिपाएँ
- **नेटिव अनुभव** - SwiftUI के साथ निर्मित, macOS डिज़ाइन दिशानिर्देशों का पालन करता है
- **हल्का** - न्यूनतम संसाधन उपयोग, कोई Electron नहीं
- **गोपनीयता केंद्रित** - कोई एनालिटिक्स नहीं, कोई टेलीमेट्री नहीं

## स्क्रीनशॉट

<p align="center">
  <img src="../screenshots/app-screenshot.png" alt="ClaudeBar सामान्य दृश्य" width="380">
</p>

<p align="center">
  <em>प्लान बैज के साथ रीयल-टाइम उपयोग निगरानी</em>
</p>

<details>
<summary><strong>और स्क्रीनशॉट</strong></summary>

<br>

| सेटिंग्स | सूचनाएँ | के बारे में |
|:---------:|:--------:|:----------:|
| <img src="../screenshots/settings-screenshot.png" alt="सेटिंग्स" width="250"> | <img src="../screenshots/notifications-screenshot.png" alt="सूचनाएँ" width="250"> | <img src="../screenshots/about-screenshot.png" alt="के बारे में" width="250"> |

</details>

## आवश्यकताएँ

- macOS 14.0 (Sonoma) या बाद का संस्करण
- [Claude Code](https://claude.ai/code) इंस्टॉल और लॉग इन होना चाहिए
- सक्रिय Claude Pro, Max, या Team सदस्यता

## इंस्टॉलेशन

### Homebrew (अनुशंसित)

```bash
brew install --cask kemalasliyuksek/claudebar/claudebar-monitor
```

यह स्वचालित रूप से macOS Gatekeeper सुरक्षा को संभालता है — किसी अतिरिक्त कदम की आवश्यकता नहीं।

### पूर्व-निर्मित बाइनरी डाउनलोड करें

[Releases](https://github.com/kemalasliyuksek/claudebar/releases) पेज से नवीनतम `.app` डाउनलोड करें, फिर इसे अपने Applications फ़ोल्डर में ड्रैग करें।

> **नोट:** यदि macOS "ClaudeBar is damaged and can't be opened" त्रुटि दिखाता है, तो क्वारंटाइन फ़्लैग हटाने के लिए यह कमांड चलाएँ:
> ```bash
> xattr -cr ClaudeBar.app
> ```

### स्रोत से बनाएँ

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

ऐप बंडल `.build/release/ClaudeBar.app` पर बनाया जाएगा।

इंस्टॉल करने के लिए:
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## उपयोग

1. सुनिश्चित करें कि आप Claude Code में लॉग इन हैं (टर्मिनल में `claude` कमांड काम करनी चाहिए)
2. Applications या Spotlight से ClaudeBar लॉन्च करें
3. उपयोग सीमाएँ देखने के लिए मेनू बार में गेज आइकन पर क्लिक करें

### सेटिंग्स

कॉन्फ़िगर करने के लिए ⚙️ आइकन पर क्लिक करें:

| सेटिंग | विवरण |
|--------|--------|
| लॉगिन पर लॉन्च | लॉग इन करने पर स्वचालित रूप से शुरू करें |
| मेनू बार में % दिखाएँ | मेनू बार आइकन के बगल में प्रतिशत प्रदर्शित करें |
| भाषा | ऐप की भाषा चुनें (सिस्टम, English, Türkçe, 中文, Español, Русский) |
| रिफ्रेश अंतराल | उपयोग डेटा कितनी बार प्राप्त करना है (30s - 5m) |
| 50% पर सूचित करें | 50% उपयोग पर सूचना भेजें |
| 75% पर सूचित करें | 75% उपयोग पर सूचना भेजें |
| सीमा पहुँचने पर सूचित करें | सीमा पहुँचने पर सूचना भेजें |
| सीमा रीसेट होने पर सूचित करें | सीमा रीसेट होने पर सूचना भेजें |

### के बारे में

ऐप जानकारी, क्रेडिट और लिंक देखने के लिए ⓘ आइकन पर क्लिक करें।

## यह कैसे काम करता है

ClaudeBar macOS Keychain से OAuth क्रेडेंशियल पढ़ता है जो Claude Code लॉग इन करते समय संग्रहीत करता है। फिर यह आपकी वर्तमान उपयोग सीमाओं के लिए Anthropic API से क्वेरी करता है।

### आर्किटेक्चर

```
┌─────────────────┐                      ┌───────────────────────────┐
│                 │  Stores tokens       │                           │
│   Claude Code   │─────────────────────▶│     macOS Keychain        │
│   (CLI login)   │                      │ "Claude Code-credentials" │
└─────────────────┘                      └───────────────────────────┘
                                                     │
                                                     │ Reads tokens
                                                     ▼
┌─────────────────┐                      ┌───────────────────────────┐
│                 │ GET /api/oauth/usage │                           │
│  Anthropic API  │◀─────────────────────│        ClaudeBar          │
│                 │─────────────────────▶│                           │
└─────────────────┘    Usage data        └───────────────────────────┘
```

## महत्वपूर्ण नोट्स

### Keychain एक्सेस

पहली बार लॉन्च करने पर, macOS आपसे ClaudeBar को Keychain एक्सेस करने की अनुमति देने के लिए कह सकता है। सुचारू संचालन के लिए **Always Allow** पर क्लिक करें।

### गोपनीयता

- केवल Keychain से मौजूदा क्रेडेंशियल पढ़ता है
- सभी संचार HTTPS का उपयोग करते हैं
- सिस्टम Keychain के बाहर कोई डेटा संग्रहीत नहीं
- कोई एनालिटिक्स या टेलीमेट्री नहीं
- पूरी तरह से ओपन सोर्स

## योगदान

योगदान का स्वागत है! कृपया Pull Request सबमिट करने में संकोच न करें।

1. रिपॉजिटरी को Fork करें
2. अपनी फीचर ब्रांच बनाएँ (`git checkout -b feature/amazing-feature`)
3. अपने बदलाव कमिट करें (`git commit -m 'Add amazing feature'`)
4. ब्रांच पर पुश करें (`git push origin feature/amazing-feature`)
5. Pull Request खोलें

## लाइसेंस

यह प्रोजेक्ट MIT लाइसेंस के तहत लाइसेंस प्राप्त है - विवरण के लिए [LICENSE](../LICENSE) फ़ाइल देखें।

## लेखक

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## अस्वीकरण

यह एक अनौपचारिक सामुदायिक प्रोजेक्ट है और Anthropic से संबद्ध नहीं है, आधिकारिक रूप से Anthropic द्वारा रखरखाव या समर्थित नहीं है। अपने विवेक से उपयोग करें।
