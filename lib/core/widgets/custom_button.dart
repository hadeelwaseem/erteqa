// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class CustomButton extends StatelessWidget {
//   const CustomButton({
//     super.key,
//     required this.onPressed,
//     required this.text,
//   });

//   final void Function() onPressed;
//   final String text;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: MediaQuery.of(context).size.width * 0.85,
//       height: 45,
//       decoration: BoxDecoration(
//           color: Color(0xFF154957), borderRadius: BorderRadius.circular(10)),
//       child: MaterialButton(
//         onPressed: onPressed,
//         // style: ElevatedButton.styleFrom(
//         //   minimumSize:  Size(300, 70),
//         // ),
//         child: Text(
//           text,
//           style: GoogleFonts.poppins(
//             textStyle: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               //fontStyle: FontStyle.italic,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
