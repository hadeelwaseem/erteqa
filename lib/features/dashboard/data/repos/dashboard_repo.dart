import '../../domain/dashboard_data.dart';

abstract class DashboardRepo {
  Future<DashboardData> fetchDashboard({int? recentOrdersMaxItems});
}
