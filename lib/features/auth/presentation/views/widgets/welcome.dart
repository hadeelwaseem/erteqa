import 'package:flutter/material.dart';
import 'package:sooq_merchant/core/animations/text_typing.dart';

class WelcomeBody extends StatelessWidget {
  final VoidCallback onButtonPressed;

  const WelcomeBody({super.key, required this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(top: 150.0),
        //   child: Center(
        //     child: CircleAvatar(
        //       backgroundColor: Colors.transparent,
        //       radius: MediaQuery.of(context).size.width / 5,
        //       backgroundImage: const AssetImage(AssetsData.logoIcon),
        //     ),
        //   ),
        // ),
        const SizedBox(height: 20),
        // const Padding(
        //   padding: EdgeInsets.all(8.0),
        //   child: TypingText(text: 'مرحبا بك في مدرسة المدرسة الالكترونية  '),
        // ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: SizedBox(
            height: 80,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_rounded),
                  SizedBox(width: 25),
                  Text('Next', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
