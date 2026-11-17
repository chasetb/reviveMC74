# MC-74 recovery ADB capture and export research

Research for [issue #8](https://github.com/chasetb/reviveMC74/issues/8), within the [firmware and Home Assistant map](https://github.com/chasetb/reviveMC74/issues/1). Checked 2026-11-16. The device observations below are read-only checks reported for this ticket; no image was saved during them.

## Finding

**`adb pull` is a tested read-only capture path for the MC-74 boot partition, and is a candidate for recovery and system once their transfers are captured and checked.** AOSP's Android 4.2.2 ADB host code accepts block devices as pull sources; its device sync service opens the remote node with `O_RDONLY` and streams bytes. On this MC-74, `adb pull /dev/block/platform/sdhci.1/by-name/boot /dev/null` succeeded and transferred 8,388,608 bytes, matching the reported boot size. `/dev/null` was the host destination, so this probe intentionally discarded the bytes: no image was saved or hashed. The AOSP source explains the mechanism; the successful boot transfer is the device-specific evidence. [AOSP Android 4.2.2 ADB pull client](https://android.googlesource.com/platform/system/core/+/android-4.2.2_r1/adb/file_sync_client.c#L947) [AOSP Android 4.2.2 device sync service](https://android.googlesource.com/platform/system/core/+/android-4.2.2_r1/adb/file_sync_service.c#L323) [ADB file-copy documentation](https://developer.android.com/tools/adb#copyfiles)

The device was listed by ADB in CWM recovery as product/device `capri_me1`, model `BCM28155_TEST_PHONE`; `adb shell id` reported uid 0. `/etc/recovery.fstab` maps `boot`, `recovery`, and `system` to by-name aliases. The reported `/dev/block/platform/sdhci.1/by-name` listing resolves them to `mmcblk0p15`, `mmcblk0p21`, and `mmcblk0p17`, respectively. `/proc/partitions` reports 8,192, 16,384, and 518,144 1K blocks (8,388,608; 16,777,216; and 530,579,456 bytes). It also lists `boot2` and `system2`; do not infer that those are the requested original partitions.

The `/sdcard` path is a symlink to `/data/media`, but `/data` is not mounted; `df /sdcard` and listing a backup directory there fail. No removable microSD slot or external-card mount exists in the reported setup. [Issue #9 resolution](https://github.com/chasetb/reviveMC74/issues/9#issuecomment-6939022258)

## What the path does and does not write

- **Direct block capture:** `adb pull /dev/block/platform/sdhci.1/by-name/<verified-label> <host-file>` reads the selected device node and creates the destination file on the host. The successful boot pull confirms this path works for that node. The recovery and system nodes have been mapped but not pulled yet. The command does not write the selected partition or create an image on `/sdcard`.
- **CWM backup to `/sdcard`:** CWM nandroid creates a backup directory under the selected storage path. It writes to device storage; here `/sdcard` points into unmounted `/data`, and no external-card destination exists. Do not use this route under a no-device-write gate. [CWM destination code](https://github.com/CyanogenMod/android_bootable_recovery/blob/cm-10.2/extendedcommands.c#L1059-L1159) [CWM nandroid implementation](https://github.com/CyanogenMod/android_bootable_recovery/blob/cm-10.2/nandroid.c)
- **Partition write:** `dd of=/dev/block/...`, `adb push` to a device path, flash, and restore operations have a device-side destination. They are not capture/export operations and must not be used here.

`adb exec-out id` failed with `error: closed`, and `adb shell -T id` reported that this device only supports allocating a PTY. These checks rule out those two tested command forms on the current recovery; the successful `adb pull` is the working route. The ADB enumeration alone would not prove shell/read access, but uid 0 and the boot pull were observed. Recovery and system still need successful pulls.

## Evidence required for trusted images

Before capture, retain a timestamped record of:

1. The recovery screen/version, `adb devices -l` output showing recovery state, device product/model, and the host ADB version. Redact the serial if the record will be shared publicly.
2. The actual `/etc/recovery.fstab` entries and by-name symlink targets mapping `boot`, `recovery`, and `system` to source nodes, plus `/proc/partitions` and the nodes' major/minor numbers. The reported mapping above is the current candidate; do not infer labels from partition order or another device's layout.
3. The current mount table, showing each source partition unmounted during capture, and the read-only shell identity/access check. If a source is mounted or the mapping/access is ambiguous, stop rather than probing by writing or by starting a CWM backup.

For each saved image, keep the exact `adb pull` source and host destination, successful command output, transferred byte count, and expected partition size from the recovery's block-device metadata. On the host, record the resulting file size and SHA-256; repeat the read and compare hashes if the source can be held quiescent. Preserve the capture log and an untouched second copy. A matching size and hash support completeness and copy integrity; provenance still depends on the recovery identity, verified partition map, and capture log. No boot, recovery, or system image has yet been saved or hashed, so the backup/safety gate remains closed.

## Historical context

The earlier note at [commit `4a331b4`](https://github.com/chasetb/reviveMC74/blob/4a331b4/research/mc74-safe-backup-export.md) concluded that no safe path was established when ADB was absent and the only observed CWM destination was `/sdcard`. That conclusion was correct for its recorded baseline. Recovery ADB is now enumerated and the boot node has passed a discard-only pull, which changes the available route. No image has yet been saved or verified.
