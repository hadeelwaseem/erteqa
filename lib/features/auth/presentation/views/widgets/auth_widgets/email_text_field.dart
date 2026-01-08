// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';

// class EmailTextField extends StatelessWidget {
//   const EmailTextField({
//     super.key,
//   });
// // padding: EdgeInsets.only(top: 20, bottom: 30),
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.only(top: 20, bottom: 30),
//       width: MediaQuery.of(context).size.width * 0.85,
//       height: MediaQuery.of(context).size.width * 0.29,
//       child: FormBuilderTextField(
//         keyboardType: TextInputType.emailAddress,
//         name: 'email',
//         decoration: InputDecoration(
//           labelText: 'email@domain.com',

//           // labelStyle: GoogleFonts.inter(
//           //   textStyle: TextStyle(
//           //     //color: Color(0xFF17505E),
//           //     fontSize: 15,
//           //     fontWeight: FontWeight.normal,
//           //     //fontStyle: FontStyle.italic,
//           //   ),
//           // ),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Color(0xFF828282)),
//           ),
//         ),
//         validator: FormBuilderValidators.compose([
//           FormBuilderValidators.required(),
//           FormBuilderValidators.email(),
//         ]),
//       ),
//     );
//   }
// }
