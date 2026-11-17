# MC-74 backup export research

Research for [issue #8](https://github.com/chasetb/reviveMC74/issues/8), within the [firmware and Home Assistant map](https://github.com/chasetb/reviveMC74/issues/1). Checked 2026-11-16. Source review only; no device operation was run.

## Finding

**No safe capture-and-export path is established under the recorded setup. Keep the partition-write gate closed.** The only observed CWM destination is `/sdcard`; a CWM nandroid backup creates files on that destination, so it is not a zero-write capture. The MC-74's actual block-device mapping for `/sdcard` is unverified. Neither host enumerated the MC-74 over USB, so ADB cannot currently export files or stream an image. No removable card was present. These are the observations recorded in [issue #7](https://github.com/chasetb/reviveMC74/issues/7#issuecomment-6937968888), not fresh device checks.

## What the available methods establish

- **CWM backup:** The CyanogenMod `cm-10.2` recovery source builds the backup destination from the selected storage path and writes a timestamped backup directory under `clockworkmod/backup`. Its menu can offer extra storage paths configured for a device, so an external-card target is device-specific. This source is a CWM 6.x reference, not proof of the exact MC-74 recovery build or its storage mapping. [CWM menu and destination code](https://github.com/CyanogenMod/android_bootable_recovery/blob/cm-10.2/extendedcommands.c#L1059-L1159) [CWM backup implementation](https://github.com/CyanogenMod/android_bootable_recovery/blob/cm-10.2/nandroid.c)
- **ADB export:** Android's documented `adb pull` copies a file or directory from a device to the host; it requires a working ADB connection. ADB sideload is not a pull path: recovery's sideload mode accepts only `adb sideload`, not `pull`, `push`, or `shell`. The reported absence of USB enumeration means neither route is currently available. [ADB file-copy commands](https://developer.android.com/tools/adb#copyfiles) [AOSP recovery sideload limits](https://source.android.com/docs/core/ota/nonab/device_code#sideloading-mechanism)
- **CWM integrity checks:** CWM's nandroid code creates and checks a `nandroid.md5` manifest. Keep that manifest and the whole backup directory together; some CWM formats use shared blobs. After export, verify the manifest on the host and record SHA-256 hashes for the exported files. CWM's MD5 check detects file changes but does not prove the image came from the claimed device or partition; MD5 is not suitable for collision-resistant authentication. [CWM backup/restore code](https://github.com/CyanogenMod/android_bootable_recovery/blob/cm-10.2/nandroid.c) [NIST Secure Hash Standard](https://csrc.nist.gov/pubs/fips/180-4/upd1/final) [RFC 6151](https://www.rfc-editor.org/rfc/rfc6151.html)

## Evidence required before trusting images

For each `boot`, `recovery`, and `system` artifact, retain:

1. The exact recovery version/device identity observed during capture and the actual recovery partition map (`recovery.fstab` or equivalent) tying each label to its source block device. Do not infer the MC-74 mapping from another device's source tree.
2. CWM's complete backup log showing each requested partition completed, plus the unmodified output directory and `nandroid.md5`. The system artifact's filename/format is build-dependent; preserve every file in the backup, including any shared blobs.
3. A successful host-side `md5sum -c nandroid.md5` after export, file sizes, and a separate SHA-256 inventory stored outside the backup. Keep an untouched second copy. Hashes establish that the copies match the captured bytes; provenance still depends on the device identity, partition map, and capture log.

## Recommendation

Do not start **Backup to `/sdcard`** while the gate forbids writes to device storage: it writes a backup directory there, and the backing partition is unknown. A removable-media route is only a future possibility if a card is available and this specific CWM build visibly exposes it as a distinct destination; then the complete backup can be carried to a host for the checks above. An ADB route is only possible after USB enumeration and a usable recovery ADB connection are observed. Neither prerequisite is met in issue #7, so no safe path is known for the current setup.
