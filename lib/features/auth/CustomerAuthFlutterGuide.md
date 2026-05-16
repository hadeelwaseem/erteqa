# Customer Authentication — Flutter Integration Guide

Scope
-----
This document covers only the customer-facing authentication endpoints in ShopEngine and provides implementation guidance for Flutter mobile apps. It focuses on OTP (one-time password) mobile authentication used by customers (not admin or merchant auth).

Endpoints Covered
-----------------
- `POST /api/v1/customer/auth/otp/request`
- `POST /api/v1/customer/auth/otp/verify`

Summary / Key Behaviors
-----------------------
- OTPs are issued for an existing store tenant (customer flows use tenantId or tenantSlug to target a store).
- OTPs are sent via WhatsApp (UltraMsg integration) and are valid for 5 minutes (TTL).
- Requests are rate-limited per tenant (backend enforces tenant rate limits).
- Verification issues a JWT pair (access + refresh) and records an auth session on the server.
- Optional second factor (TOTP / backup codes) may be enforced if enabled for the user.

1) POST /api/v1/customer/auth/otp/request
-----------------------------------------
Purpose
- Request a short-lived OTP for a customer's phone number for a given tenant (store). OTP is delivered via WhatsApp.

HTTP
- Method: POST
- Path: `/api/v1/customer/auth/otp/request`

Request Body (JSON)
```
{
  "phone": "+963911000111",
  "tenantId": "<optional-uuid>",
  "tenantSlug": "store-a",
  "fullName": "Optional Customer Name"
}
```

Validation rules
- `phone`: required, pattern `^[0-9+]{8,15}$` (8–15 digits, may include `+`).
- `tenantId` or `tenantSlug`: provide at least one to target the store; backend will resolve tenant.

Success Response
- HTTP 200 with ApiResponse wrapper, data string: `"OTP sent via WhatsApp"`.

Errors & Edge Cases
- 400 — validation error (malformed phone, missing required fields).
- 429 — tenant rate limit exceeded (user should see cooldown UI / wait before trying again).
- 500 — unexpected server error.

Flutter integration notes
- UX: Show a simple screen to enter phone and optional name, then call endpoint. Show an informative message after success and start an OTP countdown (5 minutes).
- Retries: On network failure, retry with exponential backoff (max 3 tries). On 429, surface the throttle time if provided; otherwise display a friendly cooldown message and disable resend for a short window.
- Logging: Never log OTP values or display them in debug logs.

2) POST /api/v1/customer/auth/otp/verify
-----------------------------------------
Purpose
- Verify the OTP (and optional second factor) and receive JWT tokens for authenticated access as a customer.

HTTP
- Method: POST
- Path: `/api/v1/customer/auth/otp/verify`

Request Body (JSON)
```
{
  "phone": "+963911000111",
  "tenantId": "<optional-uuid>",
  "tenantSlug": "store-a",
  "otpCode": "123456",
  "totpCode": "654321",     // optional, used if 2FA is enabled
  "backupCode": "<backup-code>" // optional fallback
}
```

Validation rules
- `phone`: required, same pattern as above.
- `otpCode`: required, exactly 6 digits (@Size(min=6,max=6)).
- `totpCode`: optional, if provided must be 6 digits (@Size(min=6,max=6)).

Success Response
- HTTP 200 with ApiResponse wrapper, `AuthTokenResponseDto` payload. Fields of interest:
  - `accessToken` — Bearer JWT used for API Authorization header
  - `refreshToken` — long-lived token used to refresh access tokens
  - `tokenType` — typically `Bearer`
  - `expiresIn` — lifetime in seconds
  - `issuedAt` / `expiresAt` — timestamps
  - `username`, `userId` — user identity
  - `tenantId`, `tenantSlug` — tenant resolved into token claims
  - `roles` — role set (e.g., ["CUSTOMER"]).

Example success payload (data part):
```
{
  "accessToken": "<jwt-access>",
  "refreshToken": "<refresh-token>",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "issuedAt": "2026-05-03T12:00:00",
  "expiresAt": "2026-05-03T13:00:00",
  "username": "+963911000111",
  "userId": "20000000-...",
  "tenantId": "10000000-...",
  "tenantSlug": "store-a",
  "roles": ["CUSTOMER"]
}
```

Authentication flow behavior (server-side specifics)
- OTP TTL is 5 minutes; backend stores a hashed OTP and compares using `PasswordEncoder`.
- If TOTP/backup-code second factor is enabled for the account, the backend will validate `totpCode` or `backupCode` via `TotpService`.
- On success, `SecurityProvider.issueAuthentication(...)` issues new tokens and server records the issued access token in an auth session registry.
- Errors thrown by backend include codes for expired/invalid OTP, no active challenge, user not found, authentication failed, and tenant rate limits.

Required headers / tokens
- Both endpoints are public for unauthenticated users — no Authorization header required.
- After `otp/verify`, include `Authorization: Bearer <accessToken>` for protected API calls.
- Some multi-tenant endpoints may also require a `X-Tenant-Id` or tenant-specific header in the product API — prefer using token claims returned by the backend.

