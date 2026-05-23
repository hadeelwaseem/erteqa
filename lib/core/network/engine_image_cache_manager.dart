import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// Shared disk cache for [EngineNetworkImage] using dart:io HTTP (redirect-friendly).
class EngineImageCacheManager {
  EngineImageCacheManager._();

  static const _cacheKey = 'engineImageCache';

  static CacheManager? _instance;

  static CacheManager get instance {
    return _instance ??= CacheManager(
      Config(
        _cacheKey,
        fileService: HttpFileService(httpClient: IOClient()),
      ),
    );
  }
}
