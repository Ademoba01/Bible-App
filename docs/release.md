# Release checklist

This app is **build-ready** for iOS and Android — every code/config step
is done. What remains is the store-side paperwork (developer accounts,
signing, listings) that must be done by you as the human owner.

---

## What's already done

- **Bundle IDs set**
  - iOS: `com.ademoba.bibleApp`
  - Android: `com.ademoba.bible_app`
- **Display name**: "Bible" on both platforms
- **App icons** generated for all iOS sizes + all Android density buckets
  + adaptive icon (foreground/background)
- **Native splash** configured for both platforms + Android 12+
- **Deployment targets**: iOS 13.0+ / Android minSdk from Flutter defaults
- **Plugins**: `flutter_tts` installed via CocoaPods (iOS) / gradle (Android)
- **Verified builds**: `flutter build web`, `flutter build apk --debug`,
  `flutter build ios --no-codesign`
- **Version**: `1.0.0+1` in `pubspec.yaml` — bump before every release

## Regenerating brand assets

If you change the logo, edit `tools/make_brand_assets.dart` (or replace
the PNGs it writes with your own art of the same filenames):

```
dart run tools/make_brand_assets.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## iOS — TestFlight / App Store

### Prereqs (human-only, can't automate)
1. **Apple Developer Program** membership ($99/year) —
   https://developer.apple.com/programs/
2. **App Store Connect** app record:
   - Create a new app, bundle ID `com.ademoba.bibleApp`
   - Name: "Bible" (check availability — may need a distinctive suffix
     like "Bible — listen & read" since "Bible" alone is heavily taken)
   - Primary category: Reference. Secondary: Education.
3. **Signing**: open `ios/Runner.xcworkspace` in Xcode, sign in with your
   Apple ID, select your team in Signing & Capabilities. Xcode will
   auto-provision.

### Build & upload
```
flutter build ipa --release
open build/ios/archive/Runner.xcarchive
```
Use Xcode Organizer → Distribute App → App Store Connect → Upload.

### Review notes (be ready for these)
- **Content rights**: declare WEB/BSB are public domain in the review
  notes. Apple reviewers routinely ask about scripture apps.
- **Age rating**: infrequent/mild religious themes → 4+.
- **Privacy labels**: the current build collects **no user data**.
  Declare "Data Not Collected" in App Store Connect.
- **TTS disclosure**: `flutter_tts` uses on-device AVSpeechSynthesizer.
  Does not require mic or speech recognition permissions → no
  `Info.plist` usage strings needed (already verified).

---

## Android — Play Store

### Prereqs
1. **Google Play Console** account ($25 one-time) —
   https://play.google.com/console/
2. Create app: package `com.ademoba.bible_app`, name "Bible".
3. **Signing**: use Play App Signing (Google manages the upload key).
   Generate an upload keystore:
   ```
   keytool -genkey -v -keystore ~/bible-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
4. Create `android/key.properties` (git-ignored) with:
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/you/bible-upload.jks
   ```
5. Wire it into `android/app/build.gradle.kts` by adding a
   `signingConfigs.create("release")` block and pointing
   `buildTypes { release { signingConfig = signingConfigs.getByName("release") } }`.
   Full Flutter doc: https://docs.flutter.dev/deployment/android

### Build & upload
```
flutter build appbundle --release
```
Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console
→ Internal testing track first, promote from there.

### Review notes
- **Data safety form**: declare no data collection (matches reality).
- **Content rating**: run through the questionnaire — religious app,
  no violence/sex → Everyone.
- **Target audience**: if you submit Kids Mode as a feature, Google will
  ask if the app targets children. Answer honestly: "Not primarily for
  children" since the main audience is general readers with a kids
  section. If you do target children primarily, Designed For Families
  has extra requirements (no third-party ads, stricter privacy).

---

## Pre-submission smoke test

Before either upload, manually verify on a device:
- [ ] Welcome screen renders with both mode buttons
- [ ] "Start reading" → home → Read tab shows Genesis/John verses
- [ ] Chapter prev/next works
- [ ] Bookmark toggle persists across restart
- [ ] Listen tab plays the current chapter via TTS
- [ ] Search finds verses across all 66 books
- [ ] Settings → Dark mode toggles immediately
- [ ] Settings → Font size changes reader text live
- [ ] Settings → Translation shows WEB (and any enabled extras)
- [ ] Kids mode switches to the playful theme
- [ ] A kids story opens, reads via TTS, and returns cleanly
- [ ] Kill & relaunch: returns to last-used mode (not welcome again)

---

## Things *not* ready yet (by design, not bugs)

- **BSB translation data** — scaffolded; run
  `dart run tools/fetch_bsb.dart` then flip `available: true` in
  `lib/data/translations.dart`
- **Pidgin / Yoruba translation data** — see `docs/translations.md` for
  sourcing paths (Bible Society of Nigeria license recommended)
- **Release signing for Android** — debug-signed currently; follow the
  Android section above
- **iOS code signing** — requires your Apple Developer team
- **App Store / Play Store listings** — screenshots, descriptions,
  keywords. Take screenshots from the running app once you have final
  translations.
