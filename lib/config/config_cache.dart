import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'bootstrap_config.dart';

/// Persists validated raw config JSON to app documents (one file per merchant).
class ConfigCache {
  final Future<Directory> Function() _directoryProvider;

  ConfigCache({Future<Directory> Function()? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;

  static const _cacheSubdir = 'sooq/mobile-config';

  Future<String?> read(BootstrapConfig bootstrap) async {
    final file = await _fileFor(bootstrap);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  Future<void> write(BootstrapConfig bootstrap, String rawJson) async {
    final file = await _fileFor(bootstrap);
    await file.parent.create(recursive: true);
    await file.writeAsString(rawJson);
  }

  Future<void> delete(BootstrapConfig bootstrap) async {
    final file = await _fileFor(bootstrap);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _fileFor(BootstrapConfig bootstrap) async {
    final base = await _directoryProvider();
    // tenantSlug preferred; variantId fallback when slug is absent.
    final slug = bootstrap.tenantSlug ?? bootstrap.variantId;
    return File('${base.path}/$_cacheSubdir/$slug.json');
  }
}
