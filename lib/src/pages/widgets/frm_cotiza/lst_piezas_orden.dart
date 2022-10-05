import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/pages/widgets/my_tool_tip.dart';
import 'package:scp/src/pages/widgets/widgets_utils.dart';

import '../texto.dart';
import '../../../providers/cotiza_provider.dart';
import '../../../vars/globals.dart';

class LstPiezasOrden extends StatefulWidget {

  const LstPiezasOrden({Key? key}) : super(key: key);

  @override
  State<LstPiezasOrden> createState() => _LstPiezasOrdenState();
}

class _LstPiezasOrdenState extends State<LstPiezasOrden> {

  final _globals = getSngOf<Globals>();
  final _sctr = ScrollController();
  bool _isInit = false;
  late CotizaProvider _ctzP;

  @override
  void dispose() {
    _sctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if(!_isInit) {
      _isInit = true;
      _ctzP = context.read<CotizaProvider>();
    }

    return Scrollbar(
      controller: _sctr,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: Selector<CotizaProvider, int>(
        selector: (_, prov) => prov.refreshLstPzasOrden,
        builder: (_, val, __) {

          return ListView.builder(
            controller: _sctr,
            itemCount: _ctzP.piezas.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 15, left: 10, top: 10, bottom: 10),
            itemBuilder: (_, index) => _tilePieza(index),
          );
        }
      )
    );
  }

  ///
  Widget _tilePieza(int index) {

    final pza = _ctzP.piezas[index];
    String deta = pza.obs;
    if(deta.length > 65) {
      deta = '${deta.substring(0, 65)}...';
    }

    // Abrebiar lados
    String lado = pza.lado.trim();
    if(_globals.lugAbr.containsKey(lado)) {
      lado = _globals.lugAbr[lado];
    }
    String pos = pza.posicion.trim();
    if(_globals.lugAbr.containsKey(pos)) {
      pos = _globals.lugAbr[pos];
    }

    const dblClk = 'Doble click para Editar';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              _ctzP.indexPzaCurren = index;
            },
            child: Container(
              width: 45, height: 45,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(45)
              ),
              child: Selector<CotizaProvider, String>(
                selector: (_, prov) => prov.fotoThubm,
                builder: (_, foto, child) {

                  if(pza.fotos.isEmpty) { return child!; }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.file(
                      File(pza.fotos.first),
                      fit: BoxFit.cover,
                    ),
                  );
                },
                child: const Icon(
                  Icons.camera_enhance_outlined,
                  color: Color.fromARGB(255, 90, 90, 90)
                )
              )
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MyToolTip(
                      msg: dblClk,
                      child: InkWell(
                        onDoubleTap: () {
                          _ctzP.idPzaEdit = pza.id;
                          _ctzP.txtEdit = pza.piezaName;
                          _ctzP.taps = 'switch:pieza';
                        },
                        child: Texto(txt: pza.piezaName,
                          sz: 15, txtC: Colors.white
                        ),
                      )
                    ),
                    const SizedBox(width: 8),
                    MyToolTip(
                      msg: pza.lado,
                      child: InkWell(
                        onDoubleTap: () {
                          _ctzP.idPzaEdit = pza.id;
                          _ctzP.txtEdit = pza.lado;
                          _ctzP.taps = 'switch:lado';
                        },
                        child: Texto(txt: lado,
                          sz: 13, txtC: const Color.fromARGB(255, 173, 173, 173)
                        ),
                      )
                    ),
                    const SizedBox(width: 8),
                    MyToolTip(
                      msg: pza.posicion,
                      child: InkWell(
                        onDoubleTap: () {
                          _ctzP.idPzaEdit = pza.id;
                          _ctzP.txtEdit = pza.posicion;
                          _ctzP.taps = 'switch:posicion';
                        },
                        child: Texto(txt: pos,
                          sz: 13, txtC: const Color.fromARGB(255, 128, 128, 128)
                        ),
                      )
                    ),
                    const SizedBox(width: 20),
                    MyToolTip(
                      msg: dblClk,
                      child: InkWell(
                        onDoubleTap: () {
                          _ctzP.idPzaEdit = pza.id;
                          _ctzP.txtEdit = pza.origen;
                          _ctzP.taps = 'switch:origin';
                        },
                        child: Texto(txt: pza.origen, sz: 13, txtC: Colors.blue)
                      )
                    ),
                    const Spacer(),
                    const SizedBox(width: 20),
                    _iconGestion(
                      ico: Icons.delete, color: Colors.red,
                      fnc: () => _deletePza(pza.id)
                    ),
                    const SizedBox(width: 20),
                    _iconGestion(
                      ico: Icons.extension, color: Colors.blue,
                      fnc: (){}
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MyToolTip(
                      msg: dblClk,
                      child: InkWell(
                        onDoubleTap: () {
                          _ctzP.idPzaEdit = pza.id;
                          _ctzP.txtEdit = pza.obs;
                          _ctzP.taps = 'switch:detalles';
                        },
                        child: Texto(txt: deta, sz: 13, txtC: Colors.grey)
                      )
                    ),
                    const Spacer(),
                    Texto(
                      txt: 'Id: ${_ctzP.formatIdPza(pza.id)}',
                      txtC: const Color.fromARGB(255, 88, 206, 147),
                      sz: 13,
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _iconGestion({
    required Function fnc, required IconData ico, required Color color})
  {

    return IconButton(
      onPressed: () => fnc(),
      iconSize: 18,
      constraints: const BoxConstraints(
        maxHeight: 20
      ),
      padding: const EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
      icon: Icon(ico, color: color)
    );
  }

  void _deletePza(int id) async {

    bool? acc = await WidgetsAndUtils.showAlert(
      context,
      titulo: 'Borrando Pieza',
      msg: 'Se eliminará permanentemente la pieza seleccionada.\n'
      '¿Estás segur@ de continuar?',
      msgOnlyYes: 'Sí, Borrar',
      onlyAlert: false,
      focusOnConfirm: true,
      onlyYES: false,
      withYesOrNot: true
    );

    acc = (acc == null) ? false : acc;
    if(acc) {
      final ind = _ctzP.piezas.indexWhere((pz) => pz.id == id);
      if(ind != -1) {
        _ctzP.piezas.removeAt(ind);
        _ctzP.refreshLstPzasOrden = _ctzP.piezas.length;
      }
    }
  }
}