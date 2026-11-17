# MC-74 Replacement Android and recovery-path evidence

Research for [issue #18](https://github.com/chasetb/reviveMC74/issues/18), following [issue #17](https://github.com/chasetb/reviveMC74/issues/17)'s decision to keep Home Assistant interaction unavailable until secure transport is proven. Checked 2026-11-17. No device partition was written, no build was installed, and no Home Assistant or credential operation was performed.

## Finding

**No Replacement Android build is verified by the available evidence.** The available reproducible system images are both Meraki Android 4.2.3 builds for `capri_me1`; the checked-in CWM artifact is a recovery image, not an Android system build. Upstream Linux source includes generic BCM28155 SoC support, but that is not evidence of a bootable MC-74 product build. Community posts describe modified stock Android and unsuccessful attempts to find a vanilla ROM, but provide no verifiable candidate image, checksum, build recipe, or MC-74 compatibility test. This is a bounded finding about the evidence reviewed, not proof that no build exists.

**Read-only recovery and backup access are verified; a write-capable installation or restore route is not.** The captured recovery has root ADB and direct by-name captures were read twice and hash-checked. Fastboot did not enumerate in recovery, and entry into or access to MC-74 Fastboot remains unverified. The Meraki updater inspection identifies a primary-system update route, but no observed OTA transaction and no `system2` write path. Therefore the current evidence does not establish a safe way to install a Replacement Android build or restore the saved system images.

## Verified hardware and current Android images

The local captures are documented in the private, ignored files `backups/MC74-2026-11-17/manifest.md` and `backups/MC74-2026-11-17/SHA256SUMS`; neither file nor any raw capture is included in this report or linked from GitHub. The manifest records CWM 6.0.4.7, recovery ADB as `capri_me1` / `BCM28155_TEST_PHONE`, root shell access, the by-name map, unmounted source partitions, and two separate reads of each image with matching size and SHA-256. `userdata.img` may contain personal data.

Reproducible offline inspection of both captured ext4 system images (`strings -a <image>`) returns the same product properties and build fingerprint:

```text
ro.product.model=Meraki MC 74
ro.product.name=capri_me1
ro.product.device=capri_me1
ro.product.board=capri
ro.build.version.release=4.2.3-phone-5068355-southern-userdebug
ro.build.fingerprint=Meraki/capri_me1/capri_me1:4.2.3-phone-5068355-southern-userdebug/JDQ39/x:userdebug/release-keys
```

Both property sets were found in `system.img` and `system2.img`. Their recorded SHA-256 values differ, so they are separate images, even though they identify the same Android release and product. The capture records `boot.img` and `boot2.img` as byte-identical. The image files are device-state captures, not an independently authenticated factory firmware package. [The existing slot note](mc74-bootloader-ota-slots.md) records the raw U-Boot and fstab evidence: index 0 selects `boot` and mounts `system`; index 1 selects `boot2` and mounts `system2`. It also records live `fw_boot_state=normal` and recovery cmdline `androidboot.imgidx=0 androidboot.state=normal`.

Upstream [Android kernel BCM machine configuration](https://android.googlesource.com/kernel/common/+/34d3a78c681e8/arch/arm/mach-bcm/Kconfig) names BCM28155 in the supported Broadcom mobile SoC family. This is SoC-level kernel support only; it does not identify an MC-74 product target, display/touch/audio configuration, proprietary vendor components, a matching boot image, or a tested system image. No MC-74-specific replacement Android source tree or release artifact was identified in the reviewed repository and public primary-source searches.

## Candidate claims and provenance

The repo's [README](../README.md) explicitly says Revive retains the original Android 4.2.3 platform. The checked-in [recovery image](../installFiles/recovery-clockwork-touch-6.0.4.7-mc74v2.img) has SHA-256 `576c0be6a27c1b683550a78cf944729408157895b797825264ef6146b04dd0f2` and `file` identifies it as an Android boot image with a kernel and ramdisk. Its name, format, and code usage identify it as CWM recovery, not a `/system` replacement. The captured current recovery also reports CWM 6.0.4.7, but its digest (`12c0ea6b…`) differs from the checked-in image; byte-for-byte identity and artifact provenance are not established.

The repo's [`replaceRecoveryFunc`](../reviveMC74.py#L271) intends to run `fastboot flash recovery` with that CWM image. Its [`adbModeFunc`](../reviveMC74.py#L696) asks ADB to reboot to bootloader and then waits for Fastboot enumeration. These are documented code paths, not proof that this particular MC-74 enters Fastboot or accepts a write. The capture manifest explicitly says Fastboot did not enumerate while in recovery and Fastboot entry/access has not been verified.

The generic [`flashPartFunc`](../reviveMC74.py#L495) is a device-writing primitive: it pushes a supplied image to `/cache` and uses `dd` to write a caller-selected by-name partition, with `boot`/`boot2` as its default. This code does not validate a candidate Replacement Android build's product identity, image size, release provenance, or boot compatibility. It is not evidence that an arbitrary system image is safe to install.

The prior [prebuilt-system archive assessment](https://github.com/chasetb/reviveMC74/blob/research/mc74-prebuilt-image/research/assess-old-prebuilt-system-archive.md) found no independently verifiable archive bytes, hash, fingerprint, or exact device claim for PhoenixSheppy's linked archive; its bytes were not available for inspection. Community posts include a report of exposing a bare Android environment by removing Meraki apps from the original Jelly Bean system, and another report that a vanilla ROM could not be found. Those are user claims, not artifact provenance or a verified Replacement Android build: [MC-74 ROM discussion](https://www.reddit.com/r/meraki/comments/c0lpvl/meraki_mc74-discovery-to-root-and-make-the-phone/) and [ROM question](https://www.reddit.com/r/meraki/comments/clt3cp/).

## OTA and rollback evidence

The [slot and OTA analysis](mc74-bootloader-ota-slots.md) statically inspected the captured U-Boot, boot ramdisk, Meraki framework, and `firmware_updater` binary. It found that normal state selects primary `boot`/`system`; secondary index selects `boot2`/`system2`; and the examined Meraki updater names primary `system`, `boot`, and `boot2` targets and transitions through `dirty-primary` and `primary-ready`. It found no `system2` path in that updater. This supports the examined stock update path only. No OTA was run, so the static strings do not prove the behavior of every package or a successful transaction.

The captured `boot`, `boot2`, `system`, `system2`, `recovery`, and `userdata` images have repeat-read matching sizes and hashes in the manifest. This supplies a reproducible host-side snapshot of the current device state. It is not a tested restore set: `recovery.img` is the installed CWM recovery rather than a known stock recovery; the capture has not been restored; and Fastboot access is unverified. The captures show `/cache` was mounted and had room to stage one large image, while `/data` was not mounted and `/sdcard` resolves there; CWM's usual `/sdcard` backup destination is therefore not established as available. Do not mistake the root ADB shell or the readable block-device nodes for proof that writing or rollback works.

AOSP Android 4.2.2's [ADB pull client](https://android.googlesource.com/platform/system/core/+/android-4.2.2_r1/adb/file_sync_client.c#L947) and [device sync service](https://android.googlesource.com/platform/system/core/+/android-4.2.2_r1/adb/file_sync_service.c#L323) show that `adb pull` reads a remote source and streams it to the host. The MC-74 capture manifest records that exact direct by-name read method repeated twice for the saved images. This confirms a read-only capture path; it does not establish a corresponding safe write path.

## Decision and evidence still needed

Keep Replacement Android installation unsupported for now. A candidate would need a published artifact or reproducible build, a cryptographic digest, source/build provenance, explicit `capri_me1`/MC-74 target evidence (not just BCM28155 SoC similarity), partition-size and boot-image compatibility evidence, and a demonstrated boot/recovery route. A rollback claim would additionally need a verified way to write the saved images back, including a known-good recovery image; no such restore was attempted or established here.

If a candidate artifact later appears, collect these read-only facts before considering any write: (1) if the device enters Fastboot, record `fastboot devices` and supported read-only product/lock variables such as `fastboot getvar product` and `fastboot getvar unlocked`; (2) in recovery, record the recovery identity, by-name mapping, partition byte sizes, `/proc/cmdline`, and mount state; and (3) inspect the candidate package's target metadata and partition paths offline without running its updater. Redact device identifiers. These observations can reject a mismatch, but they cannot prove a write or restore will succeed; until a supported candidate and a verified recovery route exist, installation and rollback remain unsupported.

### Sources

- Private local capture evidence in `backups/MC74-2026-11-17/manifest.md` and `backups/MC74-2026-11-17/SHA256SUMS` — ignored and intentionally not published.
- [MC-74 boot and Meraki OTA slot analysis](mc74-bootloader-ota-slots.md) — U-Boot selection and static updater inspection.
- [Issue #18](https://github.com/chasetb/reviveMC74/issues/18), [Issue #17](https://github.com/chasetb/reviveMC74/issues/17).
- [Android kernel BCM configuration](https://android.googlesource.com/kernel/common/+/34d3a78c681e8/arch/arm/mach-bcm/Kconfig); [AOSP ADB client](https://android.googlesource.com/platform/system/core/+/android-4.2.2_r1/adb/file_sync_client.c#L947); [AOSP ADB sync service](https://android.googlesource.com/platform/system/core/+/android-4.2.2_r1/adb/file_sync_service.c#L323).
