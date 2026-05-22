# Temporary mock auth (Phase 0)

**Purpose:** Run the JSON auth flow while the OTP backend is unavailable.

## Simulated flow (same as production JSON)

1. `/auth/login` — `cubitCall` `requestOtp` → toast → `onSuccess` navigate `/auth/otp-reset`
2. `/auth/otp-reset` — `cubitCall` `verifyOtp` → save tokens → `onSuccess` navigate `/home`
3. `_AuthRequestHost` — success toast + `context.go('/home')` (duplicate until Phase 4)
4. `AuthRedirect` — logged-in users cannot stay on `/auth/*`

## Credentials (mock)

| Field | Value |
|-------|--------|
| Phone | Any valid 8–15 digits, e.g. `501234567` |
| OTP | Any 6 digits, e.g. `123456` |

## Enable / disable

`lib/dev/auth_mock/auth_mock_config.dart` → `AuthMockConfig.enabled = true|false`

## Remove completely

From repo root:

```powershell
.\scripts\remove_auth_mock.ps1
```

```bash
./scripts/remove_auth_mock.sh
```

Then hot restart and test real API login.
