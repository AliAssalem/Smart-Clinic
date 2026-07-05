# 📱 Smart Clinic — Flutter App

A complete cross-platform **Flutter** application for managing medical appointments, optimized for **Android** and **Web**.

---

# 🛠 Tech Stack

| Layer                | Technology                  |
| -------------------- | --------------------------- |
| **Framework**        | Flutter 3.x (Dart 3.3+)     |
| **State Management** | flutter_bloc 8.x            |
| **Navigation**       | go_router 14.x              |
| **Networking**       | dio 5.x + pretty_dio_logger |
| **Secure Storage**   | flutter_secure_storage 9.x  |
| **Fonts**            | google_fonts (Cairo)        |
| **Date & Calendar**  | intl + table_calendar       |

---

# 📁 Project Structure

```text
lib/
├── main.dart                          # Entry Point + Dependency Injection
├── app_router.dart                    # GoRouter Configuration + Route Guards
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Base URL & Storage Keys
│   │
│   ├── network/
│   │   └── api_client.dart            # Dio Setup + AuthInterceptor
│   │
│   ├── storage/
│   │   └── secure_storage_service.dart
│   │
│   └── theme/
│       └── app_theme.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_datasource.dart
│   │   │   └── models/
│   │   │       └── auth_models.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── auth_bloc.dart
│   │       │
│   │       └── pages/
│   │           ├── splash_page.dart
│   │           ├── login_page.dart
│   │           └── register_page.dart
│   │
│   ├── appointments/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── appointments_datasource.dart
│   │   │   └── models/
│   │   │       └── appointment_model.dart
│   │   │
│   │   └── presentation/
│   │       └── bloc/
│   │           └── appointments_bloc.dart
│   │
│   ├── patient/
│   │   └── presentation/
│   │       └── pages/
│   │           └── patient_dashboard_page.dart
│   │
│   └── doctor/
│       └── presentation/
│           └── pages/
│               └── doctor_dashboard_page.dart
│
└── shared/
    └── widgets/
        └── shared_widgets.dart
```

---

# ⚙️ Setup & Run

## 1️⃣ Verify Flutter Installation

```bash
flutter --version
```

> Flutter **3.x** or newer is required.

---

## 2️⃣ Install Dependencies

```bash
cd smart_clinic_app
flutter pub get
```

---

## 3️⃣ Start the Backend

Make sure the **smart-clinic-backend** service is running on:

```text
http://localhost:3000
```

---

## 4️⃣ Configure API Base URL

Open:

```text
lib/core/constants/app_constants.dart
```

Update the base URL according to your environment.

### Android Emulator

```dart
static const String baseUrl =
    'http://10.0.2.2:3000/api/v1';
```

### Physical Android Device

```dart
static const String baseUrl =
    'http://192.168.1.x:3000/api/v1';
```

### Flutter Web

```dart
static const String baseUrl =
    'http://localhost:3000/api/v1';
```

---

## 5️⃣ Run the App

### Android

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### Build Release APK

```bash
flutter build apk --release
```

### Build Split APKs

```bash
flutter build apk --split-per-abi
```

---

# 🗺 Application Flow

```text
Splash Screen
        │
        ▼
Token Verification
        │
 ┌──────┼─────────────┐
 │      │             │
 ▼      ▼             ▼
Patient Doctor      Login
Dashboard Dashboard  Page
                      │
                      ▼
                  Register
```

---

# 🔐 Authentication & Security

* ✅ JWT tokens are securely stored using **flutter_secure_storage**.
* ✅ Android uses **EncryptedSharedPreferences**.
* ✅ `AuthInterceptor` automatically attaches:

```http
Authorization: Bearer <token>
```

to every request.

* ✅ `GoRouter` guards all protected routes.
* ✅ Logout clears secure storage and resets authentication state.

---

# 📱 Screens

| Screen            | Description                     | Role    |
| ----------------- | ------------------------------- | ------- |
| Splash            | Authentication check            | All     |
| Login             | User sign in                    | All     |
| Register          | Create Patient/Doctor account   | All     |
| Patient Dashboard | Home, Booking, Doctors, Profile | Patient |
| Doctor Dashboard  | Analytics, Queue, Profile       | Doctor  |

---

# 👨‍⚕️ Patient Features

* ✅ View upcoming appointments
* ✅ View appointment history
* ✅ Search doctors
* ✅ Book appointments
* ✅ Cancel appointments
* ✅ View prescriptions
* ✅ View medical notes

---

# 🩺 Doctor Features

* ✅ Dashboard analytics
* ✅ Today's appointments
* ✅ Accept appointments
* ✅ Reject appointments
* ✅ Complete examinations
* ✅ Write prescriptions
* ✅ Clinical reports
* ✅ Filter appointments by status

---

# 🎨 Design System

## Colors

```dart
AppColors.primary   // #0B6E7C
AppColors.accent    // #F5A623
AppColors.success   // #2ECC71
AppColors.error     // #E74C3C
```

---

## Typography

```dart
GoogleFonts.cairo()
```

---

## Shared Widgets

```dart
StatusBadge(status)

ClinicHeader(...)

ShimmerCard(...)

EmptyState(...)

ClinicTextField(...)

StatCard(...)
```

---

# 🚀 Production Build

Universal APK

```bash
flutter build apk --release
```

Split APKs

```bash
flutter build apk --split-per-abi
```

Generated files:

```text
build/app/outputs/flutter-apk/

├── app-release.apk
├── app-armeabi-v7a-release.apk
├── app-arm64-v8a-release.apk
└── app-x86_64-release.apk
```

---

# ⚠️ Important Notes

### CORS

Allow requests from:

```text
http://localhost
```

when testing the Web application.

---

### Cleartext Traffic

For local development:

```xml
android:usesCleartextTraffic="true"
```

Remove this setting before production deployment.

---

### Minimum Android SDK

```text
minSdkVersion = 21
```

Supports Android **5.0+** devices.

---

# ✅ Summary

Smart Clinic is a modern Flutter application that provides:

* Secure JWT authentication
* Patient & Doctor dashboards
* Appointment management
* Role-based navigation
* Clean Architecture
* BLoC state management
* GoRouter navigation
* Responsive Android & Web support
* Production-ready project structure
