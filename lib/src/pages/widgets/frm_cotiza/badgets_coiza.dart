import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../texto.dart';
import '../../../providers/cotiza_provider.dart';

class BadgetsCotiza extends StatefulWidget {

  final String tipo;
  final String from;
  final ValueChanged<void> onTap;
  const BadgetsCotiza({
    Key? key,
    required this.tipo,
    required this.onTap,
    this.from = 'cotiza'
  }) : super(key: key);
  @override
  State<BadgetsCotiza> createState() => _BadgetsCotizaState();
}

class _BadgetsCotizaState extends State<BadgetsCotiza> {

  final separador = const Texto(txt: '|');
  final colorFix = const Color.fromARGB(255, 102, 102, 102);

  @override
  Widget build(BuildContext context) {

    final ctzP = context.read<CotizaProvider>();
    List<Map<String, dynamic>> items = _getItems();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: items.map((e){
        return (e.containsKey('s'))
          ? separador
          : (e.containsKey('sp')) 
            ? const SizedBox(width: 8)
            : _tileBadget(ctzP, e['lab'], e['tit']);
      }).toList(),
    );
  }

  ///
  Widget _tileBadget(CotizaProvider ctzP, String label, String titulo) {

    late Color color;
    if(widget.tipo == 'taps') {
      color = (ctzP.taps == label) ? Colors.green : colorFix;
    }else{
      color = (ctzP.seccion == label) ? Colors.blue : colorFix;
    }

    return TextButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 1)
        ),
      ),
      onPressed: (){

        if(widget.tipo == 'taps') {
          ctzP.taps = label;
          ctzP.seccion = (label == 'auto') ? 'marcas' : 'pieza';
        }else{
          ctzP.seccion = label;
        }
        widget.onTap(null);
        setState(() {});
      },
      child: Text(
        titulo,
        textScaleFactor: 1,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: color
        ),
      )
    );
  }

  ///
  List<Map<String, dynamic>> _getItems() {

    switch (widget.tipo) {
      case 'taps':
        return [
           {'sp': ''}, {'lab': 'auto', 'tit': 'Vehículo'}, {'sp': ''}, {'s': ''},
           {'sp': ''}, {'lab': 'piezas', 'tit': 'Autopartes'},
        ];
      case 'auto':
        List<Map<String, dynamic>> items = [
          {'lab': 'marcas', 'tit': 'Marcas'}, {'s': ''},
          {'lab': 'modelos', 'tit': 'Modelos'}, {'s': ''},
          {'lab': 'anios', 'tit': 'Años'}, {'s': ''},
        ];

        if(widget.from == 'cotiza') {
          items.add({'lab': 'origenCar', 'tit': 'Nacional'});
          items.add({'sp': ''});
        }
        return items;
      default:
        return [
          {'lab': 'pieza', 'tit': 'Pieza'}, {'s': ''},
          {'lab': 'lado', 'tit': 'Lado'}, {'s': ''},
          {'lab': 'posicion', 'tit': 'Posición'}, {'s': ''},
          {'lab': 'origin', 'tit': 'Orígen'}, {'s': ''},
          {'lab': 'detalles', 'tit': 'Más'}
        ];
    }
  }
}