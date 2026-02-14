import 'package:flutter/material.dart';
/*
'text':{'text':'hello','color':'red','fontSize':18,'fontWeight':w600,'fontStyle':normal}

*/

class TextComponent extends StatelessWidget {
  final String text;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  //TODO
  //google fonts (font family should be added)
  const TextComponent({
    super.key,
    required this.text,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? 18,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: textColor,
        fontStyle: fontStyle ?? FontStyle.normal,
      ),
    );
  }
}
