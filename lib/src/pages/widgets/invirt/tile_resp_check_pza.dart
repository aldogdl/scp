import 'package:flutter/material.dart';

import '../texto.dart';

class TileRespCheckPza extends StatefulWidget {

  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onCheck;
  const TileRespCheckPza({
    Key? key,
    required this.data,
    required this.onCheck,
  }) : super(key: key);

  @override
  State<TileRespCheckPza> createState() => _TileRespCheckPzaState();
}

class _TileRespCheckPzaState extends State<TileRespCheckPza> {

  bool _isCheck = false;
  
  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        SizedBox(
          width: 10, height: 10,
          child: Transform.scale(
            scale: 0.7,
            child: Checkbox(
              value: _isCheck,
              onChanged: (v){
                setState(() {
                  _isCheck = !_isCheck;
                });
                widget.onCheck({
                  'idOrd': widget.data['orden'],
                  'idRsp': widget.data['cot'],
                  'pieza': widget.data['pieza'],
                  'isCheck': _isCheck
                });
              },
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
                side: const BorderSide(width: 0.5)
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Texto(
          txt: '${widget.data['piezaName']}', sz: 13,
          width: 21,
          txtC: Colors.white.withOpacity(0.7)
        ),
      ],
    );
  }
}