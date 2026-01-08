part of 'index_address_year_cubit.dart';

sealed class IndexAddressYearState extends Equatable {
  const IndexAddressYearState();

  @override
  List<Object> get props => [];
}

final class IndexAddressYearInitial extends IndexAddressYearState {}

final class IndexAddressYearLoading extends IndexAddressYearState {}

final class IndexAddressYearFailure extends IndexAddressYearState {
  final String errMessage;
  const IndexAddressYearFailure({required this.errMessage});
}

final class IndexAddressYearSuccess extends IndexAddressYearState {
  final IndexAddressYears indexAddressYears;
  const IndexAddressYearSuccess(this.indexAddressYears);
}
