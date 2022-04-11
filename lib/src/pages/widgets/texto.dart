import 'package:flutter/material.dart';

class Texto extends StatelessWidget {

  final String txt;
  final double sz;
  final Color txtC;
  final bool isBold;
  const Texto({
    required this.txt,
    this.sz = 14.0,
    this.txtC = const Color.fromARGB(255, 158, 158, 158),
    this.isBold = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Text(
      txt,
      textScaleFactor: 1,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: sz,
        color: txtC,
        fontWeight: (isBold) ? FontWeight.bold : FontWeight.normal
      ),
    );
  }
}