import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scp/src/pages/widgets/texto.dart';
import 'package:scp/src/pages/widgets/widgets_utils.dart';
import 'package:scp/src/providers/filtros_provider.dart';
import 'package:scp/src/repository/contacts_repository.dart';

import 'filtros_contact.dart';

class PanelFiltros extends StatelessWidget {

  final double width;
  final int idEmp;
  const PanelFiltros({
    Key? key,
    required this.width,
    required this.idEmp
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.black.withOpacity(0.2),
      child: SizedBox.expand(
        child: Column(
          children: [
            Container(
              width: width,
              color: Colors.green,
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.settings, size: 35, color: Colors.black.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  const Texto(txt: 'PANEL DE FILTROS', txtC: Colors.black)
                ],
              ),
            ),
            _option(context, '[A] SÓLO AUTOS DE ALTA GAMA:'),
            _option(context, '[B] SÓLO AUTOS COMERCIALES:'),
            _option(context, '[C] EMPRESA MULTIMARCAS:'),
            const Divider(),
            Selector<FiltrosProvider, Map<String, dynamic>>(
              selector: (_, prov) => prov.marca,
              builder: (_, val, __) => _row(context, 'Marca:', val['nombre']),
            ),
            Selector<FiltrosProvider, Map<String, dynamic>>(
              selector: (_, prov) => prov.modelo,
              builder: (_, val, __) => _row(context, 'Modelo:', val['nombre']),
            ),
            Container(
              width: width,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Selector<FiltrosProvider, String>(
                      selector: (_, prov) => prov.aniosD,
                      builder: (_, val, __) => _rowDraw(context, 'Desde:', val),
                    ),
                  ),
                  Expanded(
                    child: Selector<FiltrosProvider, String>(
                      selector: (_, prov) => prov.aniosH,
                      builder: (_, val, __) => _rowDraw(context, 'Hasta:', val),
                    ),
                  ),
                ],
              )
            ),
            Selector<FiltrosProvider, Map<String, dynamic>>(
              selector: (_, prov) => prov.pieza,
              builder: (_, val, __) => _row(context, 'Pieza:', val['value']),
            ),
            _option(context, '[D] SÓLO MANEJA ESTA:'),
            _option(context, '[E] MANEJA TODAS EXCEPTO ESTA:'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      const Color.fromARGB(255, 108, 173, 110)
                    )
                  ),
                  onPressed: (){},
                  child: const Texto(txt: 'Limpiar Panel', txtC: Colors.black)
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _guardarFiltro(context);
                  },
                  child: const Texto(txt: 'Guardar Filtro', txtC: Colors.black)
                ),
              ],
            ),
            Expanded(
              child: FiltrosContact(idEmp: idEmp)
            )
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, String label) {

    String op = _getLetterOption(label);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Texto(txt: label),
          const Spacer(),
          Transform.scale(
            scale: 0.6,
            child: Selector<FiltrosProvider, bool>(
              selector: (_, prov) {
                switch (op) {
                  case 'A': return prov.altaGam;
                  case 'B': return prov.autoCom;
                  case 'C': return prov.multimrk;
                  case 'D': return prov.soloEsta;
                  default:  return prov.excEsta;
                }
              },
              builder: (_, val, __) => Checkbox(
                value: val,
                checkColor: Colors.black,
                onChanged: (val) => _actionOption(context, op, val ?? false)
              ),
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _row(BuildContext context, String label, String value) {

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      child: Row(
        children: [
          Texto(txt: label),
          const Spacer(),     
          Texto(txt: value, txtC: Colors.white, isBold: true),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () {
              final prov = context.read<FiltrosProvider>();
              switch (label) {
                case 'Marca:':
                  prov.marca = {'nombre':'0'};
                  prov.modelo = {'nombre':'0'};
                  break;
                case 'Modelo:':
                  prov.modelo = {'nombre':'0'};
                  break;
                case 'Pieza:':
                  prov.pieza = {'value':'0'};
                  break;
                default:
              }
            },
            constraints: const BoxConstraints(maxWidth: 25, maxHeight: 28),
            padding: const EdgeInsets.all(0),
            icon: const Icon(Icons.close, size: 18, color: Color.fromARGB(255, 236, 68, 68))
          ),
        ],
      ),
    );
  }

  ///
  Widget _rowDraw(BuildContext context, String label, String value) {

    return Row(
      children: [
        Texto(txt: label),
        const SizedBox(width: 20),
        Texto(txt: value, txtC: Colors.white, isBold: true),
        const Spacer(),
        IconButton(
          onPressed: () {
            
            final prov = context.read<FiltrosProvider>();
            switch (label) {
              case 'Desde:':
                prov.aniosD = '0';
                break;
              case 'Hasta:':
                prov.aniosH = '0';
                break;
              default:
            }
          },
          constraints: const BoxConstraints(maxWidth: 25, maxHeight: 28),
          padding: const EdgeInsets.all(0),
          icon: const Icon(Icons.close, size: 18, color: Color.fromARGB(255, 236, 68, 68))
        ),
      ],
    );
  }

  ///
  String _getLetterOption(String label) {

    if(label.startsWith('[A')) { return 'A'; }
    if(label.startsWith('[B')) { return 'B'; }
    if(label.startsWith('[C')) { return 'C'; }
    if(label.startsWith('[D')) { return 'D'; }
    if(label.startsWith('[E')) { return 'E'; }
    return '';
  }

  ///
  void _actionOption(BuildContext context, String opcion, bool val) {

    final prov = context.read<FiltrosProvider>();
    switch (opcion) {
      case 'E':
        prov.excEsta = val;
        prov.soloEsta = !prov.excEsta;
        break;
      case 'D':
        prov.soloEsta = val;
        prov.excEsta = !prov.soloEsta;
        break;
      case 'C':
        prov.multimrk = val;
        prov.autoCom = (prov.multimrk) ? false : prov.autoCom;
        prov.altaGam = (prov.multimrk) ? false : prov.altaGam;
        break;
      case 'B':
        prov.autoCom = val;
        prov.multimrk = (prov.autoCom) ? false : prov.multimrk;
        prov.altaGam = (prov.autoCom) ? false : prov.altaGam;
        break;
      case 'A':
        prov.altaGam = val;
        prov.multimrk = (prov.altaGam) ? false : prov.multimrk;
        prov.autoCom = (prov.altaGam) ? false : prov.autoCom;
        break;
      default:
    }
  }

  ///
  Future<void> _guardarFiltro(BuildContext context) async {

    const t = 'Guardando Filtro';

    WidgetsAndUtils.showAlert(
      context, titulo: t,
      msgOnlyYes: 'Sí, Continuar',
      withYesOrNot: true,
      onlyAlert: false,
      onlyYES: false,
      focusOnConfirm: true,
      msg: 'Se guardarán los datos en las diferentes Bases de Datos.\n'
      'Esto significa un cambio importante en los registros.\n'
      '¿Estás segur@ de continuar?'
    ).then((bool? acc) async {

      acc = (acc == null) ? false : acc;
      if(acc) {
        
        await WidgetsAndUtils.showAlertBody(
          context, titulo: t,
          dismissible: false,
          body: FutureBuilder(
            future: _saveFiltro(context),
            builder: (_, AsyncSnapshot snap) {

              String txt = 'Guardando Filtro. Espera un momento por favor';
              if(snap.connectionState == ConnectionState.done) {
                if(snap.hasData) {
                  if(snap.data['abort']) {
                    txt = '${snap.data['body']}.\nInténtalo nuevamente';
                  }else{
                    txt = '¡Listo!, Filtro Guardado con Éxito';
                    Future.delayed(const Duration(milliseconds: 500), (){
                      Navigator.of(context).pop();
                    });
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Column(
                  children: [
                    Texto(txt: txt),
                    const SizedBox(height: 8),
                    if(txt.startsWith('Error'))
                      ...[
                        const Divider(),
                        Texto(txt: snap.data['msg'], sz: 12),
                        const Divider(),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Texto(txt: 'ENTENDIDO', txtC: Colors.black)
                        )
                      ]
                    else
                      const LinearProgressIndicator(),
                  ],
                ),
              );
            },
          )
        );
      }
    });

  }

  ///
  Future<Map<String, dynamic>> _saveFiltro(BuildContext context) async {

    final prov = context.read<FiltrosProvider>();
    final data = prov.getDataForSave();
    data['emp'] = idEmp;

    final em = ContactsRepository();
    await em.setFiltroCotizador(data, isLocal: false);

    if(!em.result['abort']) {
      await em.setFiltroCotizador(data, isLocal: true);
    }
    return em.result;
  }
}