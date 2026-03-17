# ضع أيقونة التطبيق هنا

## المطلوب:
- صورة واحدة بحجم **1024x1024 بكسل**
- صيغة **PNG**
- **بدون شفافية** (بدون خلفية شفافة)
- **بدون زوايا مستديرة** (iOS يضيفها تلقائياً)

## الخطوات:
1. سمّ الصورة `icon.png`
2. ضعها في هذا المجلد
3. ثم انسخها إلى: `AiteApp/Assets.xcassets/AppIcon.appiconset/icon.png`
4. وعدّل ملف `AiteApp/Assets.xcassets/AppIcon.appiconset/Contents.json` ليصبح:

```json
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
```

أو ببساطة: افتح المشروع في Xcode واسحب الأيقونة إلى AppIcon في Assets.xcassets
