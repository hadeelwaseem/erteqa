// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'user.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class UserAdapter extends TypeAdapter<User> {
//   @override
//   final int typeId = 12;

//   @override
//   User read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return User(
//       name: fields[0] as String?,
//       email: fields[1] as String?,
//       addressId: fields[2] as String?,
//       birthDate: fields[3] as String?,
//       gender: fields[4] as String?,
//       imageId: fields[5] as String?,
//       roleId: fields[6] as int?,
//       yearId: fields[7] as String?,
//       stageId: fields[8] as int?,
//       id: fields[9] as int?,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, User obj) {
//     writer
//       ..writeByte(10)
//       ..writeByte(0)
//       ..write(obj.name)
//       ..writeByte(1)
//       ..write(obj.email)
//       ..writeByte(2)
//       ..write(obj.addressId)
//       ..writeByte(3)
//       ..write(obj.birthDate)
//       ..writeByte(4)
//       ..write(obj.gender)
//       ..writeByte(5)
//       ..write(obj.imageId)
//       ..writeByte(6)
//       ..write(obj.roleId)
//       ..writeByte(7)
//       ..write(obj.yearId)
//       ..writeByte(8)
//       ..write(obj.stageId)
//       ..writeByte(9)
//       ..write(obj.id);
//   }

//   @override
//   int get hashCode => typeId.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is UserAdapter &&
//           runtimeType == other.runtimeType &&
//           typeId == other.typeId;
// }
