# MC74 Hardware And Supporting Software

A VOIP application to revive the MC74 that was withdrawn and abandoned by Cisco/Meraki.
This package contains code and instructions on how to (more or less) automatically root
an MC74 and install the new Android apps to allow the phone to be used on any VOIP
provider.

### Debug interface

The main board labels connector J1002 `DEBUG INTERFACE`. The opposite side labels nearby connectors J1301 `HANDSFREE MIC` and J801 `TOUCH SCREEN`. The J1002 pinout, voltage, protocol, and relationship to nearby test pads remain unmeasured.

#### First measurement pass

1. Disconnect the DC adapter, PoE, USB, and UART. Put the meter leads in COM and V/Ω. On DC volts (20 V range or auto-range), verify 0 V across the DC input.
2. Switch to resistance (Ω). With a manual-range meter, use its lowest available range for low-resistance pads and increase the range for `OL` readings. Touch the probes together and note their resistance. The Klein MM325's continuity position also displays a low-resistance value.
3. Measure each labeled test pad against the DC jack sleeve. Record its TP number and stable resistance, `OL`, or a changing reading. Leave J1002's fine contacts untouched during this pass.

#### Unpowered measurements

With the DC input at 0 V and power disconnected, resistance from each pad to the DC jack sleeve was measured on the meter's 200 kΩ range. The shorted-probe reading was `0.0` on that range. These are kΩ readings; `0.0` here does not establish a zero-ohm connection.

| Pad | Resistance to jack sleeve (kΩ) |
| --- | ---: |
| TP814 | 0.0 (continuity tone also observed) |
| TP1001 | 10.5 |
| TP802 | 10.5 |
| TP811 | 0.0 |
| TP803 | 14.1 |
| TP1016 | 14.1 |
| TP1312 | 0.9 |
| TP1311 | 135.9 |

On a Klein MM325's continuity setting, shorted probes, TP814 to jack sleeve, and TP811 to jack sleeve each displayed `0.0` and beeped. TP814 and TP811 are ground-connected at the meter's resolution.

With power disconnected, TP1001–TP802 and TP803–TP1016 each displayed `0.0` and beeped on continuity. TP1312–TP814 did not beep. The first two pairs are connected at the meter's resolution; TP1312's powered 0 V reading does not make it a confirmed ground pad.

#### Powered voltage survey

With power disconnected, put the meter leads in COM and V/Ω, select 20 V DC, and secure the black lead to TP814. If it cannot stay secure without being held, stop before applying power. Connect the confirmed 12 V center-positive supply, leaving PoE and UART disconnected. Verify about 0 V at TP811, then measure each remaining labeled test pad one at a time without bridging adjacent contacts. Record its TP number, voltage, and whether the reading is steady or changing. Disconnect power before moving the ground lead. Do not use resistance or continuity mode while powered, and leave J1002's fine contacts untouched.

With the black lead on TP814 and the meter set to 20 V DC, the following steady voltages were reported.

| Pad | Reported voltage (V DC) |
| --- | ---: |
| TP1001 | 3.31 |
| TP802 | 3.31 |
| TP811 | 0.0 |
| TP803 | 1.80 |
| TP1016 | 1.80 |
| TP1312 | 0.0 |
| TP1311 | 0.38 |

TP811 read 1.1–1.2 V when the black lead was clipped to the DC input jack's apparent ground contact, but 0.0 V when referenced to TP814. The jack contact and reason for the difference remain unverified, so use TP814 as the reference for subsequent powered measurements. Matching DC voltages do not establish that pads share a net or carry UART signals.

An [MC74 owner's oscilloscope report](https://www.reddit.com/r/meraki/comments/gj6ael/mc74_debug_connector/) claims a 1.8 V, 115200 baud UART on the debug connector (RX 5, TX 6, ground 7). This is an unverified lead; the connector pin numbering and correspondence to this board's test pads are not established.

### Prerequisites
