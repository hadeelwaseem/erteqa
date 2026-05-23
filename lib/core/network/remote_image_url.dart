import 'package:get_it/get_it.dart';
import 'package:sooq_merchant/core/network/network_config.dart';
import 'package:sooq_merchant/core/utils/constants.dart';

/// HTTP headers for remote image CDNs (Unsplash, picsum, Railway assets).
const Map<String, String> kRemoteImageHttpHeaders = {
  'Accept': 'image/avif,image/webp,image/apif,image/*,*/*;q=0.8',
  'User-Agent': 'SOOQMerchant/1.0 (Flutter; Mobile)',
};

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
