# Research: PhoenixSheppy prebuilt `/system` archive

Context: [Assess the old prebuilt /system archive](https://github.com/chasetb/reviveMC74/issues/4).

## Scope and method

This is read-only documentation and repository research. The Mega-hosted archive bytes were not accessed: browser site-safety blocked the `mega.nz` link, so I did not try another route. No archive hash or contents inspection is claimed; nothing was executed, installed, or flashed.

## Findings

- **What the guide claims:** PhoenixSheppy's [setup guide](https://github.com/PhoenixSheppy/reviveMC74.com/blob/main/docs/setup.md) links a Mega `.zip` and describes it as a backup of the author's `/system` partition, built from their phone, configured to allow ADB on boot, with the Meraki dialer removed. The guide gives manual CWM sideload and wipe steps. This is the publisher's description, not independently verified provenance. The [guide's Git history](https://github.com/PhoenixSheppy/reviveMC74.com/commits/main/docs/setup.md) shows its last change in February 2021.
- **Availability:** The setup guide still contains a Mega link, but the Reddit [original poster reported that the link was dead](https://www.reddit.com/r/ReviveMC74/comments/1mu907l/anyone_have_a_prebuilt_system_image/). I could not verify whether the hosted file is currently available because the browser safety gate blocked access to Mega.
- **Hash, exact contents, and Android build:** The guide publishes no SHA-256 or other checksum, file manifest, exact hardware revision, build fingerprint, or partition size. Because the archive bytes were inaccessible, its format, integrity, contents, Android version, and any device assertion inside it remain unverified. No digest has been calculated.
- **The Reddit “master image” is a separate, unverified artifact:** In the same thread, commenter Jacobwitt says they would look for a master image set up for TWRP and flashable as a ZIP. No download link or checksum is posted there, and the comment does not establish that it is the PhoenixSheppy archive. Another commenter reports mixing a working and broken image between two devices, after which neither booted; a follow-up says one could not mount eMMC in recovery. These are user reports, not compatibility tests for either image.
- **The repo does not provide a matching `/system` image:** The [reviveMC74 repository tree](https://github.com/chasetb/reviveMC74/tree/main/installFiles) contains the CWM recovery image, scripts, APKs, and utilities, but no replacement `/system` archive. Its [README](https://github.com/chasetb/reviveMC74/blob/main/README.md#phone-software) says the Revive installation retains Android 4.2.3; it supplies no reference system image against which to authenticate this archive.

## Assessment

The archive cannot be authenticated or shown compatible with this MC-74 from available evidence. The guide offers a first-person provenance claim, but no independently checkable hash, exact build/device metadata, or verified archive bytes. The separate Reddit “master image” is also unidentified. Treat both as unsuitable for flashing unless new evidence closes those gaps.

Before considering either image, require:

1. The exact archive bytes from a source controlled by the original publisher, plus a SHA-256 published through an independently authenticated channel.
2. A non-executing inspection report for the archive structure, partition contents, Android build fingerprint, device assertions, partition sizes, and any installer script.
3. Evidence that the image matches the MC-74 hardware revision and partition layout, ideally a successful restore/boot report tied to the same SHA-256.
4. A verified backup of this device's original partitions and a demonstrated recovery path before any partition write, as required by the [map's safety gate](https://github.com/chasetb/reviveMC74/issues/1).

No archive was executed, installed, or flashed, and no device commands were run.
