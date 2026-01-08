// import 'package:equatable/equatable.dart';
// import 'package:hive/hive.dart';

// part 'user.g.dart';

// @HiveType(typeId: 12)
// class User extends Equatable {
//   @HiveField(0)
//   final String? name;
//   @HiveField(1)
//   final String? email;
//   @HiveField(2)
//   final String? addressId;
//   @HiveField(3)
//   final String? birthDate;
//   @HiveField(4)
//   final String? gender;
//   @HiveField(5)
//   final String? imageId;
//   @HiveField(6)
//   final int? roleId;
//   @HiveField(7)
//   final String? yearId;
//   @HiveField(8)
//   final int? stageId;
//   @HiveField(9)
//   final int? id;

//   const User({
//     this.name,
//     this.email,
//     this.addressId,
//     this.birthDate,
//     this.gender,
//     this.imageId,
//     this.roleId,
//     this.yearId,
//     this.stageId,
//     this.id,
//   });

//   factory User.fromJson(Map<String, dynamic> json) => User(
//         name: json['name'] as String?,
//         email: json['email'] as String?,
//         addressId: (json['address_id'] as dynamic).toString(),
//         birthDate: json['birth_date'] as String?,
//         gender: (json['gender'] as dynamic).toString(),
//         imageId: (json['image_id'] as dynamic).toString(),
//         roleId: json['role_id'] as int?,
//         yearId: (json['year_id'] as dynamic).toString(),
//         stageId: json['stage_id'] as int?,
//         id: json['id'] as int?,
//       );

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'email': email,
//         'address_id': addressId,
//         'birth_date': birthDate,
//         'gender': gender,
//         'image_id': imageId,
//         'role_id': roleId,
//         'year_id': yearId,
//         'stage_id': stageId,
//         'id': id,
//       };

//   @override
//   List<Object?> get props {
//     return [
//       name,
//       email,
//       addressId,
//       birthDate,
//       gender,
//       imageId,
//       roleId,
//       yearId,
//       stageId,
//       id,
//     ];
//   }
// }
