# Team Setup Guide — Campus Lost & Found

For team members joining the project. The Firebase project, security rules, and Cloud Functions are already deployed — you do not need to set any of that up.

**Estimated time:** 20–40 minutes.

---

## Step 1 — Install the Tools

### Flutter SDK

Download and install from https://docs.flutter.dev/get-started/install

- Pick **Windows** → **Android**
- Follow the instructions to add Flutter to your PATH
- Verify:

```bash
flutter --version
```

You need Flutter **3.0+**.

### JDK 17

Required for Android builds. Download **Temurin JDK 17** from https://adoptium.net/temurin/releases/?version=17

After installing, verify:

```bash
java -version
```

Must show `17.x`. If it shows something else, update your `JAVA_HOME` environment variable to point at the JDK 17 installation.

### Git

```bash
git --version
```

If missing, install from https://git-scm.com and configure:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Google Chrome

Required for Web builds. Install from https://www.google.com/chrome/ if you don't have it.

### Verify everything

```bash
flutter doctor
```

You want green checks on **Flutter**, **Android toolchain**, and **Chrome**. Fix any red X before continuing.

---

## Step 2 — Set Up VS Code

1. Download and install VS Code from https://code.visualstudio.com
2. Open VS Code
3. When prompted to install recommended extensions, click **Install All**
   - If not prompted: open Extensions (Ctrl+Shift+X), search each ID below and install:

| Extension | ID |
|---|---|
| Dart | `Dart-Code.dart-code` |
| Flutter | `Dart-Code.flutter` |
| Flutter Riverpod Snippets | `robert-brunhage.flutter-riverpod-snippets` |
| Error Lens | `usernamehw.errorlens` |
| GitLens | `eamodio.gitlens` |
| GitHub Pull Requests | `GitHub.vscode-pull-request-github` |

---

## Step 3 — Clone the Repository

```bash
git clone https://github.com/SittaWetpa/Campus-Lost-Found-Digital-Bulletin-Board.git campus_lost_found
cd campus_lost_found
git checkout develop
git pull origin develop
```

---

## Step 4 — Install Flutter Packages

```bash
flutter pub get
```

This downloads all dependencies. Should complete with no errors.

---

## Step 5 — Verify the App Runs

**Android** (start an emulator first from Android Studio, or run from terminal):

```bash
flutter emulators --launch <emulator-name>
```

Check available emulators with `flutter emulators`, then wait ~60 seconds for it to boot before running:

```bash
flutter run
```

**Web:**

```bash
flutter run -d chrome
```

Both should show a screen with "Firebase connected ✓". If you see that, everything is wired up correctly.

---

## Step 6 — Start Feature Work

Always branch off `develop`:

```bash
git checkout develop
git pull
git checkout -b <yournickname>/feat/<feature-name>
```

Example: `film/feat/login-screen`

Read `CLAUDE.md` at the project root — it explains the architecture rules, naming conventions, and what not to do. Claude Code (the VS Code extension) reads it automatically every session.

---

## Troubleshooting

**`flutter doctor` shows Android toolchain errors**
Open Android Studio → Tools → SDK Manager → install the latest Platform-Tools and Build-Tools. Accept licenses:
```bash
flutter doctor --android-licenses
```

**`flutter pub get` fails with analyzer version conflict**
The project pins `riverpod_generator: ^2.4.0` specifically to avoid a conflict with `hive_generator`. Do not upgrade it independently.

**`flutter run` shows a red error screen mentioning Firebase**
Make sure you cloned the full repo including `lib/config/firebase_options.dart` and `android/app/google-services.json`. Run `git status` — if those files are missing, run `git pull`.

**Android build fails with JDK version error**
Confirm `java -version` shows 17. If Android Studio's bundled JDK is taking over, set `JAVA_HOME` explicitly to your JDK 17 path.

**Android emulator crashes on startup / exits with code 1**
Enable virtualization in BIOS, then run in PowerShell (Admin):
```powershell
bcdedit /set hypervisorlaunchtype auto
```
Restart your machine and try again.