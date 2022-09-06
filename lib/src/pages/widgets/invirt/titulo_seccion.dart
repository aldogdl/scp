import 'package:flutter/material.dart';

import '../texto.dart';

class TituloSeccion extends StatelessWidget {

  final String titulo;
  final String chip;
  final IconData ico;
  const TituloSeccion({
    Key? key,
    required this.titulo,
    required this.chip,
    required this.ico
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ico, size: 15, color: Colors.orange),
              const SizedBox(width: 10),
              Texto(
                txt: titulo, txtC: const Color.fromARGB(255, 90, 90, 90), isBold: true,
              ),
              const Spacer(),
              if(chip.isNotEmpty)
                Container(
                  height: 21,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(255, 90, 90, 90)
                  ),
                  child: Text(
                    chip,
                    textScaleFactor: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal
                    ),
                  )
                )
            ],
          ),
          const SizedBox(height: 5),
          const Divider(color: Colors.black, height: 2),
          const Divider(color: Color.fromARGB(255, 97, 97, 97), height: 1),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}