import 'package:flutter/material.dart';

import '../texto.dart';

class TileTituloOrden extends StatelessWidget {

  final String marca;
  final String modelo;
  final String anio;
  final String solicitante;
  final String created;
  final int nOrd;
  final int nResp;
  final int nPzas;
  final bool active;
  final ValueChanged<int> onTap;

  const TileTituloOrden({
    Key? key,
    required this.marca,
    required this.modelo,
    required this.solicitante,
    required this.created,
    required this.anio,
    required this.nResp,
    required this.onTap,
    required this.nOrd,
    this.nPzas = 0,
    this.active = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => onTap(nOrd),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: _body(),
      ),
    );
  }

  ///
  Widget _body() {

    double valOp = 0.55;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Texto(
              txt: modelo,
              txtC: (active) ? Colors.green : Colors.green.withOpacity(valOp),
              sz: 15, isBold: true
            ),
            _sz(5),
            Texto(
              txt: anio,
              txtC: (active) ? Colors.white : Colors.white.withOpacity(valOp),
              sz: 15
            ),
            _sz(5),
            Texto(txt: marca, txtC: Colors.grey, sz: 15),
            const Spacer(),
            if(nPzas != 0)
              ...[
                Row(
                  children: [
                    const Texto(txt: 'Pzs:', sz: 13, txtC: Colors.grey, pw: 3),
                    Texto(txt: '$nPzas', sz: 13, txtC: Colors.white.withOpacity(0.7)),
                  ],
                ),
                _sz(10),
              ],
            if(active)
              Texto(txt: '$nResp', txtC: Colors.grey, sz: 13)
            else
              Texto(txt: 'O: $nOrd', txtC: const Color.fromARGB(255, 240, 219, 32), sz: 13),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Texto(txt: solicitante, sz: 12, txtC: Colors.white.withOpacity(0.5)),
            const Spacer(),
            Texto(txt: created, sz: 12, txtC: Colors.white.withOpacity(0.5), isFecha: true),
          ],
        )
      ],
    );
  }

  ///
  Widget _sz(double size) => SizedBox(width: size);
}