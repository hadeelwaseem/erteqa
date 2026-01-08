import 'package:flutter/widgets.dart';

class TypingText extends StatefulWidget {
  final String text;

  const TypingText({super.key, required this.text});

  @override
  TypingTextState createState() => TypingTextState();
}

class TypingTextState extends State<TypingText>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<int> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    animation = StepTween(begin: 0, end: widget.text.length)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        String text = widget.text.substring(0, animation.value);
        return Text('Welcome to ScholarSphere',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 40));
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
