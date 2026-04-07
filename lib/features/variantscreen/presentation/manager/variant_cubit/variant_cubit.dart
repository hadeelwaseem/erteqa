import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/genericConfig/screen_config.dart';
import '../../../data/repos/variant_repository.dart';

part 'variant_state.dart';

class VariantCubit extends Cubit<VariantState> {
  VariantCubit(this._repo, this._variantId) : super(VariantInitial()) {
    loadVariant();
  }

  final VariantRepository _repo;
  final String _variantId;

  Future<void> loadVariant() async {
    emit(VariantLoading());
    try {
      final config = await _repo.loadVariant(_variantId);
      emit(VariantSuccess(config));
    } catch (e) {
      emit(VariantFailure(e.toString()));
    }
  }
}
