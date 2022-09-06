import 'package:flutter/material.dart';
import 'package:scp/src/pages/widgets/my_tool_tip.dart';

class Texto extends StatelessWidget {

  final String txt;
  final double sz;
  final double pw;
  final double ph;
  final Color txtC;
  final bool isBold;
  final bool isCenter;
  final bool isFecha;
  final int width;

  const Texto({
    required this.txt,
    this.sz = 14.0,
    this.txtC = const Color.fromARGB(255, 158, 158, 158),
    this.isBold = false,
    this.isCenter = false,
    this.width = 0,
    this.isFecha = false,
    this.pw = 0,
    this.ph = 0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => (isFecha) ? _isFecha() : _isText();

  ///
  Widget _isText() {

    String txtSlice = txt;
    bool wSlice = false;

    if(width != 0) {
      if(txtSlice.length > width) {
        txtSlice = txtSlice.substring(0, width);
        txtSlice = '$txtSlice...';
        wSlice = true;
      }
    }

    Widget t = Padding(
      padding: EdgeInsets.symmetric(horizontal: pw, vertical: ph),
      child: _elTxt(txtSlice)
    );
    
    return (wSlice) ? MyToolTip(msg: txt, child: t) : t;
  }

  ///
  Widget _isFecha() {

    DateTime hoy   = DateTime.now();
    DateTime fecha = DateTime.parse(txt);
    final diff = hoy.difference(fecha);
    
    String elD = '';
    switch (diff.inDays) {
      case 0:
        elD = 'Hoy';
        break;
      case 1:
        elD = 'Ayer';
        break;
      default:
        elD = '${"${fecha.day}".padLeft(2, '0')}/${"${fecha.month}".padLeft(2, '0')}';
    }

    final hora = '${"${fecha.hour}".padLeft(2, '0')}:${"${fecha.minute}".padLeft(2, '0')}';

    return _elTxt('$elD $hora');
  }

  ///
  Widget _elTxt(String label) {

    return Text(
      label,
      textScaleFactor: 1,
      textAlign: (isCenter) ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontSize: sz,
        color: txtC,
        fontWeight: (isBold) ? FontWeight.bold : FontWeight.normal
      ),
    );
  }

}