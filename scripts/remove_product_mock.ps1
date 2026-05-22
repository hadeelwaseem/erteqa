# Removes temporary Phase 0 mock product API. Run from repo root:
#   .\scripts\remove_product_mock.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host 'Removing lib/dev/product_mock/ ...'
if (Test-Path 'lib/dev/product_mock') {
  Remove-Item -Recurse -Force 'lib/dev/product_mock'
}

Write-Host 'Reverting service_locator.dart ...'
$sl = Get-Content 'lib/core/utils/service_locator.dart' -Raw
$sl = $sl -replace "import 'package:sooq_merchant/dev/product_mock/product_mock_config.dart';\r?\n", ''
$sl = $sl -replace "import 'package:sooq_merchant/dev/product_mock/mock_product_repo.dart';\r?\n", ''
$sl = $sl -replace "(?s)getIt\.registerLazySingleton<ProductRepo>\(\) \{\s*if \(ProductMockConfig\.enabled\) \{\s*AppLogger\.network\('ProductMockConfig.enabled=true — using MockProductRepo \(no HTTP\)'\);\s*return MockProductRepo\(\);\s*\}\s*return ProductRepoImpl\(getIt<Dio>\(\)\);\s*\}\);", @"
  getIt.registerLazySingleton<ProductRepo>(
    () => ProductRepoImpl(getIt<Dio>()),
  );"@
Set-Content 'lib/core/utils/service_locator.dart' -Value $sl -NoNewline

Write-Host 'Done. Run: flutter test'
