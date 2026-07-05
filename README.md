# 📱 العيادة الذكية — Flutter App

تطبيق Flutter كامل لإدارة المواعيد الطبية يعمل على Android وWeb.

---

## 🛠 Tech Stack

| الطبقة | التقنية |
|--------|---------|
| Framework | Flutter 3.x (Dart 3.3+) |
| State Management | flutter_bloc 8.x |
| Navigation | go_router 14.x |
| Networking | dio 5.x + pretty_dio_logger |
| Token Storage | flutter_secure_storage 9.x |
| UI Fonts | google_fonts (Cairo) |
| Date Formatting | intl + table_calendar |

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                          ← نقطة الدخول + DI
├── app_router.dart                    ← GoRouter + Guards
├── core/
│   ├── constants/app_constants.dart   ← Base URL, Storage Keys
│   ├── network/api_client.dart        ← Dio + AuthInterceptor + Failure classes
│   ├── storage/secure_storage_service.dart ← JWT storage
│   └── theme/app_theme.dart           ← Colors, Typography, Theme
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/auth_datasource.dart
│   │   │   └── models/auth_models.dart
│   │   └── presentation/
│   │       ├── bloc/auth_bloc.dart    ← Events, States, BLoC
│   │       └── pages/
│   │           ├── splash_page.dart
│   │           ├── login_page.dart
│   │           └── register_page.dart
│   ├── appointments/
│   │   ├── data/
│   │   │   ├── datasources/appointments_datasource.dart
│   │   │   └── models/appointment_model.dart
│   │   └── presentation/
│   │       └── bloc/appointments_bloc.dart
│   ├── patient/
│   │   └── presentation/pages/patient_dashboard_page.dart
│   └── doctor/
│       └── presentation/pages/doctor_dashboard_page.dart
└── shared/widgets/shared_widgets.dart  ← Reusable components
```

---

## ⚙️ الإعداد والتشغيل

### 1. تأكد من تثبيت Flutter
```bash
flutter --version   # يجب أن يكون 3.x أو أحدث
```

### 2. ثبّت الـ dependencies
```bash
cd smart_clinic_app
flutter pub get
```

### 3. تأكد من تشغيل الباكيند
تأكد أن `smart-clinic-backend` يعمل على المنفذ 3000.

### 4. عدّل الـ Base URL حسب بيئتك

افتح `lib/core/constants/app_constants.dart`:

```dart
// للمحاكي (Android Emulator)
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

// للجهاز الحقيقي (استبدل بـ IP جهازك)
static const String baseUrl = 'http://192.168.1.x:3000/api/v1';

// للويب (flutter run -d chrome)
static const String baseUrl = 'http://localhost:3000/api/v1';
```

### 5. شغّل التطبيق

```bash
# للمحاكي أو الجهاز
flutter run

# للويب
flutter run -d chrome

# لبناء APK
flutter build apk --release

# لبناء APK مصغّر (أصغر حجم)
flutter build apk --split-per-abi
```

---

## 🗺 تدفق التطبيق

```
Splash Screen
    ↓ (تحقق من التوكن)
    ├─ لوحة المريض ← يوجد توكن + role=patient
    ├─ لوحة الطبيب ← يوجد توكن + role=doctor
    └─ تسجيل الدخول ← لا يوجد توكن
         └─ إنشاء حساب (اختياري)
```

---

## 🔐 نظام المصادقة

- **JWT** يُحفظ في `flutter_secure_storage` (مشفّر على Android بـ EncryptedSharedPreferences)
- **AuthInterceptor** يُضيف `Authorization: Bearer <token>` تلقائياً لكل request
- **GoRouter redirect** يحمي المسارات حسب حالة AuthBloc
- عند الخروج يُحذف التوكن وبيانات المستخدم كاملاً

---

## 📱 الشاشات

| الشاشة | الوصف | الدور |
|--------|-------|-------|
| Splash | شاشة تحميل مع التحقق التلقائي | الجميع |
| Login | تسجيل الدخول | الجميع |
| Register | تسجيل حساب جديد (طبيب/مريض) | الجميع |
| Patient Dashboard | الرئيسية + الأطباء + مواعيدي + الملف | مريض |
| Doctor Dashboard | لوحة التحكم + المواعيد + الملف | طبيب |

### لوحة المريض
- ✅ رؤية المواعيد القادمة والسابقة
- ✅ تصفح قائمة الأطباء مع البحث
- ✅ حجز موعد (اختيار تاريخ + وقت)
- ✅ إلغاء موعد
- ✅ رؤية الملاحظات الطبية بعد الكشف

### لوحة الطبيب
- ✅ إحصائيات اليوم (إجمالي، انتظار، مكتملة)
- ✅ قائمة مواعيد اليوم
- ✅ تأكيد/إلغاء المواعيد
- ✅ إتمام الكشف مع إضافة الوصفة
- ✅ فلترة المواعيد حسب الحالة

---

## 🎨 نظام التصميم

```dart
// الألوان الرئيسية
AppColors.primary        // #0B6E7C — تيل طبي
AppColors.accent         // #F5A623 — أمبر للـ CTAs
AppColors.success        // #2ECC71
AppColors.error          // #E74C3C

// الخط
GoogleFonts.cairo()      // خط عربي احترافي

// المكونات المشتركة
StatusBadge(status)      // شارة حالة الموعد
ClinicHeader(...)        // هيدر بتدرج لوني
ShimmerCard(...)         // Loading skeleton
EmptyState(...)          // حالة البيانات الفارغة
ClinicTextField(...)     // حقل إدخال موحّد
StatCard(...)            // بطاقة إحصائية
```

---

## 🚀 بناء الـ APK للرفع على Moodle

```bash
# APK واحد للكل
flutter build apk --release

# أو APKs منفصلة لكل معمارية (أصغر حجم وأفضل)
flutter build apk --split-per-abi
```

ستجد الملفات في:
```
build/app/outputs/flutter-apk/
├── app-release.apk            (APK واحد للكل)
# أو
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk  ← هذا للأجهزة الحديثة
└── app-x86_64-release.apk
```

---

## ⚠️ ملاحظات مهمة

1. **CORS**: تأكد أن الباكيند يقبل الطلبات من `http://localhost` للويب
2. **cleartext**: `android:usesCleartextTraffic="true"` مضاف للتطوير المحلي، أزله في production
3. **minSdk**: 21 (Android 5.0+) — يغطي أكثر من 98% من الأجهزة
