// ignore: file_names

import 'package:evide_dashboard/Application/Core/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextformWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hinttext;
  final String labelText;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final String? prefixText;
  // ignore: non_constant_identifier_names
  final List<TextInputFormatter>? InputFormatter;
  const CustomTextformWidget({
    super.key,
    required this.controller,
    required this.hinttext,
    required this.labelText,
    required this.keyboardType,
    required this.isPassword,
    required this.validator,
    this.prefixText,
    this.InputFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: texColor),
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixText: prefixText ?? '',
      ),
      inputFormatters: InputFormatter ?? [],
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}

class CustomFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    if (text.length > 0) {
      if (text.length <= 2) {
        return TextEditingValue(
          text: text.toUpperCase(),
          selection: newValue.selection,
        );
      } else {
        return TextEditingValue(
          text: '${text.substring(0, 2).toUpperCase()}${text.substring(2)}',
          selection: newValue.selection,
        );
      }
    }
    return newValue;
  }
}
