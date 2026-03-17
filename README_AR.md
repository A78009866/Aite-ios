# تطبيق Aite - نسخة iOS

---

## الطريقة 1: البناء عبر GitHub Actions (بدون Mac)

### الخطوات:

#### 1. أنشئ ريبو جديد على GitHub
- اذهب إلى [github.com/new](https://github.com/new)
- سمّه مثلاً AiteApp-iOS
- اجعله **Private**

#### 2. ارفع ملفات المشروع
ارفع كل محتويات مجلد AiteApp إلى الريبو (يمكنك السحب والإفلات في صفحة GitHub)

أو عبر الأوامر:
    git init
    git add AiteApp/ AiteApp.xcodeproj/ .github/ README_AR.md ICON_HERE/
    git commit -m "Initial iOS app"
    git branch -M main
    git remote add origin https://github.com/USERNAME/AiteApp-iOS.git
    git push -u origin main

#### 3. شغّل الـ Workflow
- اذهب إلى تبويب **Actions** في الريبو
- اختر **Build iOS App**
- اضغط **Run workflow**
- انتظر حتى ينتهي البناء (حوالي 5-10 دقائق)

#### 4. حمّل ملف IPA
- بعد نجاح البناء، اضغط على الـ workflow run
- ستجد **AiteApp-unsigned-ipa** في قسم **Artifacts**
- حمّله - هذا هو ملف التطبيق!

#### 5. تثبيت IPA على iPhone
الملف الناتج هو **unsigned IPA** (غير موقّع). لتثبيته:
- **الطريقة الأسهل:** استخدم [AltStore](https://altstore.io/) أو [Sideloadly](https://sideloadly.io/) لتثبيته على جهازك
- **للنشر على App Store:** أنظر قسم البناء الموقّع أدناه

---

## الطريقة 2: البناء على Mac بـ Xcode

### المتطلبات
1. **جهاز Mac** يعمل بنظام macOS 13 أو أحدث
2. **Xcode 15** أو أحدث (مجاني من Mac App Store)
3. **حساب Apple Developer** (مجاني للتجربة، 99 دولار/سنة للنشر)

### الخطوات:
1. افتح AiteApp.xcodeproj بالنقر المزدوج عليه
2. في Xcode اضغط على **AiteApp** في القائمة اليسرى
3. اذهب إلى **Signing & Capabilities**
4. فعّل **Automatically manage signing**
5. اختر **Team** الخاص بك
6. غيّر **Bundle Identifier** مثلاً: com.yourname.aite
7. وصّل iPhone أو اختر Simulator ثم اضغط Run

---

## أين أضع أيقونة التطبيق؟

### الملف المطلوب:
- صورة **PNG** بحجم **1024x1024 بكسل**
- **بدون شفافية** (خلفية صلبة)
- **بدون زوايا مستديرة** (iOS يضيفها تلقائياً)

### المكان:
ضع صورة الأيقونة باسم icon.png في هذا المسار:

    AiteApp/Assets.xcassets/AppIcon.appiconset/icon.png

ثم عدّل ملف AiteApp/Assets.xcassets/AppIcon.appiconset/Contents.json ليصبح:

    {
      "images" : [
        {
          "filename" : "icon.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

**أو بالطريقة السهلة في Xcode:**
افتح المشروع > اضغط على Assets.xcassets > اضغط على AppIcon > اسحب الصورة إلى المربع الفارغ

---

## البناء الموقّع (للنشر على App Store / TestFlight)

لبناء نسخة موقّعة عبر GitHub Actions، تحتاج إلى إضافة هذه الـ Secrets في إعدادات الريبو:

### 1. استخراج الشهادة والـ Profile
على جهاز Mac:

    # تحويل شهادة p12 إلى base64
    base64 -i Certificates.p12 | pbcopy

    # تحويل provisioning profile إلى base64
    base64 -i YourApp.mobileprovision | pbcopy

### 2. إضافة Secrets في GitHub
اذهب إلى: Settings > Secrets and variables > Actions وأضف:

- BUILD_CERTIFICATE_BASE64: شهادة التوقيع (.p12) بصيغة base64
- P12_PASSWORD: كلمة مرور ملف .p12
- KEYCHAIN_PASSWORD: أي كلمة مرور (للـ keychain المؤقت)
- PROVISIONING_PROFILE_BASE64: ملف provisioning profile بصيغة base64

### 3. تشغيل البناء الموقّع
- اذهب إلى Actions > Build iOS App
- اضغط Run workflow
- النسخة الموقّعة ستظهر كـ artifact باسم AiteApp-signed-ipa

---

## تغيير رابط التطبيق

إذا كان رابط تطبيقك مختلف عن https://chat-trimer.vercel.app :

افتح ملف AiteApp/ViewController.swift وغيّر:

    private let appURL = URL(string: "https://chat-trimer.vercel.app")!

وأيضاً غيّر:

    !host.contains("chat-trimer.vercel.app")

---

## الميزات المدعومة

- تحميل تطبيق الويب بالكامل داخل WKWebView
- دعم الكاميرا والميكروفون ومكتبة الصور
- رفع الملفات (صور، فيديو، صوت)
- حفظ الجلسات والكوكيز
- شاشة بداية (Splash Screen)
- شريط تقدم التحميل
- السحب للتحديث (Pull to Refresh)
- التنقل بالسحب (Swipe Back)
- دعم Safe Area لجميع أجهزة iPhone
- فتح الروابط الخارجية في Safari
- دعم JavaScript alerts/confirms/prompts
- إشعارات Push (تحتاج إعداد إضافي)
- رسالة عدم اتصال بالإنترنت

## ملاحظات مهمة

- التطبيق يدعم iOS 15.0 وأحدث
- التطبيق يعمل على iPhone فقط
- تأكد من أن تطبيق الويب يعمل على Safari قبل البناء
- للإشعارات، تحتاج إعداد APNs في Apple Developer Portal
