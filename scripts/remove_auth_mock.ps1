# Removes temporary Phase 0 mock auth. Run from repo root:
#   .\scripts\remove_auth_mock.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host 'Removing lib/dev/auth_mock/ ...'
if (Test-Path 'lib/dev/auth_mock') {
  Remove-Item -Recurse -Force 'lib/dev/auth_mock'
}
if (Test-Path 'lib/dev') {
  $remaining = Get-ChildItem 'lib/dev' -ErrorAction SilentlyContinue
  if (-not $remaining) {
    Remove-Item -Force 'lib/dev'
  }
}

Write-Host 'Reverting service_locator.dart ...'
$sl = Get-Content 'lib/core/utils/service_locator.dart' -Raw
$sl = $sl -replace "import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';\r?\n", ''
$sl = $sl -replace "import 'package:sooq_merchant/dev/auth_mock/mock_auth_repo.dart';\r?\n", ''
$sl = $sl -replace '(?s)  getIt\.registerLazySingleton<AuthRepo>\(\(\) \{\s*if \(AuthMockConfig\.enabled\) \{\s*AppLogger\.auth\(\s*'AuthMockConfig\.enabled=true — using MockAuthRepo \(no OTP HTTP\)',\s*\);\s*return MockAuthRepo\(getIt<AuthTokenStorage>\(\)\);\s*\}\s*return AuthRepoImpl\(getIt<Dio>\(\), getIt<AuthTokenStorage>\(\)\);\s*\}\);', @'
  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(getIt<Dio>(), getIt<AuthTokenStorage>()),
  );'@
Set-Content 'lib/core/utils/service_locator.dart' -Value $sl -NoNewline

Write-Host 'Reverting main.dart ...'
$main = Get-Content 'lib/main.dart' -Raw
$main = $main -replace "import 'package:sooq_merchant/core/utils/app_logger.dart';\r?\n", ''
$main = $main -replace "import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';\r?\n", ''
$main = $main -replace "(?s)  if \(AuthMockConfig\.enabled\) \{\s*AppLogger\.auth\(\s*'TEMPORARY: Auth mock enabled — see lib/dev/auth_mock/README\.md',\s*\);\s*\}\s*", ''
Set-Content 'lib/main.dart' -Value $main -NoNewline

Write-Host 'Removing mock tests ...'
if (Test-Path 'test/dev/auth_mock') {
  Remove-Item -Recurse -Force 'test/dev/auth_mock'
}

Write-Host 'Done. Run: flutter test'
Write-Host 'Set AuthMockConfig.enabled=false was not needed — mock tree deleted.'
