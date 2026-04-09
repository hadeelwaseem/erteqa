import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/screen_config.dart';
import '../../../data/repos/variant_repository.dart';

part 'variant_state.dart';

/// Cubit for loading and managing dynamic screen state.
///
/// **Pattern**: One VariantCubit instance per VariantScreen, keyed by pageId.
///
/// **Responsibilities**:
/// - Accept a [pageId] (variantId) on construction
/// - Load screen config from [VariantRepository] based on pageId
/// - Emit loading/success/failure states as config loads
///
/// **Design Decision**: Plain Cubit (not BaseCubit) because:
/// - Simple, focused responsibility: load a screen by pageId
/// - One-off pattern not suitable for base class abstraction yet
/// - BaseCubit is only introduced when 3+ cubits share identical behavior
///
/// **Initialization**: Automatically loads variant on construction.
/// This simplifies usage in BlocProvider:
/// ```dart
/// BlocProvider(
///   create: (_) => VariantCubit(repo, pageId)..loadVariant(),
///   child: ...,
/// )
/// ```
///
/// **States**:
/// - [VariantInitial]: Starting state
/// - [VariantLoading]: Config is being loaded
/// - [VariantSuccess]: Config loaded successfully, ready to render
/// - [VariantFailure]: Config load failed with error message
///
/// See [DYNAMIC_SCREENS_IMPLEMENTATION.md] for detailed usage guidelines.
class VariantCubit extends Cubit<VariantState> {
  /// Creates a VariantCubit with the given repository and pageId.
  ///
  /// **Parameters**:
  /// - [_repo]: Repository for loading screen configs
  /// - [_variantId]: The pageId to load (e.g., 'classic', 'dashboard')
  ///
  /// **Initialization**: Automatically calls [loadVariant] on construction.
  /// This ensures screen loading begins immediately without an explicit call.
  VariantCubit(this._repo, this._variantId) : super(VariantInitial()) {
    loadVariant();
  }

  final VariantRepository _repo;
  final String _variantId;

  /// Loads the screen config for the variant (pageId).
  ///
  /// **Flow**:
  /// 1. Emits [VariantLoading] state
  /// 2. Calls repository to load config by [_variantId]
  /// 3. On success: emits [VariantSuccess] with loaded [ScreenConfig]
  /// 4. On error: emits [VariantFailure] with error message
  ///
  /// **Why deterministic**: Same pageId always loads the same config from the same source.
  /// No factory layers or hidden resolution; just direct repository lookup.
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
