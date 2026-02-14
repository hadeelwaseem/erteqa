import 'package:sooq_merchant/features/dashboard/data/repos/dashboard_repo.dart';
import 'package:sooq_merchant/features/dashboard/domain/dashboard_data.dart';

import '../dashboard_data_provider.dart';

class DashboardRepoImpl implements DashboardRepo {
  final DashboardDataProvider _dataProvider;

  DashboardRepoImpl(this._dataProvider);

  @override
  Future<DashboardData> fetchDashboard({int? recentOrdersMaxItems}) async {
    return Future.value(
      DashboardData(
        welcomeMessage: _dataProvider.getWelcomeMessage(),
        stats: _dataProvider.getStats(),
        recentOrders: _dataProvider.getRecentOrders(
          maxItems: recentOrdersMaxItems,
        ),
        insights: _dataProvider.getInsights(),
      ),
    );
  }
}
