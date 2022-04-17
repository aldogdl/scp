import 'package:flutter/material.dart';

import 'texto.dart';

class LoadingMiddle extends StatelessWidget {

  final String msg;
  const LoadingMiddle({
    Key? key,
    required this.msg
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Texto(txt: 'Recuperando $msg', sz: 12, txtC: Colors.amber),
          )
        ],
      ),
    );
  }
}