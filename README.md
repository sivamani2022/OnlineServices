# SIT e-Services Directory — Native Mobile App (Flutter)

A native Android/iOS app for the department-wise online services dashboard, backed by
Google Sheets + Google Apps Script (free, no server to rent or maintain).

**What's included:**
- `backend/Code.gs` + `backend/index.html` — the Apps Script backend, exposing both a JSON
  REST API (for this app) and the old browser page (handy for quick testing/admin use)
- Everything under `lib/` — the Flutter app source code

---

## Part 1 — Deploy the backend (Google Sheets + Apps Script)

1. Create a new Google Sheet (e.g. "SIT e-Services Directory").
2. **Extensions → Apps Script**. Replace the default `Code.gs` with `backend/Code.gs` from
   this package.
3. Add an HTML file named exactly `index` (Apps Script adds `.html`) and paste in
   `backend/index.html`.
4. Save. Run `setupSheets` once from the function dropdown (▶), authorizing when prompted.
   This creates the `Departments` and `Services` sheet tabs.
5. Add your departments — edit and run `addDepartmentHelper()` (or call `addDepartment(...)`
   directly) once per department, e.g.:
   ```js
   function addDepartmentHelper() {
     addDepartment('Revenue Department', 'revenue_admin', 'ChangeThisPassword123', '🏛️');
   }
   ```
   Note down each username/password you set — passwords are stored as one-way hashes, so
   they can't be read back later.
6. **Deploy → New deployment → Web app**:
   - Execute as: **Me**
   - Who has access: **Anyone**
7. Click Deploy, authorize again if asked, and **copy the Web app URL** — you'll need it in
   Part 2. It looks like:
   `https://script.google.com/macros/s/AKfycb.../exec`

Any time you change `Code.gs`, go to **Deploy → Manage deployments → edit → New version →
Deploy** to push the update live.

## Part 2 — Point the Flutter app at your backend

Open `lib/services/api_service.dart` and replace the placeholder with your Web app URL:

```dart
const String kApiBaseUrl =
    'https://script.google.com/macros/s/AKfycb.../exec';
```

## Part 3 — Build the app

Two ways to get an actual `.apk` file — pick whichever is easier for you.

### Option A — Build in the cloud with GitHub Actions (no install needed)

This package includes `.github/workflows/build_apk.yml`, which builds the APK for you on
GitHub's servers.

1. Create a new (private is fine) repository on [github.com](https://github.com) and push
   this whole folder to it (or use GitHub's "Add file → Upload files" in the browser if you
   don't use git from the command line).
2. On the repo page, go to the **Actions** tab. GitHub will detect the workflow — click
   **"I understand my workflows, go ahead and enable them"** if prompted.
3. Click **Build APK** in the left sidebar → **Run workflow** → **Run workflow** (green
   button). It takes a few minutes.
4. Once it finishes (green checkmark), click into that run → scroll to **Artifacts** →
   download **app-release-apk**. Unzip it — that's your `app-release.apk`, ready to copy to
   a phone and install.

Every time you push a change (e.g. after updating `kApiBaseUrl`), it rebuilds automatically.

### Option B — Build locally with the Flutter SDK

You'll need the free [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
on your own computer (Windows, Mac, or Linux).

1. Install Flutter and run `flutter doctor` to confirm your setup (Android Studio + Android
   SDK is enough for an Android build; Xcode is additionally needed for iOS, Mac only).
2. Open a terminal in this project folder and run:
   ```
   flutter create . --platforms=android --org com.sit.puducherry
   flutter pub get
   ```
   (The first command generates the `android/` folder this package doesn't include — it
   won't touch your existing `lib/` or `pubspec.yaml`.)
3. To test on a connected phone or emulator:
   ```
   flutter run
   ```
4. To build the installable Android APK:
   ```
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`. Copy that file to
   your phone (via USB, email, Drive, etc.) and open it to install — you may need to allow
   "Install from unknown sources" the first time, since it isn't from the Play Store.
5. For the Play Store instead of a sideloaded APK, build an App Bundle:
   ```
   flutter build appbundle --release
   ```
   and upload the resulting `.aab` through the [Google Play Console](https://play.google.com/console)
   (requires a one-time $25 developer account).
6. For iOS, `flutter build ios` and distribute via TestFlight or the App Store — this step
   requires a Mac with Xcode and an Apple Developer account ($99/year).

## How the app works

- **Home screen**: grid of departments (icon, name, service count), with search.
- **Tap a department**: list of its public services, each with an "Open Service" button that
  launches the URL in the phone's browser.
- **"Dept Login"** (top right): a department signs in with the username/password you set up
  for them, and gets an admin screen scoped to their own department — add, edit, or delete
  their services. The backend re-checks the department ID on every write, so no department
  can alter another's listings. The session persists between app launches until they log out.

## Customizing

- **App name / branding**: colors are set in `lib/main.dart`'s `ThemeData`. For the Android
  app name and launcher icon, edit `android/app/src/main/AndroidManifest.xml` (`android:label`)
  and swap the icon files under `android/app/src/main/res/mipmap-*/`. Flutter's
  [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) package
  automates this if you'd rather not do it by hand.
- **Departments/icons**: managed entirely in the Google Sheet or via `addDepartment(...)`.
- **A central SIT super-admin** (to manage all departments/passwords from within the app,
  rather than the Apps Script editor) is a natural next addition — let me know if you'd like
  that built in.

## Note on the Android project files

This package includes the Dart application code (`lib/`) and `pubspec.yaml` only — not the
generated `android/`/`ios/` platform folders. Both build options above generate those
automatically (`flutter create . --platforms=android`), so you don't need to create them by
hand.
