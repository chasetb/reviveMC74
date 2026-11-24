# MC-74

This context describes the Cisco Meraki MC-74 hardware and the software used to revive it.

## Software states

**Revive installation**:
The software state supported by this repo that repurposes the MC-74 while retaining its original Android 4.2.3 platform.
_Avoid_: replacement ROM, new Android image

**Boot-only experiment**:
A trial of modified original Android boot software without installing the Revive application suite.
_Avoid_: Revive installation

**Replacement Android build**:
An Android operating system build for MC-74 hardware that differs from the original Android 4.2.3 platform.
_Avoid_: Revive installation

## Hardware

**Factory recovery**:
The recovery software present on an MC-74 before this project writes its recovery partition.
_Avoid_: ClockworkMod Recovery, CWM

**Debug interface**:
The physical interface labeled `DEBUG INTERFACE` on the MC-74 main board, with connector J1002. Its pinout and protocol have not been established.
_Avoid_: UART port
