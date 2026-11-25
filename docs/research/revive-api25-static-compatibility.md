# Revive and SSM compatibility with Android 7.1

**Assessment date:** 2026-11-25
**Scope:** Static inspection of the checked-in Revive and SSM service APKs for the Android 7.1 / API 25 donor. No emulator or device tests were run.

## Assessment

The manifests leave an install path open on API 25: both APKs declare `minSdkVersion=17`, `targetSdkVersion=29`, and no `maxSdkVersion`. Android 7.1 is API 25; the Package Manager minimum-version check uses `minSdkVersion`, while `targetSdkVersion` selects compatibility behavior and does not raise the minimum install level. This does **not** establish runtime compatibility. Both DEX files reference framework classes first added after API 25, and the SSM service contains reflective Meraki API lookups whose target implementation is unavailable here.

The static audit is complete for the two APKs in this checkout. It supports a conditional compatibility path for further testing, not a claim that Revive/VoIP works on the donor. Revive/VoIP remains required; Meraki dialer compatibility remains best effort. [Android API levels](https://developer.android.com/reference/android/os/Build.VERSION_CODES#N_MR1), [uses-sdk behavior](https://developer.android.com/guide/topics/manifest/uses-sdk-element).

## Confirmed findings

### Manifests and permissions

| APK | Manifest facts |
| --- | --- |
| [revive.MC74-debug.apk](../../installFiles/revive.MC74-debug.apk) | Package `revive.MC74`; min 17, target 29, compile 29; `debuggable=true`, `testOnly=true`, and no max SDK. Declares `INTERNET`, `RECORD_AUDIO`, `READ_CONTACTS`, `MODIFY_AUDIO_SETTINGS`, `ACCESS_NETWORK_STATE`, `VIBRATE`, `WAKE_LOCK`, `CAMERA` (camera feature is optional), `READ_PHONE_STATE`, `READ/WRITE_EXTERNAL_STORAGE`, `WRITE_CONTACTS`, `BLUETOOTH`, `GET_ACCOUNTS`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `READ/WRITE_SYNC_SETTINGS`, `AUTHENTICATE_ACCOUNTS`, `SYSTEM_ALERT_WINDOW`, `KILL_BACKGROUND_PROCESSES`, `FOREGROUND_SERVICE`, `RECEIVE_BOOT_COMPLETED`, `ACCESS_NOTIFICATION_POLICY`, and `USE_FULL_SCREEN_INTENT`. |
| [revive.SSMService-debug.apk](../../installFiles/revive.SSMService-debug.apk) | Package `ribo.ssm`; min 17, target 29, compile 29; `debuggable=true`, no `testOnly`, and no max SDK. Declares `RECEIVE_BOOT_COMPLETED`, `INTERNET`, `REORDER_TASKS`, `READ/WRITE_EXTERNAL_STORAGE`, `READ_PHONE_STATE`, `GET_TASKS`, `READ_PHONE_DEVICES`, and `FOREGROUND_SERVICE`. |

The Revive manifest marks the camera feature optional. Both manifests request the API 23+ dangerous-permission runtime model on API 25 because their target is above 22; the DEX files contain permission-check/request API references, including `checkSelfPermission` and `requestPermissions`. That is evidence of a request path, not proof every required permission is requested and denial is handled. Overlay access also needs a user grant through special app access; whether the app reaches that settings flow remains unverified. Android documents [runtime permissions](https://developer.android.com/about/versions/marshmallow/android-6.0-changes) and [special permissions](https://developer.android.com/training/permissions/requesting-special).

`FOREGROUND_SERVICE` and `USE_FULL_SCREEN_INTENT` were introduced in API 28 and API 29, respectively. `READ_PHONE_DEVICES` is not a standard permission name in the public Android permission reference; its owner and behavior on the target system are unresolved. These declarations need checking against the actual API 25 build and its custom permission definitions before relying on them. [Android permission reference](https://developer.android.com/reference/android/Manifest.permission).

`testOnly=true` means the Revive APK is intended for ADB installation. The repo installer uses `adb install -t -r` for app packages, which explicitly enables test APK installation. [Manifest `testOnly`](https://developer.android.com/guide/topics/manifest/application-element#testOnly), [installer call](../../reviveMC74.py#L635-L650).

### Native ABI and imports

Revive packages only `armeabi-v7a` libraries. `readelf` identifies them as 32-bit ARM EABI v7: `liblinphone.so`, `libmediastreamer.so`, `libortp.so`, `libbctoolbox.so`, `libmswebrtc.so`, `libmsandroidcamera2.so`, and the bundled `libc++_shared.so`. SSM has no native `.so` files. The platform dependencies seen in `DT_NEEDED` are Bionic (`libc`, `libm`, `libdl`, `liblog`), graphics (`libEGL`, `libGLESv2`), Android (`libandroid`), ZIP (`libz`), and media/camera (`libcamera2ndk`, `libmediandk`); the Linphone stack dependencies are packaged in the APK. No obvious private platform library such as `libcutils.so` or `libandroid_runtime.so` appears in the dynamic dependency lists.

`libmsandroidcamera2.so` imports `ACamera*`/`AImage*` functions from `libcamera2ndk` and `libmediandk`. The native camera API is available from API 24, so that import family meets API 25's platform floor. NDK libraries eagerly resolve strong native symbols when loaded; a complete per-symbol/API-level check and actual library load are still needed for runtime proof. [NDK ABI guide](https://developer.android.com/ndk/guides/abis), [stable NDK APIs](https://developer.android.com/ndk/guides/stable_apis), [NDK API-level behavior](https://developer.android.com/ndk/guides/sdk-versions), [Android 7.0 private-library restrictions](https://developer.android.com/about/versions/nougat/android-7.0-changes).

### Framework and service assumptions

The Revive manifest exposes a SIP/telephone dialer activity and declares a Linphone service, boot receiver, sync/account services, and an SSM command service. The installer maps both APKs to packages `revive.MC74` and `ribo.ssm`, then starts `ribo.ssm/.SSMservice` before launching `org.linphone.dialer.DialerActivity` ([installer package map](../../reviveMC74.py#L57-L61), [startup sequence](../../reviveMC74.py#L826-L833)). The SSM manifest declares an exported `SSMservice`, an exported `SSMcmd`, and a boot receiver, so the cross-APK service dependency is explicit.

The DEX type/string tables in both APKs include `android.app.NotificationChannel` and `android.app.job.JobWorkItem` (API 26), `android.graphics.ColorSpace` (API 26), `android.app.Person` (API 28), and `android.graphics.Insets` (API 29). These references may sit behind AndroidX compatibility branches; a string/type scan cannot tell whether API 25 will load or execute those paths safely. [NotificationChannel](https://developer.android.com/reference/android/app/NotificationChannel), [ColorSpace](https://developer.android.com/reference/android/graphics/ColorSpace), [Person](https://developer.android.com/reference/android/app/Person), [Insets](https://developer.android.com/reference/android/graphics/Insets).

SSM also contains reflective references to `com.meraki.androidapi.devicemanager`, `com.meraki.devicemanager.PhoneDevice`, and `com.meraki.lights`, alongside “can't find class/method” log strings. This suggests optional or version-dependent Meraki integrations, but static strings do not show which core paths require them. No Meraki dialer APK is present, so its compatibility cannot be assessed here.

## Inferences and runtime unknowns

- The API floor, ARMv7 package ABI, and API 24 camera NDK dependency make API 25 a plausible static target. They do not prove all framework calls, native symbols, or audio paths work.
- Revive call setup depends on runtime microphone/audio permissions and the Linphone audio stack. Actual microphone, speaker, hook-switch, call interruption, and sleep/wake behavior depend on the target audio/input HALs and cannot be established from APK contents.
- SSM startup depends on the separate `ribo.ssm` package and its exported service. The availability and necessity of its Meraki-specific reflective targets remain unknown.
- Permission grant state, API 26+ references’ fallback guards, service boot reliability, and full-screen incoming-call behavior are unverified. No separate Meraki dialer APK is available.

## Focused compatibility test plan

1. On an API 25 test system with a compatible 32-bit ARM runtime, install the exact APKs using the repo’s `adb install -t -r` path. Check package-manager errors and effective grants for mic, contacts, phone state, and storage; exercise denied and granted states.
2. Start `ribo.ssm/.SSMservice`, reboot to exercise its boot receiver, then cold-start the Revive dialer. Capture logcat for missing API/class errors, `UnsatisfiedLinkError`, and service bind/start failures.
3. Exercise SIP registration, outgoing and incoming calls, lock-screen wake, mic/speaker routing, hook-switch controls, and recovery after suspend/resume. Repeat the VoIP checks on a separately authorized MC74 replacement build, because an emulator cannot validate its HAL and board paths.

This memo records static evidence only. It authorizes no device test or write.
