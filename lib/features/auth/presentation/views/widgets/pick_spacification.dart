// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lms_student/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
// import 'package:lms_student/core/utils/app_router.dart';
// import 'package:lms_student/core/widgets/custom_error.dart';
// import 'package:lms_student/core/widgets/custom_loading.dart';
// import 'package:lms_student/features/auth/presentation/manager/grades_cubit/grades_cubit.dart';

// import 'option_card.dart';

// class PickSpecificationBody extends StatefulWidget {
//   final VoidCallback guestActions;
//   final bool isGuest;
//   const PickSpecificationBody({super.key, required this.guestActions, required this.isGuest});

//   @override
//   PickSpecificationBodyState createState() => PickSpecificationBodyState();
// }

// class PickSpecificationBodyState extends State<PickSpecificationBody> {
//   int _selectedOption = 0;

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<GradesCubit, GradesState>(builder: (context, state) {
//       if (state is GradesLoading) {
//         return const CustomLoading();
//       }
//       if (state is GradesFailure) {
//         return CustomError(errMessage: state.errMessage);
//       }
//       if (state is GradesSuccess) {
//         return ListView(
//           physics: const BouncingScrollPhysics(),
//           children: <Widget>[
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text(
//                 'قم بإختيار فرعك',
//                 style: TextStyle(fontSize: 40),
//               ),
//             ),
//             const SizedBox(
//               height: 80,
//             ),

//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: state.grades.data!.length,
//               itemBuilder: (context, index) {
//                 return OptionCard(
//                   index: index,
//                   selectedOption: _selectedOption,
//                   optionText: state.grades.data![index].name!,
//                   onOptionSelected: (index) {
//                     setState(() {
//                       _selectedOption = index;
//                     });
//                   },
//                 );
//               },
//             ),
//             const SizedBox(
//               height: 80,
//             ),
//             // Spacer(),
//             Padding(
//               padding: const EdgeInsets.all(50.0),
//               child: SizedBox(
//                 height: 60,
//                 child: ElevatedButton(
//                     onPressed: () {
//                       if (widget.isGuest) {
//                         widget.guestActions();
//                         context.push(AppRouter.kHomeView,
//                             extra: (_selectedOption + 1).toString());
//                         return;
//                       }
//                       BlocProvider.of<SharedPreferencesCubit>(context)
//                           .setGrade((_selectedOption + 1).toString());

//                       context.pushReplacement(AppRouter.kHomeView,
//                           extra: (_selectedOption + 1).toString());
//                     },
//                     child: const Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.check),
//                         Text(
//                           'تأكيد',
//                           style: TextStyle(
//                             fontSize: 20,
//                           ),
//                         ),
//                       ],
//                     )),
//               ),
//             ),
//           ],
//         );
//       }
//       return Container();
//     });
//   }
// }
