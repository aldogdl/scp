import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../texto.dart';
import '../../../services/scranet/system_file_scrap.dart';

class BuildDataGral extends StatelessWidget {

  final ValueChanged<void> onFinish;
  const BuildDataGral({
    Key? key,
    required this.onFinish
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    final proccs = ValueNotifier<List<Map<String, dynamic>>>([]);
    final nProccs = ValueNotifier<int>(0);

    return Container(
      width: size.width * 0.6,
      height: size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Image(
                image: AssetImage('assets/build_data.jpg'),
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          Container(
            width: size.width * 0.3,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Construyendo Datos de Funcionalidad',
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.comfortaa(
                    textStyle: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      height: 1.3
                    )
                  ),
                ),
                const Divider( color: Colors.green),
                const Texto(
                  txt: 'Es muy importante construir o actualizar los datos requeridos '
                  'para el funcionamiento óptimo de tu Sistema Central '
                  'de Piezas y Proveedores (SCP).',
                  txtC: Color.fromARGB(255, 56, 56, 56),
                ),
                const SizedBox(height: 15),
                const Texto(
                  txt: 'Este proceso puede durar considerables minutos '
                  'por favor, espera y ten pasciencia, estamos trabajando '
                  'para ti, NO CIERRES EL SCP en este punto.',
                  txtC: Color.fromARGB(255, 207, 74, 74),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey)
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Texto(
                        txt: 'TAREAS EN PROCESAMIENTO',
                        txtC: Colors.black,
                      ),
                      const Spacer(),
                      Chip(
                        label: ValueListenableBuilder<int>(
                          valueListenable: nProccs,
                          builder: (_, val, __) {
                            return Texto(
                              txt: '$val',
                              txtC: Colors.greenAccent,
                            );
                          },
                        )
                      )
                    ],
                  )
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder(
                    future: _procesandoTask(proccs, nProccs),
                    builder: (_, AsyncSnapshot snap) {
                      return _procesando(proccs);
                    },
                  )
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _procesando(ValueNotifier<List<Map<String, dynamic>>> proc) {

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: proc,
      builder: (_, val, __) {

        if(val.isEmpty) {
          return const SizedBox();
        }

        return ListView(
          padding: const EdgeInsets.only(right: 15),
          children: val.map((e) => _tileProcess(e)).toList(),
        );
      }
    );
  }

  ///
  Widget _tileProcess(Map<String, dynamic> p) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Row(
        children: [
          if(p['stt'] == 'ok')
            const Icon(Icons.done_all, color: Colors.green, size: 19)
          else
            const SizedBox(
              width: 15, height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 10),
          Text(
            p['proc'],
            textScaleFactor: 1,
            style: GoogleFonts.inconsolata(
              textStyle: TextStyle(
                color: (p['stt'] != 'ok')
                  ? const Color.fromARGB(255, 46, 100, 145)
                  : const Color.fromARGB(255, 104, 104, 104),
                fontSize: 16
              )
            ),
          )
        ],
      ),
    );
  }

  ///
  Future<void> _procesandoTask(
    ValueNotifier<List<Map<String, dynamic>>> proc, ValueNotifier<int> nProc
  ) async  {

    List<Map<String, dynamic>> task = [];

    String craw = 'radec';
    await _st('[${craw.toUpperCase()}] Nombres de Piezas', proc, nProc);
    // await BuildDataScrap.getPiezasOf(craw);
    await _st('', proc, nProc);

    await _st('[${craw.toUpperCase()}] Nombres de Marcas', proc, nProc);
    // await BuildDataScrap.getMarcasOf(craw);
    await _st('', proc, nProc);

    await _buildModelos(craw, task, proc, nProc);
    onFinish(null);
  }

  ///
  Future<void> _buildModelos
    (
      String craw, List<Map<String, dynamic>> task,
      ValueNotifier<List<Map<String, dynamic>>> proc, ValueNotifier<int> nProc
    ) async 
  {

    final marcasW = await SystemFileScrap.getAllMarcasBy(craw);
    Map<String, dynamic> models = {};

    for (var i = 0; i < marcasW.length; i++) {

      final clave = marcasW[i]['id'].toString().toUpperCase().trim();
      if(clave.isEmpty) {
        if(clave.contains('TODOS')) {
          continue;
        }
      }

      await _st('[${craw.toUpperCase()}] Modelos de ${marcasW[i]['value']}', proc, nProc);
      // await BuildDataScrap.getMarcasOf(craw);
      await _st('', proc, nProc);
      // final modsWeb = await BuildDataScrap.getModelosOf(craw, clave);
      // if(modsWeb.isNotEmpty) {
      //   List<Map<String, dynamic>> listos = [];
      //   modsWeb.forEach((key, value) {
      //     String checkVal = value.toString().trim();
      //     if(checkVal.isNotEmpty) {
      //       if(!checkVal.contains('TODOS')) {
      //         listos.add({
      //           'id': key.toUpperCase().trim(),
      //           'value': checkVal.toUpperCase().trim()
      //         });
      //       }
      //     }
      //   });
        
      //   models.putIfAbsent(clave, () => listos);
      //   await Future.delayed(const Duration(milliseconds: 2000));
      // }
    }

    if(models.isNotEmpty) {
      SystemFileScrap.setModelosBy(craw, models);
    }
  }

  ///
  Future<void> _st
    (
      String t,
      ValueNotifier<List<Map<String, dynamic>>> proc, ValueNotifier<int> nProc
    ) async
  {

    var tareas = List<Map<String, dynamic>>.from(proc.value);
    proc.value = [];
    if(t.isEmpty) {
      tareas[0]['stt'] = 'ok';
    }else{
      tareas.insert(0, {'proc':t, 'stt': 'make'});
    }
    proc.value = tareas;
    nProc.value = tareas.length;
    await Future.delayed(const Duration(milliseconds: 250));
    
  }
}