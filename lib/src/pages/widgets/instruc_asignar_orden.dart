import 'package:flutter/material.dart';

class InstrucAsignarOrden extends StatelessWidget {

  const InstrucAsignarOrden({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (_, tamanio) => _body(tamanio)
      ),
    );
  }

  ///
  Widget _body(BoxConstraints tamanio) {

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.black)
              )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿CÓMO ASIGNAR LAS ÓRDENES?',
                  textScaleFactor: 1,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.w300
                  ),
                ),
                const Divider(color: Colors.blue),
                const SizedBox(height: 20),
                _instruccion('1', 'Selecciona la orden que vas a asignar.'),
                _instruccion('2', 'Con doble click elige al AVO a quien le será asignada la orden.'),
                _instruccion('3', 'Presiona el botón de asignar.'),
                const Padding(
                  padding: EdgeInsets.only(top: 10, left: 3),
                  child: Text(
                    'NOTA: Repite los pasos 1 y 3 por cada orden que le asignarás al mismo AVO.',
                    textScaleFactor: 1,
                    style: TextStyle(
                      fontSize: 13.5, color: Color.fromARGB(255, 206, 206, 206)
                    ),
                  ),
                ),
                _instruccion('4', 'Si deseas desasignar una orden haz click en el icono de tijeras sobre la orden deseada.'),
                _instruccion('5', 'Al finalizar las asignaciones almacena tu selección al presionar el botón de guardar.'),
              ],
            ),
          ),
        ),
        _tituloInstructivo(tamanio)
      ],
    );
  }
  
  ///
  Widget _tituloInstructivo(BoxConstraints tamanio) {

    return Container(
      width: tamanio.maxWidth * 0.1,
      height: tamanio.maxHeight,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 2, 79, 143),
        border: Border(
          left: BorderSide(color: Color.fromARGB(255, 102, 117, 250))
        )
      ),
      child: const RotatedBox(
        quarterTurns: 1,
        child: Center(
          child: Text(
            'INSTRUCTIVO',
            textScaleFactor: 1,
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w200,
              color: Color.fromARGB(255, 176, 184, 255),
              letterSpacing: 8,
              shadows: [
                Shadow(
                  offset: Offset(1, 0),
                  blurRadius: 1
                )
              ]
            ),
          ),
        )
      ),
    );
  }
  
  ///
  Widget _instruccion(String nu, String inst) {

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _bolita(nu),
          const SizedBox(width: 10),
          Expanded(child: _titLabel(inst))
        ],
      ),
    );
  }

  ///
  Widget _bolita(String valor) {

    return CircleAvatar(
      backgroundColor: const Color(0xFF8aa5ae),
      radius: 15,
      child: Text(
        valor,
        textScaleFactor: 1,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17
        ),
      ),
    );
  }

  ///
  Widget _titLabel(String txt) {

    return Text(
      txt,
      textScaleFactor: 1,
      maxLines: 2,
      style: const TextStyle(
        color: Color(0xFFe1b787),
        fontSize: 16
      ),
    );
  }
}
