import 'package:flutter/material.dart';

class ActionShowActionMain {

  ///
  static Future<void> showActionsMain(BuildContext context) async {
    
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        content: Text('hola'),
      )
    );
  }
}