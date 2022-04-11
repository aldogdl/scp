import 'package:flutter/material.dart';

import '../../widgets/texto.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Texto(txt: 'HOME')),
    );
  }
}