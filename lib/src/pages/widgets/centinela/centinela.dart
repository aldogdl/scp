import 'package:flutter/material.dart';

import 'charts_terminal.dart';
import 'lst_prov_pzas.dart';
import 'metrix_data.dart';
import '../texto.dart';

class Centinela extends StatelessWidget {

  final Map<String, dynamic> orden;
  const Centinela({
    Key? key,
    required this.orden
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final w = MediaQuery.of(context).size.width;

    return Container(
      width: w,
      height: MediaQuery.of(context).size.height,
      color: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          _topBarr(context, w, 35),
          const Divider(height: 1, color: Colors.black),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: MetrixData(file: orden['file']),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: SizedBox.expand(
                    child: Column(
                      children: const [
                        Expanded(
                          flex: 4,
                          child: LstProvPzas()
                        ),
                        Expanded(
                          flex: 2,
                          child: ChartsTerminal()
                        )
                      ],
                    ),
                  )
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _topBarr(BuildContext context, double w, double h) {

    return Container(
      width: w, height: h,
      color: const Color.fromARGB(255, 96, 161, 98),
      child: Row(
        children: [
          _btnClose(context, h),
          const SizedBox(width: 10),
          const Icon(Icons.android, color: Colors.white),
          const SizedBox(width: 10),
          Texto(txt: '${orden['sol']}, ', txtC: Colors.white,),
          Texto(txt: 'ORDEN ID: ${orden['id']}', txtC: Colors.black, isBold: true),
          const Spacer(),
          const Texto(txt: 'CENTINELA', sz: 13, txtC: Colors.black),
          const SizedBox(width: 10),
          _btnClose(context, h)
        ],
      ),
    );
  }

  ///
  Widget _btnClose(BuildContext context, double alto) {

    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 38, height: alto,
        color: Colors.red,
        child: const Center( child: Icon(Icons.close) ),
      ),
    );
  }
}