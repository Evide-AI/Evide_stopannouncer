import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.onTap, required this.text, required this.boxDecoration, required this.height, required this.width, required this.textStyle, });
  final VoidCallback onTap;
final String text;
final BoxDecoration boxDecoration;
final double height;
final double width;
final TextStyle textStyle;



  @override

  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
decoration:boxDecoration,
child: Center(child: Text(text,style: textStyle,)),
      ),
    );

  }
}