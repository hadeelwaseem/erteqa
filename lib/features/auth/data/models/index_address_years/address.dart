import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final int? id;
  final String? address;

  const Address({this.id, this.address});

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as int?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
      };

  @override
  List<Object?> get props => [id, address];
}
