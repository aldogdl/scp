import 'package:flutter/material.dart';
import 'chonometro.dart';

class Controles extends StatefulWidget {

  final int idOrd;
  final int nPzas;
  final String filename;
  final String created;
  final ValueChanged<void> onOpenCentinela;

  const Controles({
    Key? key,
    required this.filename,
    required this.created,
    required this.idOrd,
    required this.nPzas,
    required this.onOpenCentinela,
  }) : super(key: key);

  @override
  State<Controles> createState() => _ControlesState();
}

class _ControlesState extends State<Controles> {

  @override
  Widget build(BuildContext context) {
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 46, 46, 46),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10)
            ),
          ),
          child: Row(
            children: [
              _btn(
                Icons.android, 'Centinela',
                c: const Color.fromARGB(255, 9, 206, 140), fnc: () => widget.onOpenCentinela(null)
              ),
              _btn(
                Icons.back_hand_rounded, 'Cancelar',
                c: Colors.red, fnc: (){}
              ),
              const Spacer(),
              Chonometro(
                filename: widget.filename, created: widget.created,
                idOrd: widget.idOrd, nPzas: widget.nPzas
              )
            ],
          ),
        )
      ),
    );
  }

  ///
  Widget _btn
    (IconData ico, String tip,
    {required Color c, required Function fnc, double padd = 8})
  {

    return Padding(
      padding: EdgeInsets.only(right: padd),
      child: MouseRegion(
        child: IconButton(
          icon: Icon(ico, color: c),
          iconSize: (ico == Icons.android) ? 20 : 15,
          onPressed: () => fnc(),
          tooltip: tip,
          padding: const EdgeInsets.all(0),
          constraints: const BoxConstraints(
            maxWidth: 40, maxHeight: 18, minWidth: 30
          ),
        ),
      )
    );
  }

}