# CareDrop (caredrop)

> 🎓 **University Project**: This mobile application is developed as part of a university project.

**CareDrop** is a Sri Lankan healthcare errand and helper platform designed to connect patients and guardians with local helpers.

---

## Prerequisites (What to Install First)

Before setting up CareDrop on your machine, ensure you have installed the following required tools based on your operating system.

### Core Prerequisites (All Platforms)
1. **Git**: Required for cloning the repository and version control.
   - Download from [git-scm.com](https://git-scm.com/)
2. **Flutter SDK (3.x or higher)** & **Dart SDK**:
   - Download from [flutter.dev](https://docs.flutter.dev/get-started/install)
3. **IDE / Editor**:
   - **VS Code** (with Flutter & Dart extensions installed) OR **Android Studio**
4. **Android Setup (For Mobile Development / Emulators)**:
   - Install **Android Studio** and Android SDK Command-line Tools via SDK Manager.

---

## OS-Specific Requirements

### Linux (Ubuntu / Debian-based)
Install the required system dependencies for Flutter Linux desktop & build tools:
```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++6
```

### Windows
1. Install **Visual Studio 2022** (Community Edition is fine) with the **"Desktop development with C++"** workload selected if you intend to run or build Windows Desktop apps.
2. Ensure environment variables for Flutter are configured (e.g. `C:\src\flutter\bin` added to User/System `PATH`).

---

## Setup & How to Start Working

### 1. Clone the Repository
Open your terminal (Linux) or PowerShell/Git Bash (Windows) and clone the repository:

```bash
git clone https://github.com/Dewnan/CareDrop.git
cd caredrop
```

### 2. Verify Your Environment
Run `flutter doctor` to confirm that Flutter SDK and Android/IDE toolchains are correctly configured:

```bash
flutter doctor
```
*Resolve any missing checkmarks reported by `flutter doctor`.*

### 3. Fetch Project Dependencies
Get all required Dart packages specified in `pubspec.yaml`:

```bash
flutter pub get
```

### 4. Run the Application

#### Run on Connected Android Device / Emulator:
```bash
flutter run
```

#### Run on Specific Target (e.g., Linux Desktop / Chrome / Device ID):
```bash
# Check connected devices:
flutter devices

# Launch on target device:
flutter run -d <DEVICE_ID>
```

---

## Project Structure Overview

```text
caredrop/
├── lib/
│   ├── main.dart               # App entry point
│   ├── models/                 # Data models (TaskModel, HelperModel, EarningsItem, ReviewItem)
│   ├── providers/              # Provider state management (CareDropAppState)
│   ├── screens/                # UI Screens
│   │   ├── common/             # LandingScreen, SplashRoleScreen
│   │   └── helper/             # Helper SignIn, Register, Dashboard, Task Browse, Earnings, Profile, etc.
│   └── theme/                  # Brand colors, typography & light/dark theme tokens (app_theme.dart)
├── pubspec.yaml                # Dependencies & asset declarations
└── README.md
```
