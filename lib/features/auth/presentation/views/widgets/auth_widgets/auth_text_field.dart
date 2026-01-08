// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class AuthTextField extends StatelessWidget {
//   const AuthTextField({
//     super.key,
//     required this.validator,
//     required this.onSave,
//     required this.formatter,
//     required this.hintText,
//     required this.textInputType,
//     this.obscureText = false,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.onTap,
//   });

//   final String? Function(String? p1)? validator;
//   final void Function(String? p1)? onSave;
//   final List<TextInputFormatter>? formatter;
//   final String hintText;
//   final TextInputType textInputType;
//   final bool obscureText;
// final  void Function()? onTap;

//   final Widget? prefixIcon;
//   final Widget? suffixIcon;
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       onTap: onTap,
//       obscureText: obscureText,
//       validator: validator,
//       onSaved: onSave,
//       keyboardType: textInputType,
//       inputFormatters: formatter,
//       decoration: InputDecoration(
//         hintText: hintText,
//         // hintStyle: TextStyle(color: Colors.black),
//         prefixIcon: prefixIcon,
//         suffixIcon: suffixIcon,
//         disabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(100),
//           //  borderSide: const BorderSide(width: 1),
//           borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
//         ),
//       ),
//     );
//   }
// }
