import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repos/dashboard_repo.dart';
import '../../../domain/dashboard_data.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo) : super(DashboardInitial());
  final DashboardRepo _repo;

  Future<void> loadDashboard({int? recentOrdersMaxItems}) async {
    emit(DashboardLoading());
    try {
      final data = await _repo.fetchDashboard(
        recentOrdersMaxItems: recentOrdersMaxItems,
      );
      emit(DashboardSuccess(data));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}
