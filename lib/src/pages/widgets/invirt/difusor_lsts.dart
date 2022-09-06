import 'package:flutter/material.dart';

class DifusorLsts extends StatelessWidget {

  final Widget child;
  final double altura;
  const DifusorLsts({
    Key? key,
    required this.child,
    this.altura = 15,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: altura,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 37, 37, 38).withOpacity(0.5),
                  const Color.fromARGB(255, 37, 37, 38)
                ],
                begin: Alignment.topCenter ,
                end: Alignment.bottomCenter,
              )
            ),
          )
        )
      ],
    );
  }
}