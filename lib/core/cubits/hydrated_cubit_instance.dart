// import 'dart:convert';
// import 'dart:io';
// import 'package:hydrated_bloc/hydrated_bloc.dart';
// import 'package:path_provider/path_provider.dart';

// class HydratedCubitInstance extends Cubit<Storage?> {
//   HydratedCubitInstance() : super(null);

//   Future<void> setup() async {
//     final storage = PersistentStorage();
//     HydratedBloc.storage = await HydratedStorage.build(
//       storageDirectory: await storage.directory,
//     );
//     emit(HydratedBloc.storage);
//   }
// }

// class PersistentStorage implements Storage {
//   static final PersistentStorage _singleton = PersistentStorage._internal();

//   factory PersistentStorage() {
//     return _singleton;
//   }

//   PersistentStorage._internal();

//   Directory? _directory;

//   Future<Directory> get directory async {
//     if (_directory != null) {
//       return _directory!;
//     }
//     final dir = await getApplicationDocumentsDirectory();
//     _directory = Directory('${dir.path}/hydrated_bloc');
//     return _directory!;
//   }

//   @override
//   Future<void> clear() async {
//     final dir = await directory;

//     await dir.delete(recursive: true);
//   }

//   @override
//   Future<void> delete(String key) async {
//     final file = File('${(await directory).path}/$key');
//     if (await file.exists()) {
//       await file.delete();
//     }
//   }

//   @override
//   Future<Map<String, dynamic>?> read(String key) async {
//     final file = File('${(await directory).path}/$key');
//     if (await file.exists()) {
//       return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
//     }
//     return null;
//   }

//   @override
//   Future<void> write(String key, dynamic value) async {
//     final file = File('${(await directory).path}/$key');
//     if (!await file.parent.exists()) {
//       await file.parent.create(recursive: true);
//     }
//     await file.writeAsString(jsonEncode(value));
//   }

//   @override
//   Future<void> close() {
//     throw UnimplementedError();
//   }
// }
