# ClaudeBar

<p align="center">
  <img src="../assets/icons/claudebar-macOS-Dark-1024x1024@1x.png" alt="أيقونة ClaudeBar" width="128" height="128">
</p>

<p align="center">
  <strong>تطبيق شريط قوائم macOS أصلي لمراقبة حدود استخدام Claude في الوقت الفعلي.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="الرخصة">
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

> **ملاحظة:** تم إنشاء هذه الترجمة بواسطة الذكاء الاصطناعي وقد تحتوي على أخطاء أو عدم دقة. يرجى إرسال Pull Request للتصحيحات.

---

## الميزات

- **مراقبة الاستخدام في الوقت الفعلي** - عرض حدود الجلسة الحالية والأسبوعية بنظرة واحدة
- **شارة الخطة** - يعرض اشتراكك الحالي (Pro، Max، Team)
- **دعم الاستخدام الإضافي** - تتبع رصيد الدفع حسب الاستخدام عند تفعيله
- **أشرطة تقدم ملونة** - أخضر، أصفر، برتقالي، أحمر حسب نسبة الاستخدام
- **دعم متعدد اللغات** - الإنجليزية، التركية، الصينية، الإسبانية، الروسية مع محدد اللغة داخل التطبيق
- **إشعارات قابلة للتخصيص** - احصل على إشعار عند 50%، 75%، 100% أو عند إعادة التعيين
- **تحديث تلقائي** - فاصل تحديث قابل للتكوين (30 ثانية، 1 دقيقة، 2 دقيقة، 5 دقائق)
- **التشغيل عند تسجيل الدخول** - البدء اختيارياً مع جهاز Mac الخاص بك
- **النسبة المئوية في شريط القوائم** - إظهار/إخفاء النسبة المئوية بجانب الأيقونة
- **تجربة أصلية** - مبني بـ SwiftUI، يتبع إرشادات تصميم macOS
- **خفيف الوزن** - استهلاك موارد ضئيل، بدون Electron
- **يركز على الخصوصية** - لا تحليلات، لا قياس عن بعد

## لقطات الشاشة

<p align="center">
  <img src="../screenshots/app-screenshot.png" alt="عرض ClaudeBar العام" width="380">
</p>

<p align="center">
  <em>مراقبة الاستخدام في الوقت الفعلي مع شارة الخطة</em>
</p>

<details>
<summary><strong>المزيد من لقطات الشاشة</strong></summary>

<br>

| الإعدادات | الإشعارات | حول |
|:---------:|:---------:|:---:|
| <img src="../screenshots/settings-screenshot.png" alt="الإعدادات" width="250"> | <img src="../screenshots/notifications-screenshot.png" alt="الإشعارات" width="250"> | <img src="../screenshots/about-screenshot.png" alt="حول" width="250"> |

</details>

## المتطلبات

- macOS 14.0 (Sonoma) أو أحدث
- [Claude Code](https://claude.ai/code) مثبت ومسجل الدخول
- اشتراك نشط في Claude Pro أو Max أو Team

## التثبيت

### Homebrew (موصى به)

```bash
brew install --cask kemalasliyuksek/claudebar/claudebar-monitor
```

يتعامل تلقائيًا مع أمان macOS Gatekeeper — لا حاجة لخطوات إضافية.

### تحميل الملف الثنائي المُجمَّع مسبقاً

قم بتحميل أحدث ملف `.app` من صفحة [Releases](https://github.com/kemalasliyuksek/claudebar/releases)، ثم اسحبه إلى مجلد التطبيقات.

> **ملاحظة:** إذا أظهر macOS رسالة "ClaudeBar is damaged and can't be opened"، قم بتشغيل الأمر التالي لإزالة علامة الحجر:
> ```bash
> xattr -cr ClaudeBar.app
> ```

### البناء من المصدر

```bash
git clone https://github.com/kemalasliyuksek/claudebar.git
cd claudebar
./build.sh
```

سيتم إنشاء حزمة التطبيق في `.build/release/ClaudeBar.app`.

للتثبيت:
```bash
cp -r .build/release/ClaudeBar.app /Applications/
```

## الاستخدام

1. تأكد من تسجيل الدخول إلى Claude Code (يجب أن يعمل أمر `claude` في الطرفية)
2. قم بتشغيل ClaudeBar من التطبيقات أو Spotlight
3. انقر على أيقونة المقياس في شريط القوائم لعرض حدود الاستخدام

### الإعدادات

انقر على أيقونة ⚙️ للتكوين:

| الإعداد | الوصف |
|---------|-------|
| التشغيل عند تسجيل الدخول | البدء تلقائياً عند تسجيل الدخول |
| إظهار % في شريط القوائم | عرض النسبة المئوية بجانب أيقونة شريط القوائم |
| اللغة | اختر لغة التطبيق (النظام، English، Türkçe، 中文، Español، Русский) |
| فاصل التحديث | مدى تكرار جلب بيانات الاستخدام (30 ثانية - 5 دقائق) |
| الإشعار عند 50% | إرسال إشعار عند 50% استخدام |
| الإشعار عند 75% | إرسال إشعار عند 75% استخدام |
| الإشعار عند بلوغ الحد | إرسال إشعار عند بلوغ الحد |
| الإشعار عند إعادة التعيين | إرسال إشعار عند إعادة تعيين الحد |

### حول

انقر على أيقونة ⓘ لعرض معلومات التطبيق والاعتمادات والروابط.

## كيف يعمل

يقرأ ClaudeBar بيانات اعتماد OAuth من سلسلة مفاتيح macOS التي يخزنها Claude Code عند تسجيل الدخول. ثم يستعلم من API الخاص بـ Anthropic للحصول على حدود الاستخدام الحالية.

### الهندسة المعمارية

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

## ملاحظات مهمة

### الوصول إلى سلسلة المفاتيح

عند التشغيل الأول، قد يطلب منك macOS السماح لـ ClaudeBar بالوصول إلى سلسلة المفاتيح. انقر على **السماح دائماً** لعمل سلس.

### الخصوصية

- يقرأ فقط بيانات الاعتماد الموجودة من سلسلة المفاتيح
- جميع الاتصالات تستخدم HTTPS
- لا يتم تخزين بيانات خارج سلسلة مفاتيح النظام
- لا تحليلات أو قياس عن بعد
- مفتوح المصدر بالكامل

## المساهمة

المساهمات مرحب بها! لا تتردد في إرسال Pull Request.

1. قم بعمل Fork للمستودع
2. أنشئ فرع الميزة الخاص بك (`git checkout -b feature/amazing-feature`)
3. قم بعمل Commit لتغييراتك (`git commit -m 'Add amazing feature'`)
4. ادفع إلى الفرع (`git push origin feature/amazing-feature`)
5. افتح Pull Request

## الرخصة

هذا المشروع مرخص بموجب رخصة MIT - راجع ملف [LICENSE](../LICENSE) للتفاصيل.

## المؤلف

**Kemal Aslıyüksek** - [@kemalasliyuksek](https://github.com/kemalasliyuksek)

## إخلاء المسؤولية

هذا مشروع مجتمعي غير رسمي وليس تابعاً لـ Anthropic أو مُداراً أو معتمداً رسمياً من قبلها. استخدمه وفقاً لتقديرك الخاص.
