import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../texto.dart';

class ConsoleProccs extends StatelessWidget {

  final List<String> proccs;
  const ConsoleProccs({
    Key? key,
    required this.proccs
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Container(
          color: Colors.green,
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Row(
              children: [
                Texto(txt: '[ ${proccs.length} ]', txtC: Colors.white, sz: 14),
                const SizedBox(width: 8),
                const Texto(txt: 'Consola', txtC: Colors.white, sz: 14),
                const Spacer(),
                const Icon(Icons.code, size: 18),
              ],
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.26,
          color: Colors.black.withOpacity(0.7),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: proccs.length,
            itemBuilder: (_, i) {

              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  proccs[i],
                  textScaleFactor: 1,
                  style: GoogleFonts.inconsolata(
                    fontSize: 13,
                    color: const Color.fromARGB(255, 123, 140, 161)
                  ),
                ),
              );
            },
          )
        )
      ],
    );
  }
}