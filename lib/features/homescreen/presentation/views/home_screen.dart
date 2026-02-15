// import 'package:flutter/material.dart';
// import 'variant_screen.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   void _openVariant(BuildContext context, String variantId) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (_) => VariantScreen(variantId: variantId)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Runtime UI Experiment')),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _VariantButton(
//                 label: 'Load Classic Variant',
//                 onPressed: () => _openVariant(context, 'classic'),
//               ),
//               const SizedBox(height: 16),
//               _VariantButton(
//                 label: 'Load Modern Variant',
//                 onPressed: () => _openVariant(context, 'modern'),
//               ),
//               const SizedBox(height: 16),
//               _VariantButton(
//                 label: 'Load Experimental Variant',
//                 onPressed: () => _openVariant(context, 'experimental'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _VariantButton extends StatelessWidget {
//   final String label;
//   final VoidCallback onPressed;

//   const _VariantButton({required this.label, required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       height: 48,
//       child: ElevatedButton(onPressed: onPressed, child: Text(label)),
//     );
//   }
// }
