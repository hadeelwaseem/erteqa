import 'package:equatable/equatable.dart';

/// Query params for guest order lookup (spec §4).
class GuestOrderLookup extends Equatable {
  const GuestOrderLookup({
    required this.orderNumber,
    required this.email,
  });

  final String orderNumber;
  final String email;

  Map<String, String> toQueryParameters() => {
        'orderNumber': orderNumber,
        'email': email,
      };

  @override
  List<Object?> get props => [orderNumber, email];
}
