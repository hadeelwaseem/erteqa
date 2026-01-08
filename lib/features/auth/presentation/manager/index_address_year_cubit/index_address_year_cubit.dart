import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sooq_merchant/features/auth/data/models/index_address_years/index_address_years.dart';
import 'package:sooq_merchant/features/auth/data/repos/auth_repo.dart';

part 'index_address_year_state.dart';

class IndexAddressYearCubit extends Cubit<IndexAddressYearState> {
  final AuthRepo authRepo;
  IndexAddressYearCubit(this.authRepo) : super(IndexAddressYearInitial());

  // Future<void> fetchAuthData() async {
  //   emit(IndexAddressYearLoading());
  //   final result = await authRepo.fetchAuthData();
  //   result.fold(
  //       (failure) =>
  //           emit(IndexAddressYearFailure(errMessage: failure.errMessage)),
  //       (indexAddressYear) => emit(IndexAddressYearSuccess(indexAddressYear)));
  // }
}
