# Customer OTP Auth

This module owns the customer OTP auth flow.

Usage:
- Call `AuthCubit.requestOtp(...)` with `phone` plus either `tenantId` or `tenantSlug`.
- Call `AuthCubit.verifyOtp(...)` with `phone`, `otpCode`, and the same tenant selector.
- On success, the repository stores `accessToken` and `refreshToken` in `flutter_secure_storage`.
- The `AuthInterceptor` attaches `Authorization: Bearer <accessToken>` automatically on later requests.

Assumptions:
- OTP request and verify follow the endpoints documented in `CustomerAuthFlutterGuide.md`.
- Refresh retry uses `POST /api/v1/customer/auth/refresh` as the current best-effort assumption.
- If refresh fails or the endpoint is unavailable, stored auth tokens are cleared and the app is treated as logged out.

Validation rules:
- `phone`: `^[0-9+]{8,15}$`
- `otpCode`: exactly 6 digits
- `totpCode`: optional, exactly 6 digits when present# Auth Feature Guide

Last updated: 2026-05-14

This file documents the customer-only authentication flow used by the Flutter app.
It is written as a feature guide for the auth folder, so the repository, cubit, and UI can stay small and self-contained.

The current backend evidence shows an OTP-based flow with two public endpoints:

- request OTP
- verify OTP

Use this guide when wiring the auth repository, cubit, and onboarding UI.

## 0. What To Keep In Mind

Use the following practical rules when implementing this feature in Flutter:

- Keep customer auth isolated from merchant/admin flows.
- Keep API transport code out of widgets.
- Keep request bodies minimal and omit fields that are not required.
- Treat the OTP flow as a short state machine: request, verify, persist session, continue.
- Do not add slug unless the backend explicitly requires tenant context for a non-default path.

## 1. Scope

This guide is for customer authentication only.

Do not mix these endpoints with merchant admin auth or store setup.
For the customer flow, the app should keep the request small, predictable, and easy to retry.

## 2. Customer Auth Endpoints

### 2.1 Request OTP

- Method: `POST`
- Path: `/api/v1/auth/otp/request`
- Auth: public
- Purpose: ask the backend to send an OTP to the customer phone number

#### Request body

```json
{
  "phone": "+9639xxxxxxxx",
  "fullName": "Optional display name"
}
```

#### Notes

- `phone` is the only required field.
- `fullName` is optional and should only be sent if the backend needs it for first-time customer registration.
- For a clean Flutter implementation, keep the request DTO minimal and omit null fields.

### 2.2 Verify OTP

- Method: `POST`
- Path: `/api/v1/auth/otp/verify`
- Auth: public
- Purpose: verify the OTP and receive the authenticated customer session

#### Request body

```json
{
  "phone": "+9639xxxxxxxx",
  "code": "123456"
}
```

#### Notes

- Send the same phone number used in the OTP request.
- The verification code should be treated as a short-lived, user-entered value.
- After success, persist the returned token or session data in a secure storage layer.

## 3. When To Pass Slug

For the customer-only auth flow, do not send slug by default.

Slug is relevant when the backend needs tenant context for a returning merchant or a store-scoped flow.
That is separate from the customer OTP flow.

Use this rule in Flutter:

- Customer first-time sign-in: send only the phone number.
- Customer OTP verify: send phone and code only.
- Only add tenant slug if the backend explicitly requires tenant context for a special returning-user path.

## 4. Recommended Flutter Layering

Keep auth code in the same feature structure used elsewhere in the app:

- `data/models/`
- `data/repos/`
- `presentation/manager/`
- `presentation/views/`

If you already have a shared API client, inject it into the auth repository instead of creating another client inside the widget tree.

### 4.1 Data models

Create small DTOs for each request and response.

Recommended request models:

- `OtpRequestModel`
- `OtpVerifyRequestModel`

Recommended response models:

- `OtpRequestResponseModel`
- `OtpVerifyResponseModel`

Keep parsing isolated in models so widgets never touch raw JSON.

### 4.2 Repository

The repository should own all transport details:

- endpoint path
- HTTP method
- header construction
- body serialization
- error mapping

Keep the endpoint URLs in a single place so future auth changes stay easy to update.

Recommended repository methods:

- `requestOtp({required String phone, String? fullName})`
- `verifyOtp({required String phone, required String code})`

### 4.3 Cubit

The cubit should only orchestrate state.

Suggested states:

- `AuthInitial`
- `AuthLoading`
- `AuthOtpRequested`
- `AuthVerified`
- `AuthFailure`

Suggested behavior:

- emit loading before request
- emit success after OTP request or verify
- emit failure with readable message when the backend rejects the input

### 4.4 UI

Keep the UI simple and linear:

1. Ask for phone number.
2. Submit OTP request.
3. Ask for OTP code.
4. Submit verification.
5. Store auth result and move into the app.

Do not keep request logic inside widgets.

## 5. Request Handling Rules For Flutter

### 5.1 Validation

- Validate the phone before sending the request.
- Validate OTP length before verify.
- Keep local validation messages short and specific.
- Prevent duplicate submits while a request is in flight.

### 5.2 Networking

- Use a single API client instance.
- Keep the auth endpoints in one repository file.
- Build request URLs in one place.
- Avoid repeated string concatenation in widgets.

### 5.3 Storage

After verify success, persist only what the app needs:

- access token or session token
- customer identifier if returned
- optional profile metadata

Use secure storage for sensitive values.

Keep any cached auth state simple enough to restore the session on app start without repeating the OTP flow.

### 5.4 Errors

Handle these cases explicitly:

- invalid phone number
- OTP request failed
- wrong OTP code
- expired OTP
- network timeout
- server 5xx error

Show a user-friendly message and keep technical details in logs only.

## 6. Clean Implementation Guidelines

- Keep request models immutable.
- Keep repository methods focused on one endpoint each.
- Keep cubit methods thin and predictable.
- Reuse a single loading state instead of many ad hoc flags.
- Use secure storage for auth state, not widget memory.
- Prefer typed response parsing over raw `Map<String, dynamic>` in the UI layer.

## 7. Minimal Flow Summary

The customer auth flow is:

1. `POST /api/v1/auth/otp/request`
2. `POST /api/v1/auth/otp/verify`
3. Store the returned session
4. Continue into the app

That is the full customer auth path that the Flutter app should depend on.

## 8. What This File Deliberately Excludes

This guide intentionally leaves out backend-only items such as seed data, Swagger annotations, Postman collections, and plan tracking.
Those belong in backend documentation and release workflow, not in the Flutter auth feature guide.
