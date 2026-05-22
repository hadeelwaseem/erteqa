#!/usr/bin/env bash
# Removes temporary Phase 0 mock auth. Run from repo root:
#   chmod +x scripts/remove_auth_mock.sh && ./scripts/remove_auth_mock.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo 'Removing lib/dev/auth_mock/ ...'
rm -rf lib/dev/auth_mock
rmdir lib/dev 2>/dev/null || true

echo 'Reverting service_locator.dart and main.dart ...'
python3 << 'PY'
from pathlib import Path
import re

sl = Path('lib/core/utils/service_locator.dart').read_text(encoding='utf-8')
sl = re.sub(r"import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';\n", '', sl)
sl = re.sub(r"import 'package:sooq_merchant/dev/auth_mock/mock_auth_repo.dart';\n", '', sl)
sl = re.sub(
    r"  getIt\.registerLazySingleton<AuthRepo>\(\(\) \{.*?  \}\);",
    """  getIt.registerLazySingleton<AuthRepo>(
    () => AuthRepoImpl(getIt<Dio>(), getIt<AuthTokenStorage>()),
  );""",
    sl,
    count=1,
    flags=re.DOTALL,
)
Path('lib/core/utils/service_locator.dart').write_text(sl, encoding='utf-8')

main = Path('lib/main.dart').read_text(encoding='utf-8')
main = re.sub(r"import 'package:sooq_merchant/core/utils/app_logger.dart';\n", '', main)
main = re.sub(r"import 'package:sooq_merchant/dev/auth_mock/auth_mock_config.dart';\n", '', main)
main = re.sub(
    r"  if \(AuthMockConfig\.enabled\) \{.*?\}\n",
    '',
    main,
    count=1,
    flags=re.DOTALL,
)
Path('lib/main.dart').write_text(main, encoding='utf-8')
PY

rm -rf test/dev/auth_mock

echo 'Done. Run: flutter test'
