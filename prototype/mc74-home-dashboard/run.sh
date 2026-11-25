#!/bin/sh
set -eu

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tools=${MC74_PROTO_TOOLS:-/tmp/mc74-prototype-tools/root}
java="$tools/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
aapt="$tools/usr/bin/aapt"
android_jar="$tools/usr/lib/android-sdk/platforms/android-23/android.jar"
build="$here/build"
keystore="$tools/home-status-prototype.jks"

export PATH="$tools/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH"
export LD_LIBRARY_PATH="$tools/usr/lib/7zip:$tools/usr/lib/x86_64-linux-gnu/android:$tools/usr/lib/x86_64-linux-gnu:$tools/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
rm -rf "$build"
mkdir -p "$build"
"$aapt" package -f -M "$here/AndroidManifest.xml" -A "$here/assets" -I "$android_jar" --min-sdk-version 17 --target-sdk-version 17 -F "$build/unsigned.apk"
"$java" -cp "$tools/usr/share/java/*" org.jf.smali.Main assemble --api 17 -o "$build/classes.dex" "$here/smali"
cp "$build/unsigned.apk" "$build/with-classes.apk"
(cd "$build" && zip -q with-classes.apk classes.dex)
if [ ! -f "$keystore" ]; then
  "$tools/usr/lib/jvm/java-17-openjdk-amd64/bin/keytool" -genkeypair -keystore "$keystore" -storepass prototype -keypass prototype -alias prototype -dname "CN=Home Status Prototype" -keyalg RSA -keysize 2048 -validity 365 -noprompt >/dev/null 2>&1
fi
"$java" -cp "$tools/usr/share/java/*" com.android.apksigner.ApkSignerTool sign --ks "$keystore" --ks-pass pass:prototype --key-pass pass:prototype --min-sdk-version 17 --v1-signing-enabled true --v2-signing-enabled false --out "$build/home-status-prototype.apk" "$build/with-classes.apk"
adb install -r "$build/home-status-prototype.apk"
adb shell am start -n com.revivemc74.prototype.dashboard/.MainActivity
