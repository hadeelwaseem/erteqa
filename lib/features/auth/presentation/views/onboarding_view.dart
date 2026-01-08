import 'package:flutter/material.dart';
import 'package:sooq_merchant/features/auth/presentation/views/widgets/auth.dart';
import 'package:sooq_merchant/features/auth/presentation/views/widgets/welcome.dart';

class OnBoaringView extends StatefulWidget {
  // final String? deviceToken;
  const OnBoaringView({super.key});

  @override
  State<OnBoaringView> createState() => _OnBoaringViewState();
}

class _OnBoaringViewState extends State<OnBoaringView> {
  int bodyIndex = 0;
  final PageController _controller = PageController();
  bool failedToLog = false;
  bool isGuest = false;
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> body = [
      WelcomeBody(
        onButtonPressed: () {
          _controller.animateToPage(
            1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
          setState(() {
            bodyIndex = 1;
          });
        },
      ),
      AuthBody(
        guestState: (state) {
          isGuest = state;
        },
        // deviceToken: widget.deviceToken!,
        onButtonPressed: () {
          setState(() {
            // if (!failedToLog) {
            bodyIndex = 2;
            _controller.animateToPage(
              2,
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            );
            // }
          });
        },
        // failedToLogState: (bool state) {
        //   failedToLog = state;
        // },
        // failedToLog: failedToLog,
      ),
      // PickSpecificationBody(
      //   isGuest: isGuest,
      //   guestActions: () {
      //     setState(() {
      //       if (isGuest) {
      //         bodyIndex = 1;
      //         _controller.animateToPage(1,
      //             duration: const Duration(milliseconds: 500),
      //             curve: Curves.ease);
      //       }
      //       isGuest = false;
      //     });
      //   },
      // )
    ];
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ProgressBar(
            //progress: bodyIndex,
            //),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
