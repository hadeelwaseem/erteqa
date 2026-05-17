import 'package:flutter_test/flutter_test.dart';
import 'package:sooq_merchant/engine/tree/parsers/data_context_path.dart';

void main() {
  test('resolveDataContextPath reads nested request data with prefix', () {
    final root = <String, dynamic>{
      'requests': {
        'category-detail': {
          'data': {'name': 'ملابس'},
        },
      },
    };

    expect(
      resolveDataContextPath(
        root,
        'dataContext.requests.category-detail.data.name',
      ),
      'ملابس',
    );
  });

  test('resolveDataContextPath reads paths without prefix', () {
    final root = <String, dynamic>{
      'requests': {
        'product-detail': {
          'data': {'displayPrice': '50,000.00 SYP'},
        },
      },
    };

    expect(
      resolveDataContextPath(root, 'requests.product-detail.data.displayPrice'),
      '50,000.00 SYP',
    );
  });
}
