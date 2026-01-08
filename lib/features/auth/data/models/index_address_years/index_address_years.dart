import 'package:equatable/equatable.dart';

import 'address.dart';
import 'year.dart';

class IndexAddressYears extends Equatable {
  final List<Year>? years;
  final List<Address>? addresses;

  const IndexAddressYears({this.years, this.addresses});

  factory IndexAddressYears.fromJson(Map<String, dynamic> json) {
    return IndexAddressYears(
      years: (json['years'] as List<dynamic>?)
          ?.map((e) => Year.fromJson(e as Map<String, dynamic>))
          .toList(),
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'years': years?.map((e) => e.toJson()).toList(),
        'addresses': addresses?.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [years, addresses];
}
