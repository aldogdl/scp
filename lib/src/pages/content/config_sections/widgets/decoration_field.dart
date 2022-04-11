import 'package:flutter/material.dart';

class DecorationField {

  ///
  static InputDecoration get({
    required String help,
    required IconData iconoPre,
    bool isPass = false,
    Widget? showHidden
  }) {

    return InputDecoration(
      suffixIcon: (!isPass)
      ? null
      : Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: showHidden ?? const SizedBox()
      ),
      hintText: help,
      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 88, 88, 88)
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1
        ),
      ),
      prefixIcon: Icon(iconoPre, size: 15, color: Colors.white.withOpacity(0.2)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1
        ),
      ),
      errorStyle: const TextStyle(
        color: Color.fromARGB(255, 255, 244, 149)
      ),
      helperText: help
    );
  }
}