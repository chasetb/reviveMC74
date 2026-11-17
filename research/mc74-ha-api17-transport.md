# Secure transport options for the MC-74 on API 17

Research for [Find a secure transport usable by the MC-74 on API 17](https://github.com/chasetb/reviveMC74/issues/15), checked 2026-11-17. No token was created or sent; no app or CA was installed; no Home Assistant configuration or device state was changed. The owner's unique Home Assistant Cloud hostname is omitted.

## Finding

No route is established as both currently supported and secure enough to carry a Home Assistant bearer token from this API 17 device. Keep the interaction stopped after the host-side API reachability work in [Validate an API 17 Home Assistant state-read path](https://github.com/chasetb/reviveMC74/issues/14), before issuing a token, installing an app or CA, or configuring a bridge.

### Updated TLS provider

- Google `ProviderInstaller` installs a dynamically updatable TLS provider, but current Google Play services support excludes devices older than Android 7.0/API 24. It is not a maintained update route for this Android 4.2.3/API 17 target.
- Current upstream Conscrypt Android builds require API 21, and the current release is 2.9.0. The older Conscrypt 2.5.3 Android build declares API 9 minimum and includes TLS 1.2 plus `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256`, matching the suite seen in the prior host probe. That makes 2.5.3 a plausible credential-free prototype, not a currently supported production choice: no upstream commitment to maintain 2.5.3 was found, and later releases contain changes absent from it. Device ABI, provider loading, trust, and the actual handshake are untested.
- A provider can solve cipher negotiation only. The app still needs a trust anchor for the Cloud chain and must verify the expected Cloud hostname. The prior issue's read-only probe found a Let's Encrypt chain ending at ISRG Root X1; Let's Encrypt lists built-in Android trust for that root from 7.1.1, so API 17 must not assume it is trusted. Bundling a verified root can solve trust only if the app still performs normal chain/expiry validation and hostname verification.

### Controlled HTTPS bridge

- Android documents TLS 1.2 as supported by client sockets from API 16, but enabled by default only from API 20. It documents `TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA` as available and enabled by default from API 11. A bridge can therefore have a protocol/cipher intersection **only if** the client explicitly enables TLS 1.2 and the actual device accepts that handshake.
- That overlap alone is not enough to call the leg secure. The IETF TLS best-practice document recommends AEAD suites such as AES-GCM and says CBC suites should not be used unless Encrypt-then-MAC is successfully negotiated. No evidence establishes that this API 17 client negotiates Encrypt-then-MAC. TLS 1.0 is not an acceptable fallback; the IETF formally prohibits negotiating it.
- A bridge certificate could use a dedicated private CA installed as a user CA (Android apps targeting API 23 or lower trust user-added CAs by default) or a CA bundled and explicitly trusted by the app. Either requires a deliberate trust setup and hostname validation for the bridge DNS name. Installing a CA changes device state and was not done. Direct `SSLSocket` use does not perform hostname verification by itself; use a checked hostname verifier or an HTTPS client that performs it.
- The bridge's separate outbound connection can use modern TLS to the exact Cloud hostname, but it must independently verify both the server chain and hostname and send SNI. The previous issue #14 host-side probe reached the Cloud endpoint and got HTTP 401 without a credential; it does not prove a device handshake or revalidate today's endpoint. OpenSSL exposes explicit cipher-list and hostname-check controls for this split.

### Credentials and upkeep

- The device should never receive the Home Assistant bearer token. If a bridge is eventually accepted, keep the token in a service-owned secret file or OS secret store on the bridge host, outside the repository, URL, process arguments, logs, and device. Expose only the one read-only state operation, bind/firewall the listener to the trusted LAN and MC-74, and do not expose it to the WAN.
- Home Assistant long-lived access tokens last ten years. The built-in read-only group can read all entities rather than only the door, so a read-only identity still exposes broader state. Treat the bridge token as a high-value secret, restrict who can access its host, and revoke it if that host is lost or compromised. No token was issued in this research.
- Bridge upkeep would include OS/TLS updates, checking Cloud certificate/hostname validation after renewals, private-CA and bridge-certificate rotation if used, a narrow network ACL, and checking that the one-entity API remains read-only. This is ongoing infrastructure, not a one-time cipher setting.

## Required checks before any credential

After the boot/recovery gate in [Specify the Revive flash and rollback checkpoints](https://github.com/chasetb/reviveMC74/issues/12) and only when device work is authorized:

1. Read `ro.build.version.sdk`, build fingerprint, date/time, network/DNS reachability, and the status app's target SDK. For a bundled provider, record its exact version and device ABI; log its supported and enabled protocols/cipher suites.
2. With no token, test the exact Cloud hostname from the MC-74 using the candidate provider. Require TLS 1.2, the negotiated cipher, valid certificate chain and expected hostname; also require failures for wrong hostname, untrusted CA, expired certificate, and handshake failure. Do not permit TLS 1.0/1.1, HTTP fallback, or a trust-all manager.
3. For a bridge, first verify the bridge's exact DNS name and chosen CA trust path without a token. Capture the device handshake and bridge logs; require TLS 1.2, an API 17-supported ECDHE suite, and successful Encrypt-then-MAC negotiation. Confirm wrong-host/untrusted/expired certificates fail and TLS 1.0/1.1 cannot be negotiated. Separately verify the bridge's upstream TLS chain and exact Cloud hostname, including negative wrong-host and untrusted-CA checks.
4. Only after a route passes those checks and the owner chooses a credential model should one authenticated GET be tried. Confirm the token appears only in the bridge's outbound `Authorization` header, the bridge returns only the door state, and failures produce `UNAVAILABLE` without weakening TLS.

## Stop point

Neither option currently clears the security gate: current Conscrypt targets API 21+, the API 17-compatible Conscrypt build is not established as maintained, and the bridge's API 17 CBC leg has no proof of Encrypt-then-MAC. Stop before token creation, app/CA installation, bridge configuration, or the device's one-entity request. The remaining human decision is whether to accept a bounded, legacy-provider/bridge experiment with explicit risks, or stop the Home Assistant status goal at the API 17 transport boundary.

## Primary sources

- [Android `SSLSocket` protocols and cipher suites](https://developer.android.com/reference/javax/net/ssl/SSLSocket)
- [Android TLS security guidance](https://developer.android.com/privacy-and-security/security-ssl)
- [Android custom CA trust behavior](https://developer.android.com/privacy-and-security/security-config)
- [Google Play services support](https://developers.google.com/android/guides/overview/) and [`ProviderInstaller`](https://developers.google.com/android/reference/com/google/android/gms/security/ProviderInstaller)
- [Current Conscrypt Android build](https://github.com/google/conscrypt/blob/master/android/build.gradle), [Conscrypt 2.9.0 release](https://github.com/google/conscrypt/releases/tag/v2.9.0), [Conscrypt 2.5.3 Android build](https://github.com/google/conscrypt/blob/2.5.3/android/build.gradle), and [2.5.3 cipher definitions](https://raw.githubusercontent.com/google/conscrypt/2.5.3/common/src/main/java/org/conscrypt/NativeCrypto.java)
- [Let's Encrypt certificate compatibility](https://letsencrypt.org/docs/certificate-compatibility/)
- [IETF RFC 9325, secure TLS use](https://www.rfc-editor.org/rfc/rfc9325.html) and [RFC 8996, TLS 1.0/1.1 deprecation](https://www.rfc-editor.org/rfc/rfc8996.html)
- [OpenSSL TLS 1.2 cipher-list configuration](https://docs.openssl.org/3.5/man3/SSL_CTX_set_cipher_list/) and [OpenSSL hostname verification](https://docs.openssl.org/3.5/man3/SSL_set1_host/)
- Home Assistant [REST API](https://contributors.home-assistant.io/core/internals/rest-api/), [authentication](https://contributors.home-assistant.io/core/internals/auth-api/), [permissions](https://contributors.home-assistant.io/core/internals/permissions/), and [Cloud remote access](https://www.home-assistant.io/docs/configuration/remote/)
- [Prior API 17 host-side research note](https://github.com/chasetb/reviveMC74/blob/research/mc74-ha-api17/research/home-assistant-api17-state-read.md)
