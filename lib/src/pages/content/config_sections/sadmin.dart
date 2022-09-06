import 'package:flutter/material.dart';

import '../../widgets/texto.dart';

class Sadmin extends StatefulWidget {

  const Sadmin({Key? key}) : super(key: key);

  @override
  State<Sadmin> createState() => _SadminState();
}

class _SadminState extends State<Sadmin> {

  @override
  Widget build(BuildContext context) {

    return const SizedBox(
      child: Center(
        child: Texto(txt: 'SADMIN')
      ),
    );
  }
}