import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final int progress;

  const ProgressBar({
    super.key,
    required this.progress,
  });

  @override
  ProgressBarState createState() => ProgressBarState();
}

class ProgressBarState extends State<ProgressBar> {
  List<double> progress = List.filled(3, 0);
  @override
  Widget build(BuildContext context) {
    progress[widget.progress] = 1;
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.all(3.0),
                child: Column(
                  children: [
                    SizedBox(
                        height: 10,
                        width: MediaQuery.of(context).size.width * .28,
                        child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress[index]),
                            duration: const Duration(seconds: 1),
                            builder: (BuildContext context, double value,
                                Widget? child) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor:
                                    const Color.fromARGB(255, 112, 111, 111),
                                // valueColor: const AlwaysStoppedAnimation<Color>(
                                //     Colors.blue

                                //  ),
                              );
                            })),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     setState(() {
                    //       progress[index] = 1;
                    //     });
                    //   },
                    //   child: Text('Step ${index + 1}'),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
