import 'package:flutter/material.dart';
import 'package:scp/src/pages/widgets/texto.dart';

import '../../../services/inventario_service.dart';

class ShowHelpCmd extends StatelessWidget {

  const ShowHelpCmd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 194, 194, 194),
        borderRadius: BorderRadius.circular(5)
      ),
      child: Column(
        children: [
          const Texto(
            txt: 'COMANDOS DE ENTRADAS Y FILTROS',
            isBold: true, isCenter: true,
            sz: 20,
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getData(),
              builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> helps) {
                if(helps.connectionState == ConnectionState.done) {
                  if(helps.hasData) {
                    return ListView.builder(
                      itemCount: helps.data!.length,
                      itemBuilder: (_, i) => _item(helps.data![i])
                    );
                  }
                }
                return const Center(
                  child: SizedBox(
                    width: 40, height: 40,
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _item(Map<String, dynamic> help) {

    if(help.containsKey('hidden')) { return const SizedBox(); }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey)
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Texto(txt: help['desc'], txtC: const Color.fromARGB(255, 46, 46, 46)),
              ),
              Expanded(
                flex: 1,
                child: Texto(txt: help['clv'], isCenter: true, sz: 18, txtC: Colors.red),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Texto(txt: '${help['val']}', txtC: const Color.fromARGB(255, 0, 0, 0))
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ///
  Future<List<Map<String, dynamic>>> _getData() async {

    List<Map<String, dynamic>> helps = [];
    final comm = InventarioService.cmds;
    comm.forEach((key, value) {
      helps.add(value);
    });

    return helps;
  }
}