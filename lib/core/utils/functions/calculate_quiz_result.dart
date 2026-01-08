// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lms_student/core/utils/app_router.dart';
// import 'package:lms_student/features/subject_data/data/models/quizzes_model/answer.dart';

// Future<void> calulateAndPush(
//     {required BuildContext context,
//     required List<Answer?> answers,
//     required int totalMark,
//     required List<Answer?> correctAnswers,
//     required void Function(bool) showCorrect}) async {
//   // int mark = 0;
//   double userMark = 0;
//   // int points = 0;
//   // double userPoints = 0;
//   for (int i = 0; i < answers.length; i++) {
//     //Video ,List<Answwwer?>,void Function(void Function()) setState
//     if (answers[i] is MCQAnswer) {
//       if ((correctAnswers[i] as MCQAnswer).selectedOption ==
//           (answers[i] as MCQAnswer).selectedOption) {
//         userMark += totalMark / answers.length;
//       }
//     }
//   }

//   bool? value = await context.push<bool>(AppRouter.kQuizResults, extra: {
//     'fullMark': totalMark,
//     // 'fullPoints': points,
//     'userMarks': userMark.round(),
//     // 'userPoints': userPoints.round(),
//   });
//   if (value == true) {
//     showCorrect(value!);
//   }
// }
