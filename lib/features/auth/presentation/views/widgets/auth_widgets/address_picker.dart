// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';
// import 'package:lms_student/features/auth/data/models/index_address_years/address.dart';

// class AddressPicker extends StatelessWidget {
//   final List<Address> addresses;
//   const AddressPicker({
//     super.key,
//     required this.addresses,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return

//         //   DropdownButtonHideUnderline(
//         //   child: DropdownButton2<String>(
//         //     value: addresses[0].id.toString(),
//         //     isExpanded: true,
//         //     hint: const Row(
//         //       children: [
//         //         // Icon(
//         //         //   Icons.list,
//         //         //   size: 16,
//         //         //   color: Colors.yellow,
//         //         // ),
//         //         // SizedBox(
//         //         //   width: 4,
//         //         // ),
//         //         Expanded(
//         //           child: Text(
//         //             'Select Item',
//         //             style: TextStyle(
//         //               fontSize: 14,
//         //               fontWeight: FontWeight.bold,
//         //               //color: Colors.yellow,
//         //             ),
//         //             overflow: TextOverflow.ellipsis,
//         //           ),
//         //         ),
//         //       ],
//         //     ),
//         //     onChanged: (){},
//         //
//         //     //FormBuilderValidators.compose([FormBuilderValidators.required()]),
//         //
//         //
//         //     items: addresses
//         //         .map((address) => DropdownMenuItem(
//         //       alignment: AlignmentDirectional.center,
//         //       value: address.id.toString(),
//         //       child: Text(address.address!),
//         //     ))
//         //         .toList(),
//         //
//         //
//         //     //valueTransformer: (val) => val?.toString(),
//         //   ),
//         // );

//         Container(
//       margin: EdgeInsets.only(bottom: 10),
//       width: MediaQuery.of(context).size.width * 0.85,
//       height: MediaQuery.of(context).size.height * 0.10,
//       child: FormBuilderDropdown<String>(
//         name: 'address',
//         decoration: InputDecoration(
//           labelText: 'address',
//           hintText: 'choose an address',
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide(color: Color(0xFF828282)),
//           ),
//         ),
//         validator:
//             FormBuilderValidators.compose([FormBuilderValidators.required()]),
//         items: addresses
//             .map((address) => DropdownMenuItem(
//                   alignment: AlignmentDirectional.center,
//                   value: address.id.toString(),
//                   child: Text(address.address!),
//                 ))
//             .toList(),
//         valueTransformer: (val) => val?.toString(),
//       ),
//     );
//   }
// }
