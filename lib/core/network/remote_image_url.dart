import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

/// HTTP headers for images served from the merchant API / upload host only.
const Map<String, String> kRemoteImageHttpHeaders = {
  'Accept': 'image/avif,image/webp,image/*,*/*;q=0.8',
  'User-Agent': 'SOOQMerchant/1.0 (Flutter; Mobile)',
};

/// Headers for catalog image downloads, or null to use the platform default client.
///
/// Third-party mock CDNs (e.g. placehold.co) should use null — custom user agents
/// are unnecessary and can trigger blocks on some hosts.
Map<String, String>? httpHeadersForImageUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  if (_isMerchantAssetHost(uri.host)) {
    return kRemoteImageHttpHeaders;
  }
  return null;
}

bool _isMerchantAssetHost(String host) {
  final normalized = host.toLowerCase();
  for (final candidate in _merchantAssetHosts()) {
    if (normalized == candidate) return true;
  }
  return false;
}

Iterable<String> _merchantAssetHosts() sync* {
  if (GetIt.I.isRegistered<NetworkConfig>()) {
    final fromConfig = Uri.tryParse(GetIt.I<NetworkConfig>().assetBaseUrl)?.host;
    if (fromConfig != null && fromConfig.isNotEmpty) {
      yield fromConfig.toLowerCase();
    }
  }
  final fromFallback = Uri.tryParse(kBaseUrlAsset)?.host;
  if (fromFallback != null && fromFallback.isNotEmpty) {
    yield fromFallback.toLowerCase();
  }
}

/// Resolves a catalog image URL for [Image.network] / [CachedNetworkImage].
///
/// - Absolute `http`/`https` URLs pass through unchanged.
/// - Root-relative paths (`/uploads/...`) prefix [NetworkConfig.assetBaseUrl].
String resolveRemoteImageUrl(String url) {
  final value = url.trim();
  if (value.isEmpty) {
    return '';
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('/')) {
    final assetBase = GetIt.I.isRegistered<NetworkConfig>()
        ? GetIt.I<NetworkConfig>().assetBaseUrl
        : kBaseUrlAsset;
    return '$assetBase$value';
  }
  return value;
}

/// Generated thumbnail suffixes the API may reference when the file was never created.
final RegExp kGeneratedThumbnailSuffix = RegExp(
  r'_(150|300|600)\.png$',
  caseSensitive: false,
);

/// If [url] ends with `_150.png`, `_300.png`, or `_600.png`, returns the `.jpg` full-size URL.
///
/// Returns null when [url] is empty or does not match a generated thumbnail pattern.
String? fullSizeFallbackForGeneratedThumbnail(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final match = kGeneratedThumbnailSuffix.firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  final fallback = '${trimmed.substring(0, match.start)}.jpg';
  return fallback == trimmed ? null : fallback;
}
