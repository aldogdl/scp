import 'package:flutter/material.dart';

class CInventVirtualPage extends StatelessWidget {
  const CInventVirtualPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.3,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Color.fromARGB(255, 71, 71, 71))
            )
          ),
          child: _lstOrdenesConResp(),
        ),
        Expanded(
          child: _dashBoard()
        )
      ],
    );
    
  }

  ///
  Widget _lstOrdenesConResp() {

    return ListView(
      controller: ScrollController(),
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      children: [
        const Divider(),
        _orden(),
      ],
    );
  }

  ///
  Widget _dashBoard() {

    return Center(
      child: _t('DashBoard', fz: 20),
    );
  }

  ///
  Widget _orden() {

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tileOrden(),
        _sh(h: 5),
        _tileData(),
        const Divider(color: Colors.green)
      ],
    );
  }

  ///
  Widget _tileOrden() {

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(Icons.car_crash, size: 15, color: Colors.blue),
        _sw(),
        _t('COROLA'),
        _sw(),
        _t('2018', c: Colors.white),
        _sw(),
        _t('IMPORTADO', c: Colors.grey),
        const Spacer(),
        _t('ID:', fz: 11),
        _sw(w: 5),
        _t('15', fz: 11, c: Colors.white),
      ],
    );
  }

  ///
  Widget _tileData() {

    double s = 11;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Icon(Icons.arrow_right, size: 10, color: Colors.grey),
        _sw(),
        _t('HONDA', fz: s),
        _sw(),
        _t('Creado:', fz: s),
        _sw(w: 5),
        _t('27/58/1922', fz: s, c: Colors.white),
        _sw(),
        const Spacer(),
        _t('Resps:', fz: s),
        _sw(w: 5),
        _t('3', fz: s, c: Colors.white),

      ],
    );
  }

  ///
  Widget _t(String txt, {
    TextAlign ali = TextAlign.center,
    Color c = Colors.amber,
    double fz = 14,
    bool b = false,
  }) {

    return Text(
      txt,
      textScaleFactor: 1,
      textAlign: ali,
      style: TextStyle(
        color: c,
        fontSize: fz,
        fontWeight: (b) ? FontWeight.bold : FontWeight.normal
      ),
    );
  }

  ///
  Widget _sw({double w = 10}) => SizedBox(width: w);

  ///
  Widget _sh({double h = 10}) => SizedBox(height: h);
}