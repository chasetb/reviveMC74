# Home status UI prototype

Throwaway issue #28 prototype for the stock MC-74. Three layouts live on one screen and switch with the bottom bar, left/right arrows, or `?variant=a|b|c`:

- A: priority list
- B: asymmetric dashboard board
- C: home-zone map

The feed is fixed mock data. The app has no `INTERNET` permission, makes no Home Assistant requests, and includes no credentials or entity IDs. The visible `Return to SIP` link and Android Back action open the installed `com.meraki.dialer2` app. The prototype is removable with `adb uninstall com.revivemc74.prototype.dashboard`.

Build and install on a connected stock MC-74 with:

```sh
./run.sh
```

The session build used a temporary toolchain extracted under `/tmp/mc74-prototype-tools/root`; set `MC74_PROTO_TOOLS` if it lives elsewhere. The prototype targets Android API 17 and uses the API 23 framework jar only for packaging.
