import 'package:flutter/material.dart';

class SinData extends StatelessWidget {

  final IconData icono;
  final double opacity;
  const SinData({
    required this.icono,
    this.opacity = 0.5,
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Icon(
        icono, size: 150,
        color: Colors.black.withOpacity(opacity)
      ),
    );
  }

}