import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import '../../providers/window_cnf_provider.dart';

class WindowButtons extends StatelessWidget {

  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final winCnf = context.read<WindowCnfProvider>();

    return Row(
      children: [
        MinimizeWindowButton(colors: winCnf.buttonColors),
        MaximizeWindowButton(colors: winCnf.buttonColors),
        CloseWindowButton(colors: winCnf.closeButtonColors),
      ],
    );
  }
}