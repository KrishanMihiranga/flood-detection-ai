# Google Maps & location (demo / local dev)

## Why the map looks white (Android)

If you only see **empty white/grey paint** plus the **small Google logo** at the corner, **`google_maps_flutter` is rendering but tiles are blocked**. Almost always:

1. No valid **Maps SDK for Android** API key merged into the app, or  
2. **Billing** is not enabled for the GCP project, or **Maps SDK for Android** API is disabled, or  
3. The key has **restriction** mismatches (e.g. SHA-1/package not allowed for debug builds).

## Android

Configure the key outside version control (`android/local.properties` is gitignored):

1. In [Google Cloud Console](https://console.cloud.google.com/): enable **Maps SDK for Android**, link billing, create an API key.  
2. Add to **`android/local.properties`** (same folder level as **`android/app`**):

```properties
GOOGLE_MAPS_ANDROID_KEY=PASTE_YOUR_KEY_HERE
```

3. Optionally use env var **`GOOGLE_MAPS_ANDROID_KEY`** instead (CI / scripts).

The key is wired through **`manifestPlaceholders`** in **`android/app/build.gradle.kts`** into **`AndroidManifest.xml`** as **`${GOOGLE_MAPS_ANDROID_KEY}`**.

4. **Stop and fully restart** the app (`flutter run` from cold). Hot reload won’t reload native manifest placeholders.

Debug builds signed with debug keystore: if the API key uses **Android app restrictions**, register your **SHA-1** for package **`com.example.myapp`** in Google Cloud (or use “Don’t restrict key” briefly while prototyping).

## iOS

1. Create an API key with **Maps SDK for iOS** enabled (same or separate key).
2. Edit `ios/Runner/Info.plist` → replace `YOUR_IOS_MAPS_KEY` value for **`GMSApiKey`**.
3. `AppDelegate.swift` calls `GMSServices.provideAPIKey` using that key at launch.

Install CocoaPods deps if Xcode tells you to: from `ios/`, run `pod install`.

## Location / camera / gallery

Privacy strings live in **`ios/Runner/Info.plist`**. Adjust copy as needed before App Store submission.

Android permissions are declared in **`AndroidManifest.xml`** (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`, `READ_MEDIA_IMAGES`). No backend is used; GPS and photos stay on device for this prototype.

### Windows: debug APK / Gradle “different roots” Kotlin error

If `flutter build apk` fails with **`this and base files have different roots`** (Pub cache under **`C:`** vs project under **`E:`** etc.), the repo ships **`kotlin.incremental=false`** in **`android/gradle.properties`** to avoid Kotlin incremental compilation bugs across Windows drive roots.

If it still fails, run **`flutter clean`**, delete the project **`build/`** directory, then rebuild.

For a lasting fix, keep **the Pub cache** and **this Flutter project on the same drive letter**.