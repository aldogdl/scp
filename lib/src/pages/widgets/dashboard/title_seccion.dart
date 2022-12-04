import 'package:flutter/material.dart';

class TitleSeccion extends StatelessWidget {

  final Widget child;
  const TitleSeccion({
    Key? key,
    required this.child
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        color: Color.fromARGB(255, 45, 92, 47)
      ),
      child: child,
    );
  }
}