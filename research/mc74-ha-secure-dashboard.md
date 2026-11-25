# Secure Home Assistant reads from the stock MC-74 app

Research for [issue #27](https://github.com/chasetb/reviveMC74/issues/27), checked 2026-11-25. This is a source review, not an on-device TLS test. No token was created or sent; no authenticated request, app/provider/CA install, Home Assistant configuration change, or device change was made.

## Resolution

**Stop before any authenticated read. No currently established route meets the inherited gate for a standalone app on stock Android 4.2.3/API 17 with LAN-only access.** A standalone app can use platform HTTPS APIs, but API 17 support alone does not establish a secure handshake with the current Home Assistant server profile, its certificate chain, and hostname. Do not send a bearer token over the existing plain-HTTP LAN endpoint or add an insecure fallback.

This is a stop point, not a claim that a future configured endpoint can never work. A local HTTPS endpoint or bridge would be a new server-side route requiring a separate decision and token-free on-device verification first.

## Findings

### Transport and server compatibility

- Android 4.2/4.2.2 is API 17. Android documents TLS 1.2 as supported by client sockets from API 16, but enabled by default only from API 20. An app can call `setEnabledProtocols`, which exists from API 1, to restrict a socket to TLS 1.2; a compliant client must fail if that handshake fails rather than retrying over HTTP or an older protocol. [Android API-level table](https://developer.android.com/guide/topics/manifest/uses-sdk-element) · [Android `SSLSocket`](https://developer.android.com/reference/javax/net/ssl/SSLSocket)
- API 17's documented cipher set does not include AES-GCM suites (Android lists the ECDHE-RSA AES-GCM suite from API 20); it does include older CBC suites. IETF TLS best-current-practice says CBC suites should not be used unless Encrypt-then-MAC is negotiated. No evidence establishes that this MC-74/API 17 client negotiates Encrypt-then-MAC. Therefore the documented API 17 CBC overlap is not enough to clear the gate. [Android `SSLSocket` cipher table](https://developer.android.com/reference/javax/net/ssl/SSLSocket) · [RFC 9325, §4.2](https://www.rfc-editor.org/rfc/rfc9325.html#section-4.2)
- Home Assistant can serve HTTPS directly, but its current HTTP integration recommends the `Intermediate v6` TLS profile, which accepts current TLS 1.2/1.3 ciphers and lists Android 4.4 as its oldest Android client. The `Modern v4` and `Intermediate v4` profiles are retained for installations that used outdated guidelines. This does not establish a currently recommended profile compatible with API 17; choosing a legacy profile would require a separate decision and a device test of the negotiated protocol, cipher, and Encrypt-then-MAC behavior. [Home Assistant HTTP integration: SSL settings and oldest clients](https://www.home-assistant.io/integrations/http#http-server-settings)
- The prior host-side probe in issue #14 found the then-current Home Assistant Cloud endpoint completed TLS 1.2 using AES-GCM, while probes limited to representative API 17 CBC suites did not complete. That was a remote endpoint and a host-side result from 2026-11-17, so it neither proves a current local-LAN handshake nor substitutes for the MC-74 test. The existing LAN address was recorded there as plain HTTP. [Issue #14 resolution](https://github.com/chasetb/reviveMC74/issues/14#issuecomment-6956838414) · [Issue #14 research note](https://github.com/chasetb/reviveMC74/blob/research/mc74-ha-api17/research/home-assistant-api17-state-read.md)
- The documented current Android Conscrypt build targets API 21+, and Google states that Android devices below API 24 are not supported for Google Play services updates. These do not provide a current supported provider-update path for API 17. An older Conscrypt build was previously identified as a credential-free prototype candidate, but it is outside the current upstream Android support statement. [Conscrypt Android build](https://github.com/google/conscrypt/blob/master/android/build.gradle) · [Google Play services support](https://developers.google.com/android/guides/overview/)

### Certificate and hostname verification

A secure candidate must use `HttpsURLConnection` with the platform's normal certificate trust checks and default hostname verifier. Android warns that raw `SSLSocket` does not verify hostnames by itself; custom trust managers or hostname verifiers must not be trust-all. API 17's stock trust store also cannot be assumed to trust the prior Cloud chain: Let's Encrypt lists built-in ISRG Root X1 trust starting at Android 7.1.1. A future endpoint must pass full chain, expiry, and exact-hostname checks on the actual MC-74. [Android HTTPS API](https://developer.android.com/reference/javax/net/ssl/HttpsURLConnection) · [Android TLS guidance](https://developer.android.com/privacy-and-security/security-ssl) · [Let's Encrypt compatibility](https://letsencrypt.org/docs/certificate-compatibility/)

### Authentication and token custody

Home Assistant's REST API requires an access token in the `Authorization: Bearer` header. The OAuth app flow returns a 30-minute access token and a refresh token; long-lived access tokens last ten years. With the no-persistence rule, a client could only keep credentials in volatile memory and would need to reauthorize or have the user re-enter a credential after the app process exits. These facts do not solve the transport gate, and no credential was issued or used. [Home Assistant REST API](https://developers.home-assistant.io/docs/api/rest/) · [Home Assistant authentication API](https://developers.home-assistant.io/docs/auth_api/)

### Read-only scope

Home Assistant's built-in **Read only** group grants read permission to **all entities**. It is not selected-entity-only. Home Assistant's permission model also supports per-entity `read` grants, and the REST `GET /api/states/{entity_id}` checks `POLICY_READ`; a custom narrow policy can therefore limit which states are visible. Group policies merge permissively, so membership in the built-in Read only group (or another broad group) defeats a narrow policy. No Home Assistant account or permission configuration was inspected or changed. [Built-in policy source](https://github.com/home-assistant/core/blob/dev/homeassistant/auth/permissions/system_policies.py) · [Permission model](https://developers.home-assistant.io/docs/auth_permissions/#entities) · [REST state-read enforcement](https://github.com/home-assistant/core/blob/dev/homeassistant/components/api/__init__.py#L1679-L1700)

## Stop point and future check

Do not create a token, install an app/provider/CA, configure a bridge or Home Assistant, or send an authenticated request. If a local HTTPS route is proposed later, first identify its exact LAN hostname and server profile, then run a token-free probe on the MC-74 that requires TLS 1.2 only, valid chain and hostname, and an acceptable cipher (or proven Encrypt-then-MAC if CBC is proposed). Require failures for an untrusted/expired certificate and a wrong hostname. A failed or unverified check ends the attempt; no HTTP/TLS downgrade fallback is allowed. Only after those checks and a separate credential decision should any authenticated read be considered.

## Prior decisions

- [Issue #14](https://github.com/chasetb/reviveMC74/issues/14): no demonstrated secure direct route from stock API 17 to the existing endpoints.
- [Issue #15](https://github.com/chasetb/reviveMC74/issues/15): neither an updated provider nor a bridge was established as a secure, currently supported route.
- [Issue #16](https://github.com/chasetb/reviveMC74/issues/16): stop authenticated reads at the API 17 transport gate; no token persistence or insecure fallback.