Error handling expectations (map to Flutter UX)
- Invalid / malformed input (400): surface field-level messages and guide user to correct phone/OTP format.
- `OTP_EXPIRED` (server): prompt user to request a new OTP, show a resend button.
- `OTP_INVALID` (server): allow retry attempts, but avoid infinite retries — after N attempts encourage to request new OTP.
- `RESOURCE_NOT_FOUND` (user not found): prompt to register or verify tenant selection.
- Rate limit (429): show cooldown; disable resend for the duration.
- 5xx: show generic error and allow retry.

Recommended Flutter architecture & handling patterns
---------------------------------------------------
- Networking: Use `dio` for HTTP with a centralized `ApiClient`.
- API layer (Repository pattern): `AuthRepository` exposing `requestOtp(...)` and `verifyOtp(...)` methods returning typed models.
- Models / DTOs: Create mirror models for request/response (immutable data classes with `freezed`/`json_serializable`).
- Token storage: Use `flutter_secure_storage` for `accessToken` and `refreshToken`.
- HTTP interceptor: Implement an `AuthInterceptor` to automatically attach `Authorization: Bearer <accessToken>` to outgoing requests and handle 401 -> attempt refresh flow.
- Refresh flow: On 401, call the refresh token endpoint (server may have a refresh endpoint elsewhere in API); if refresh succeeds, retry original request once. If refresh fails, emit logged-out state.
- Error mapping: Map API error payloads to typed exceptions and user-friendly strings.

State management and caching
----------------------------
- Preferred: `Riverpod` or `Bloc` for predictable auth state handling.
- Auth state: `Unauthenticated`, `OtpRequested(phone, tenant)`, `VerifyingOtp`, `Authenticated(User, tokens)`, `AuthError`.
- Cache user profile: Fetch minimal user profile after verify and cache in secure local DB (e.g., `hive`) or in-memory provider. Invalidate cache on logout or token revocation.
- Token expiry: Persist `expiresAt` and schedule a silent refresh slightly before expiry (e.g., 60s before). Keep refresh attempts limited and recoverable.

Security considerations
-----------------------
- Always use HTTPS; enforce TLS certificate validation. Consider certificate pinning for high-security apps.
- Store `accessToken` and `refreshToken` in `flutter_secure_storage` (iOS Keychain / Android Keystore).
- Limit logs: never log tokens, OTPs, or PII. Be cautious with debug builds.
- Use short-lived access tokens and rotate refresh tokens if backend supports it.
- Detect and handle revoked sessions: if backend responds with an explicit revocation code, force logout and clear storage.
- Use platform biometric unlock for local convenience, but always require server tokens for API access.

Edge cases and retry behavior
----------------------------
- OTP expired: guide user to request a new OTP. Respect rate-limit headers or show cooldown.
- Invalid OTP: allow N attempts (the backend may enforce limits); after repeated invalid attempts suggest alternate verification or customer support.
- Network failures: retry with exponential backoff (e.g., 500ms, 1s, 2s) for idempotent operations like `requestOtp`; `verifyOtp` is non-idempotent from UX perspective — retry carefully and avoid duplicating successful verifications.
- Race conditions: if user requests multiple OTPs in quick succession, the latest OTP is authoritative; show the most recent request time and advise using the latest code.
- TOTP required: if backend returns an error indicating 2FA required, route user to TOTP input flow and allow backup code fallback.

Implementation Checklist (quick)
- [ ] Build `AuthRepository` with `requestOtp` and `verifyOtp` methods.
- [ ] Create typed models for request/response using `freezed` + `json_serializable`.
- [ ] Add `AuthInterceptor` attaching `Authorization` header when token present.
- [ ] Use `flutter_secure_storage` to persist tokens and expiry.
- [ ] Implement state using `Riverpod` or `Bloc` and expose auth status to the app.
- [ ] Implement retry/backoff logic and rate-limit handling for resend.
- [ ] Add unit tests for repository and integration tests for interceptor/refresh logic.

Where to look in the ShopEngine codebase
---------------------------------------
- Controller & endpoints: [src/main/java/com/ecommerce/core/modules/auth/controller/CustomerAuthController.java](src/main/java/com/ecommerce/core/modules/auth/controller/CustomerAuthController.java#L1)
- DTOs: [src/main/java/com/ecommerce/core/modules/auth/dto/CustomerOtpRequestDto.java](src/main/java/com/ecommerce/core/modules/auth/dto/CustomerOtpRequestDto.java#L1), [src/main/java/com/ecommerce/core/modules/auth/dto/CustomerOtpVerifyRequestDto.java](src/main/java/com/ecommerce/core/modules/auth/dto/CustomerOtpVerifyRequestDto.java#L1)
- Token response DTO: [src/main/java/com/ecommerce/core/modules/auth/dto/AuthTokenResponseDto.java](src/main/java/com/ecommerce/core/modules/auth/dto/AuthTokenResponseDto.java#L1)
- OTP service behaviour: [src/main/java/com/ecommerce/core/modules/auth/service/OtpAuthenticationService.java](src/main/java/com/ecommerce/core/modules/auth/service/OtpAuthenticationService.java#L1)

Contact / Notes
---------------
If you want, I can generate a Flutter `AuthRepository` stub, `freezed` models, and example `AuthNotifier`/`Bloc` wiring to jumpstart integration. Tell me which state-management approach you prefer.
