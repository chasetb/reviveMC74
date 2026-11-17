# MC-74 normal boot and Meraki OTA slots

Research for [issue #11](https://github.com/chasetb/reviveMC74/issues/11), checked 2026-11-17. All device commands were read-only; no normal boot, OTA run, or partition write was attempted. The original partition map and capture method are recorded in [issue #10](https://github.com/chasetb/reviveMC74/issues/10#issuecomment-6939790551). The cited images and manifest are private local artifacts under ignored `backups/MC74-2026-11-17/`, unavailable on GitHub.

## Answer

With this MC-74's `fw_boot_state=normal`, **normal Android boot selects `boot` and mounts `system`** (primary image index 0). Its secondary image index 1 selects `boot2` and mounts `system2`. This follows from the captured U-Boot selection branch and boot-image fstab below. The live recovery also reports `androidboot.imgidx=0 androidboot.state=normal`; recovery loads its own partition, so that cmdline is supporting state evidence rather than an observed normal boot. Sources: `backups/MC74-2026-11-17/primary/{u-boot,u-boot-env,boot}.img`.

The **captured stock Meraki `firmware_updater` has a direct `system` flash target** and names `boot2` and `boot` as boot-image targets. It encodes `fw_boot_state` transitions to `dirty-primary` and `primary-ready`. The Meraki `DroidNode.apk` references `com.meraki.firmware.FirmwareUpdater`; `framework.jar` contains that API; `services.jar` contains `FirmwareUpdaterService` and the strings `firmware_updater` and `flash-over-primary`; the boot ramdisk registers `/system/bin/firmware_updater` as that socket service. This static chain ties the daemon to the Meraki update path. The separate Broadcom `OtaUpgrade.apk` mentions recovery `update.zip`, but its extracted DEX does not establish a link to this daemon. Sources: `backups/MC74-2026-11-17/primary/system2.img`, `/system/{app/DroidNode.apk,app/OtaUpgrade.apk,framework/framework.jar,framework/services.jar,bin/firmware_updater}`; `backups/MC74-2026-11-17/primary/boot.img` ramdisk.

There is no `system2` path or image name in the daemon or the captured `system2` filesystem. Its one `strncat` call is in a `popen` output-reading helper, and its format strings include no `system` plus `2` construction; this static inspection found no constructed `system2` destination. **This examined Meraki updater can update `system`; whether another stock OTA package or recovery path can update `system2` remains unproven.**

## Exact evidence

| Source | Observation |
| --- | --- |
| Live recovery, `adb shell cat /proc/cmdline` and `adb shell ls -l /dev/block/platform/sdhci.1/by-name` | Cmdline contains `androidboot.imgidx=0 androidboot.state=normal` (serials and MACs omitted). The by-name aliases map `boot`/`boot2` to `mmcblk0p15`/`p16` and `system`/`system2` to `p17`/`p18`. |
| Live `u-boot-env` and `u-boot-env2` captures | Both identify `MC74`/`Watchtower`, report `fw_boot_state=normal`, and their `bootcmd` invokes `android` when neither Mute nor Volume Down is held. The environment's U-Boot version is dated 2018-03-01, matching the captured primary `u-boot` binary; `u-boot2` is dated 2017-10-16. |
| Primary `u-boot` raw binary, loaded at `0x8e000000` | String offsets `0x335e0` and `0x337b2` label `0` primary and `1` secondary. In the boot selection code at offsets `0x7708`–`0x7720`, literal-pool entries at `0x7cf8` and `0x7cfc` resolve to `boot2` (`0x33514`) and `boot` (`0x3978f`). `cmp r4, #0; movne r5, r3` chooses `boot` when the index is zero, `boot2` otherwise, before the partition lookup at `0x7738`. |
| Captured `boot.img` ramdisk, `fstab.capri_me1` | The `system` entry has `wait,bootparm` and an explicit comment: for `/system`, image index 1 appends `2` to the partition path; index 0 leaves it unchanged. `boot.img` and `boot2.img` have matching SHA-256 in the private capture manifest. |
| Captured `boot.img` ramdisk, `init.bcm911130_me1.rc` | Registers `service firmware_updater /system/bin/firmware_updater` with socket `firmware_updater`. |
| Meraki `DroidNode.apk`, `framework.jar`, and `services.jar` in `system2.img` | DEX strings show `DroidNode` uses `com.meraki.firmware.FirmwareUpdater`, the framework defines that API, and `services.jar` defines `FirmwareUpdaterService` with `firmware_updater` and `flash-over-primary`. This is a static linkage, not an observed OTA transaction. |
| Meraki `system2.img` (2018-03-01 build), `/system/bin/firmware_updater` | Binary SHA-256 `20aea8ebd8a19f0f20ad1a919b618be169a037e5e13b46de916f693b11c109ec`; the file in `system.img` has the same hash. At binary offsets `0x230b`, `0x238a`, `0x23b4`, `0x2447`, and `0x24c6` its strings name `dirty-primary`, the `boot2` and `boot` block nodes, the `system` block node, and `primary-ready`. It also contains `dd if=%s of=%s bs=50M`, `system.img`, and `flash-over-primary`. No `system2` path/name appears in this binary. |

Sanitized primary excerpts (addresses are raw U-Boot file offsets):

```text
live /proc/cmdline: androidboot.imgidx=0 androidboot.state=normal
live u-boot-env:   fw_boot_state=normal
U-Boot 0x335e0:  Choosing image index (0: primary, 1: secondary)
U-Boot 0x7708:   ldr r3, [pc, #0x5e8]  ; pool 0x7cf8 -> "boot2"
U-Boot 0x770c:   ldr r5, [pc, #0x5e8]  ; pool 0x7cfc -> "boot"
U-Boot 0x7710:   cmp r4, #0
U-Boot 0x7718:   movne r5, r3
U-Boot 0x772c:   mov r0, r5         ; selected partition name
boot ramdisk fstab: # NOTE: For the mount of /system the bootparm flag appends a "2" to the partition path when the
boot ramdisk fstab: # firmware is index 1, and does nothing for index 0
boot ramdisk fstab: /dev/block/platform/sdhci.1/by-name/system              /system             ext4      rw                                                    wait,bootparm
boot ramdisk init:  service firmware_updater /system/bin/firmware_updater
boot ramdisk init:      socket firmware_updater stream 600 system system
Meraki services.jar: Unable to connect to the firmware_updater daemon.
Meraki services.jar: flash-over-primary
Meraki updater 0x230b: fw_setenv fw_boot_state dirty-primary
Meraki updater 0x238a: /dev/block/platform/sdhci.1/by-name/boot2
Meraki updater 0x23b4: /dev/block/platform/sdhci.1/by-name/boot
Meraki updater 0x2447: /dev/block/platform/sdhci.1/by-name/system
Meraki updater 0x24c6: fw_setenv fw_boot_state primary-ready
```

The newly captured `u-boot` and environment images were read twice from their by-name block nodes using `adb pull`; each pair matched in size and SHA-256. Their private mapping, sizes, hashes, and second-copy check are in `backups/MC74-2026-11-17/{manifest.md,SHA256SUMS}`. These images contain device identifiers and must stay private.

## Confidence and limit

**High** for the current normal-state `boot`/`system` selection: the live state, exact MC-74 U-Boot branch, and boot fstab agree. **Moderate** for the examined OTA write path: the Meraki updater has a `system` destination and no identified `system2` destination, but no stock OTA transaction or package was observed. Continue treating `system2` as a distinct rollback image; its contents differ from `system`, and the secondary boot state can select it. Source: `backups/MC74-2026-11-17/manifest.md`.
