import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/dialog_to_save_asign.dart';
import '../widgets/instruc_asignar_orden.dart';
import '../widgets/widgets_utils.dart';
import '../widgets/my_tool_tip.dart';
import '../widgets/texto.dart';
import '../../config/sng_manager.dart';
import '../../entity/contacto_entity.dart';
import '../../entity/orden_entity.dart';
import '../../providers/pages_provider.dart';
import '../../providers/items_selects_glob.dart';
import '../../providers/window_cnf_provider.dart';
import '../../providers/centinela_file_provider.dart';
import '../../repository/ordenes_repository.dart';
import '../../repository/contacts_repository.dart';
import '../../repository/socket_centinela.dart';
import '../../vars/globals.dart';

class CSolicitudesNonPage extends StatefulWidget {

  const CSolicitudesNonPage({Key? key}) : super(key: key);

  @override
  State<CSolicitudesNonPage> createState() => _CSolicitudesNonPageState();
}

class _CSolicitudesNonPageState extends State<CSolicitudesNonPage> {

  final globals = getSngOf<Globals>();
  final _contacEm = ContactsRepository();
  final _ordsEm = OrdenesRepository();
  final _scrollCtr = ScrollController();
  final _scrollCtrAsig = ScrollController();
  final _scrollCtrSINAsig = ScrollController();
  final _totRodsAvo = ValueNotifier<int>(0);
  final _refreshLstAvos = ValueNotifier<bool>(false);

  late final WindowCnfProvider winCnf;
  late final ItemSelectGlobProvider itemProv;
  late final CentinelaFileProvider _centiProv;
  late final SocketCentinela _sockCenti;
  late final Future _recuperarAvos;

  final Map<String, List<OrdenEntity>> _ordenesAvo = {};
  int _idAvoSelect = 0;
  bool _isInit = false;
  bool _hasErrorSave = false;
  bool _absClickAvo = false;
  bool _isLoad = false;
  int _isValidTarger = 0;
  dynamic _dataSaving;
  CPush _cpushOrden = CPush.asignacion;
  
  @override
  void initState() {
    _recuperarAvos = _getAvosAndFileCentinela();
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    _scrollCtrAsig.dispose();
    _scrollCtrSINAsig.dispose();
    _refreshLstAvos.dispose();
    itemProv.disposeMy();
    _totRodsAvo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        _actionsBar(),
        _seccionAvos(),
        Expanded(
          child: Container(
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.all(10),
            child: _body()
          )
        )
      ],
    );
  }

  ///
  Widget _actionsBar() {

    bool isActive = (itemProv.idOrdenSelect == 0 || _idAvoSelect == 0) ? false : true;

    return Container(
      width: MediaQuery.of(context).size.width * 0.05,
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.2))
        ),
        color: const Color.fromARGB(255, 22, 22, 22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          _iconAcc(
            msg: 'Asignar',
            isActive: isActive,
            icono: Icons.login, bg: const Color.fromARGB(255, 70, 68, 0),
            fnc: () async => await _asignarOrdenTo()
          ),
          _iconAcc(
            msg: 'Desasignar',
            isActive: isActive,
            icono: Icons.cut_outlined, bg: const Color.fromARGB(255, 117, 8, 0),
            fnc: () async => await _desasignarOrden(-1)
          ),
          _iconAcc(
            msg: 'Guardar Cambios',
            isActive: isActive,
            icono: Icons.save, bg: const Color.fromARGB(255, 60, 47, 97),
            fnc: () async {
              _cpushOrden = CPush.asignacion;
              _dataSaving = itemProv.ordenesAsignadas;
              await _guardarAsignacion();
            }
          ),
        ],
      )
    );
  }
  
  ///
  Widget _iconAcc({
    required IconData icono,
    required Color bg,
    required Function fnc,
    required String msg,
    bool isActive = true}) 
  {

    double op = (isActive) ? 1 : 0.3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: MyToolTip(
      msg: msg,
        child: IconButton(
          padding: const EdgeInsets.all(0),
          iconSize: 45,
          onPressed: () => (isActive) ? fnc() : null,
          icon: CircleAvatar(
            radius: 45,
            backgroundColor: bg.withOpacity(op),
            child: Icon(icono, color: Colors.white.withOpacity(op)),
          )
        )
      ),
    );
  }

  ///
  Widget _chipsIdsHead() {

    return Row(
      children: [
        const SizedBox(width: 10),
        Chip(
          label: Texto(
            txt: 'ORDEN ID: ${context.watch<ItemSelectGlobProvider>().idOrdenSelect}',
            txtC: Colors.white,
          ),
          backgroundColor: (itemProv.idOrdenSelect == 0 || itemProv.idOrdenSelect == -1)
            ? Colors.grey.withOpacity(0.5) : Colors.orange,
          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.black),
          visualDensity: VisualDensity.compact,
          onDeleted: () => setState(() {
            itemProv.idOrdenSelect = 0;
          }),
        ),
        const Spacer(),
        Chip(
          label: Texto(
            txt: 'AVO ID: $_idAvoSelect',
            txtC: Colors.white,
          ),
          backgroundColor: (_idAvoSelect == 0)
            ? Colors.grey.withOpacity(0.5) : Colors.red,
          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.black),
          visualDensity: VisualDensity.compact,
          onDeleted: () => setState(() {
            _idAvoSelect = 0;
          }),
        ),
        // const SizedBox(width: 3),
        ValueListenableBuilder(
          valueListenable: _refreshLstAvos,
          builder: (_, val, load) {

            if(val) { return load!; }

            return MyToolTip(
              msg: 'Refrescar AVOS',
              child: IconButton(
                onPressed: () async => await _getOnlyAvos(refreshScreen: true),
                icon: const Icon(
                  Icons.refresh, color: Colors.grey,
                )
              )
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _seccionAvos() {

    return Container(
      width: winCnf.tamMiddle,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.2))
        ),
        color: const Color.fromARGB(255, 22, 22, 22),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _chipsIdsHead(),
          const Divider(color: Colors.green),
          ValueListenableBuilder(
            valueListenable: _totRodsAvo,
            builder: (_, cant, child) {
              return Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Texto(
                    txt: 'Total de Piezas: $cant', isBold: true,
                    txtC: Colors.blue
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder(
              future: _recuperarAvos,
              builder: (_, AsyncSnapshot snap) {
                if(snap.connectionState == ConnectionState.done) {
                  if(itemProv.avos.isEmpty) {
                    return _sinData(icono: Icons.people_alt);
                  }
                  return _lstDeAvos();
                }
                return _loading();
              },
            )
          )
        ],
      )
    );
  }

  ///
  Widget _lstDeAvos() {

    return Scrollbar(
      controller: _scrollCtr,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        shrinkWrap: true,
        controller: _scrollCtr,
        physics: const BouncingScrollPhysics(),
        itemCount: itemProv.avos.length,
        padding: const EdgeInsets.only(right: 10, bottom: 40),
        itemBuilder: (_, index) {
          
          return AbsorbPointer(
            absorbing: _absClickAvo,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onDoubleTap: () => _seleccionandoAvo(index),
                child: Center(
                  child: _tileAvo(index),
                ),
              ),
            ),
          );
        }
      )
    );
  }

  ///
  Widget _body() {

    return Column(
      children: [
        _asignadasRecientes(),
        Container(
          width: MediaQuery.of(context).size.width,
          height: 35,
          padding: const EdgeInsets.only(left: 10),
          color: Colors.black,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Texto(txt: 'LISTA DE ORDENES ASIGNADAS'),
          ),
        ),
        Expanded(
          child: (_isLoad)
          ? _loading()
          : _lstOrdsShare(
              ctr: _scrollCtrAsig,
              items: (_ordenesAvo.containsKey('$_idAvoSelect'))
                ? _ordenesAvo['$_idAvoSelect']! : []
            )
        )
      ],
    );
  }

  ///
  Widget _asignadasRecientes() {

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
        maxWidth: MediaQuery.of(context).size.width
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.5))
        )
      ),
      child: _lstRecientes(),
    );
  }

  ///
  Widget _lstRecientes() {

    return Selector<ItemSelectGlobProvider, Map<int, List<int>>>(
      selector: (_, prov) => prov.ordenesAsignadas,
      builder: (_, lst, __) {

        List<OrdenEntity> ords = [];
        lst.forEach((key, value) {
          
          if(key == _idAvoSelect) {
            for (var i = 0; i < value.length; i++) {
              final os = itemProv.ordenes.indexWhere((e) => e[OrdCamp.orden.name]['o_id'] == value[i]);
              if(os != -1) {
                ords.add(itemProv.getOrden(os));
              }
            }
          }
        });
        
        return _lstOrdsShare( ctr: _scrollCtrSINAsig, items: ords, from: 'top');
      },
    );
  }

  ///
  Widget _lstOrdsShare({
    required ScrollController ctr,
    required List<OrdenEntity> items,
    String from = 'bottom'})
  {

    if(items.isEmpty) {
      if(from == 'bottom') {
        return const InstrucAsignarOrden();
      }else{
        return const Center(
          child: Texto(txt: 'Sin Ordenes recientemente asignadas', isCenter: true),
        );
      }
    }

    return Scrollbar(
      controller: ctr,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      trackVisibility: true,
      child: ListView.builder(
        controller: ctr,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        padding: const EdgeInsets.only(right: 10),
        itemBuilder: (_, index) {
          
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                itemProv.idOrdenSelect = items[index].id;
                itemProv.setOrdenEntitySelect(items[index]);
                setState(() {});
              },
              child: Center(
                child: _tileOrdenesAsig(items[index], from),
              ),
            ),
          );
        }
      ),
    );
  }
  
  ///
  Widget _tileAvo(int index) {

    double op = (_idAvoSelect == itemProv.avos[index].id) ? 0 : 0.05;
    Color cb = (_idAvoSelect == itemProv.avos[index].id) ? const Color.fromARGB(255, 30, 154, 255) : Colors.grey.withOpacity(0.5);

    return DragTarget<int>(
      key: Key('$index'),
      onAccept: (int? idOrden) async {

        List<int> noAceptar = [];
        if(_ordenesAvo.isNotEmpty) {
          if(_ordenesAvo.containsKey('${itemProv.avos[index].id}')) {
            noAceptar = _ordenesAvo['${itemProv.avos[index].id}']!.map((e) => e.id).toList();
          }
        }

        if(!noAceptar.contains(idOrden)) {
          setState(() { _isValidTarger = 1; });
          Future.delayed(const Duration(milliseconds: 1000), (){
            setState(() { _isValidTarger = 0; });
          });
          await _reasignarOrdenTo(idOrden!, itemProv.avos[index].id);
        }else{
          setState(() { _isValidTarger = 2; });
          Future.delayed(const Duration(milliseconds: 1000), (){
            setState(() { _isValidTarger = 0; });
          });
        }
      },
      builder: (_, __, ___) {
        
        return MyToolTip(
          msg: 'Dbl. click para Seleccionar',
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: cb,
                width: 0.5
              ),
              color: Colors.white.withOpacity(op)
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Texto(txt: itemProv.avos[index].nombre, sz: 16, txtC: Colors.white),
                ),
                const Divider(color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Texto(txt: itemProv.avos[index].curc),
                    const Spacer(),
                    const Texto(txt: 'Ords: ', sz: 12),
                    _chip(
                      label: _centiProv.getCantOrdenesDelAvo(
                        itemProv.avos[index].id,
                        recientes: (itemProv.ordenesAsignadas.containsKey(itemProv.avos[index].id))
                          ? itemProv.ordenesAsignadas[itemProv.avos[index].id]!.length : 0
                      )
                    ),
                    const SizedBox(width: 10),
                    const Texto(txt: 'Pzs: ', sz: 12),
                    _chip(label: _centiProv.getCantDePiezasDelAvo(itemProv.avos[index].id), bg: Colors.red)
                  ],
                ),
              ]
            )
          )
        );
      },
    );
  }

  ///
  Widget _tileOrdenesAsig(OrdenEntity orden, String from) {

    Widget sp10 = const SizedBox(width: 10);
    double op = (itemProv.idOrdenSelect == orden.id) ? 0 : 0.05;
    Color cb = (itemProv.idOrdenSelect == orden.id) ? const Color.fromARGB(255, 30, 154, 255) : Colors.grey.withOpacity(0.5);
    int cantPzas = 0;
    try {
      if(_centiProv.centinela.isNotEmpty) {
        if(_centiProv.centinela['piezas'].containsKey('${orden.id}')) {
          cantPzas = _centiProv.centinela['piezas']['${orden.id}'].length;
        }
      }
    } catch (_) {}
    
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: cb, width: 0.5),
        color: Colors.white.withOpacity(op)
      ),
      child: Column(
        children: [
          Row(
            children: [
              Texto(txt: orden.modelo, sz: 16, txtC: Colors.white, isBold: true),
              sp10,
              Texto(txt: '${orden.anio}', sz: 16, txtC: Colors.amber),
              sp10,
              Texto(txt: orden.marca, sz: 16, txtC: Colors.grey),
              sp10,
              Texto(
                txt: (orden.isNac) ? 'NACIONAL' : 'IMPORTADO',
                sz: 14, txtC: Colors.white
              ),
              const Spacer(),
              Texto(txt: orden.empresa, sz: 12, txtC: Colors.white)
            ],
          ),
          const Divider(color: Colors.black),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if(from != 'bottom')
                IconButton(
                  padding: const EdgeInsets.all(0),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    maxWidth: 18, maxHeight: 18
                  ),
                  onPressed: () async => await _desasignarOrden(orden.id),
                  icon: const Icon(Icons.cut, color: Color.fromARGB(255, 255, 126, 117), size: 18)
                )
              else
                MyToolTip(
                  msg: 'Arrastra para Reasignar',
                  child: Draggable<int>(
                    data: orden.id,
                    childWhenDragging: _chip(label: '${orden.id}', bg: const Color.fromARGB(255, 231, 175, 6)),
                    feedback: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 231, 175, 6),
                        borderRadius: BorderRadius.circular(50)
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.rotate_left_rounded, color: Color.fromARGB(255, 0, 0, 0), size: 18),
                          Texto(txt: 'Reasignar la Orden ${orden.id} a...', txtC: Colors.black, isBold: true)
                        ],
                      )
                    ),
                    child: (_isValidTarger == 0)
                      ? const Icon(Icons.rotate_left_rounded, color: Color.fromARGB(255, 255, 126, 117), size: 18)
                      : (_isValidTarger == 1)
                        ? const Icon(Icons.check_circle_outlined, color: Colors.blue, size: 18)
                        : const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  )
                ),
              const SizedBox(width: 10),
              const Texto(txt: 'ID: ', sz: 12),
              _chip(label: '${orden.id}', bg: Colors.white.withOpacity(0.1)),
              const SizedBox(width: 10),
              const Texto(txt: 'Pzs: ', sz: 12),
              _chip(label: '$cantPzas', bg: Colors.purple),
              const Spacer(),
              const Texto(txt: 'El status actual'),
            ],
          ),
        ]
      ),
    );
  }

  ///
  Widget _chip({required String label, Color bg = Colors.orange}) {

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30)
      ),
      child: Texto(txt: label, sz: 12, isBold: true, txtC: Colors.white),
    );
  }

  ///
  Widget _sinData({required IconData icono, double opacity = 0.5}) {

    return Center(
      child: Icon(
        icono, size: 150,
        color: Colors.black.withOpacity(opacity)
      ),
    );
  }

  ///
  Widget _loading({String msg = 'Cargando...'}) {

    return SizedBox.expand(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Texto(txt: msg),
            const SizedBox(height: 8),
            const SizedBox(
              height: 40, width: 40,
              child: CircularProgressIndicator(),
            )
          ],
        ),
      ),
    );
  }

  ///
  Widget _saveAsignacion() {

    return DialogToSaveAsign(
      centiProv: _centiProv,
      cpushOrden: _cpushOrden,
      dataSaving: _dataSaving,
      itemProv: itemProv,
      ordenesAvo: _ordenesAvo,
      onFinish: (Map<String, List<OrdenEntity>> oavo) async {
        
        final nav = Navigator.of(context);
        context.read<PageProvider>().refreshLsts = true;
        bool goServer = true;
        if(oavo.isNotEmpty) {
          if(!_ordenesAvo.containsKey(_idAvoSelect)) {
            if(oavo.containsKey('$_idAvoSelect')) {
              _ordenesAvo['$_idAvoSelect'] = oavo['$_idAvoSelect']!;
              goServer = false;
            }
          }
        }
        if(goServer) {
          await _getOrdenesByAvo(force: true);
        }
        nav.pop(true);
      },
      onError: (_) async {
        setState(() {
          _hasErrorSave = true;
        });
        Navigator.of(context).pop(false);
      }
    );
  }

  // ---------------------------- CONTROLADOR ----------------------------
  
  ///
  Future<void> _getAvosAndFileCentinela() async {

    if(!_isInit) {
      winCnf = context.read<WindowCnfProvider>();
      itemProv = context.read<ItemSelectGlobProvider>();
      itemProv.avos.clear();
      _centiProv = context.read<CentinelaFileProvider>();
      _sockCenti = SocketCentinela();
      _sockCenti.init(context);
    }
    
    if(itemProv.avos.isEmpty) {
      await _getOnlyAvos();
    }

    if(_centiProv.centinela.isEmpty) {
      var centi = await _sockCenti.getFromFile(globals.currentVersion);
      globals.currentVersion = '${centi['version']}';
      centi = {};
    }

    Future.delayed(const Duration(milliseconds: 250), (){
      _isInit = true;
      itemProv.idOrdenSelect = 0;
      itemProv.idPzaSelect = 0;
      itemProv.setOrdenEntitySelect(null);
      itemProv.piezaSelect = null;
    });
  }

  ///
  Future<void> _getOnlyAvos({bool refreshScreen = false}) async {

    bool force = false;
    if(refreshScreen) {
      _refreshLstAvos.value = true;
      force = true;
    }else{
      await _contacEm.getAllAvos();
    }

    await _contacEm.getAllAvos(force: force);
    if(!_contacEm.result['abort']) {
      
      List<ContactoEntity> cts = [];
      for (var i = 0; i < _contacEm.result['body'].length; i++) {
        if(_contacEm.result['body'][i]['c_roles'].contains('ROLE_AVO')) {
          final ct = ContactoEntity();
          ct.fromServerWidtEmpresa(_contacEm.result['body'][i]);
          cts.add(ct);
        }
      }
      _contacEm.clear();
      itemProv.avos = cts;
      if(refreshScreen) {
        if(mounted) {
          _refreshLstAvos.value = false;
          setState(() {});
        }
      }
    }
  }

  ///
  void _seleccionandoAvo(int index) async {
    
    bool resetOrdenToCero = false;
    _idAvoSelect = itemProv.avos[index].id;
    _absClickAvo = true;
    if(_idAvoSelect != 0) {

      await _getOrdenesByAvo();

      // primero revisar si tiene ordenes recientes seleccionadas.
      if(itemProv.ordenesAsignadas.containsKey(_idAvoSelect)) {

        if(itemProv.idOrdenSelect != 0) {
          if(!itemProv.ordenesAsignadas[_idAvoSelect]!.contains(itemProv.idOrdenSelect)) {
            final idOrdenHas = itemProv.ordenesAsignadas[_idAvoSelect]!.first;
            if(idOrdenHas != -1) {
              itemProv.idOrdenSelect = idOrdenHas;
              final os = itemProv.ordenes.indexWhere((e) => e[OrdCamp.orden.name]['o_id'] == itemProv.idOrdenSelect);
              if(os != -1) {
                itemProv.setOrdenEntitySelect(itemProv.getOrden(os));
              }
            }else{
              resetOrdenToCero = true;
            }
          }
        }

      }else{
        if(itemProv.ordenesAsignadas.isNotEmpty) {
          resetOrdenToCero = true;
        }
      }

      if(resetOrdenToCero) {
        itemProv.idOrdenSelect = 0;
        itemProv.setOrdenEntitySelect(null);
      }else{
        if(itemProv.ordenesAsignadas.isNotEmpty) {
          if(itemProv.idOrdenSelect == 0) {
            if(itemProv.ordenesAsignadas.containsKey(_idAvoSelect)) {

              itemProv.idOrdenSelect = itemProv.ordenesAsignadas[_idAvoSelect]!.first;
              final os = itemProv.ordenes.indexWhere((e) => e[OrdCamp.orden.name]['o_id'] == itemProv.idOrdenSelect);
              if(os != -1) {
                itemProv.setOrdenEntitySelect(itemProv.getOrden(os));
              }
            }
          }
        }
      }
    }

    _absClickAvo = false;
    setState(() {});
  }

  ///
  Future<void> _desasignarOrden(int idOrden) async {

    String subm = (idOrden == -1) ? 'TODAS LAS ORDENES' : 'esta orden'; 
    var msg = 'Estás segur@ de quitar $subm al Asesor de Ventas OnLine?';
    bool? acc = await _showAlert(
      titulo: 'DESASIGNAR ORDEN(ES) RECIENTE(S)', msg: msg, onlyAlert: false, withYesOrNot: true
    );

    if(acc ?? false) {
      if(idOrden == -1) {
        itemProv.ordenesAsignadas = {};
      }else{
        itemProv.ordenesAsignadasRemove(_idAvoSelect, idOrden);
      }
      setState(() {});
    }
  }

  ///
  Future<void> _asignarOrdenTo() async {

    if(_idAvoSelect == 0 || itemProv.idOrdenSelect == 0) {
      _showAlert(
        titulo: 'DATOS FALTANTES',
        msg: 'Es imposible asignar una orden a un Asesor de Ventas Online si no '
        'ház seleccionado una orden y a su vez un AVO.'
      );
      return;
    }

    // Revisar que esta orden no esté asiganda recientemente a otro AVO.
    bool existe = false;
    int idAvoHas = 0;
    itemProv.ordenesAsignadas.forEach((key, value) {
      if(value.contains(itemProv.idOrdenSelect)) {
        existe = true;
        idAvoHas = key;
      }
    });
    
    // Si no se encontró asignacion reciente, buscamos directamente en el centinela
    if(!existe) {
      idAvoHas = _centiProv.getAvoOrdenSelected(itemProv.idOrdenSelect);
    }

    if(existe) {
      String avoName = 'Anónimo';
      if(idAvoHas != 0) {
        final avoH = itemProv.avos.where((element) => element.id == idAvoHas);
        if(avoH.isNotEmpty) {
          avoName = '${avoH.first.nombre} de ${ avoH.first.emp!.nombre }';
        }
      }
      String msg = 'Lo sentimos, la orden que deseas asignar ya esta otorgada a '
      '$avoName, por favor, reasignala o selecciona otra orden sin asignación.';
      _showAlert(titulo: 'ORDEN CON ASIGANCIÓN', msg: msg);
      return;
    }

    itemProv.ordenesAsignadasInsert(_idAvoSelect, itemProv.idOrdenSelect);
    setState(() {});
  }

  ///
  Future<void> _reasignarOrdenTo(int idOrden, int idAvo) async {

    String msg = '';
    if(itemProv.ordenesAsignadas.isNotEmpty) {
      msg = 'Para reasignar una orden, es necesario primeramente terminar con '
      'el proceso actual de asignación, y posteriormente proceguir con esta operación.';
    }

    if(msg.isNotEmpty) {
      _showAlert(titulo: 'GUARDANDO LAS ASIGNACIONES', msg: msg);
      return;
    }

    _dataSaving = [idAvo, idOrden];
    _cpushOrden = CPush.reasignacion;
    await _guardarAsignacion();
  }

  ///
  Future<void> _guardarAsignacion() async {

    String msg = '';
    if(_centiProv.centinela.isEmpty) {

      msg = 'No existen los datos referenciales acerca de un historial de seguimiento '
      'de piezas, LOS DATOS DEL CENTINELA ESTÁN VACÍOS\n\n¿Deseas que se recuperen '
      'dichos datos para continuar con el proceso de Guardado?';

      bool? acc = await _showAlert(
        titulo: 'GUARDANDO LAS ASIGNACIONES', msg: msg,
        onlyAlert: false, withYesOrNot: true
      );
      acc = (acc == null) ? false : acc;

      if(acc) {
        msg = 'Espera un momento, estamos trabajando en ello.';
        _showAlert(
          titulo: 'RECUPERANDO CENTINELA FILE', msg: msg,
          onlyAlert: true, withYesOrNot: false
        );
        _sockCenti.getFromApiHarbi().then((_){
          _guardarAsignacion();
        });
      }
      return;
    }

    if(_cpushOrden != CPush.reasignacion) {
      if(itemProv.ordenesAsignadas.isEmpty) {
        msg = 'No hay ningúna ORDEN actualmente dentro de la lista de asignaciones '
        'por favor, selecciona una orden y asignala a un AVO.';
      }
    }

    if(msg.isNotEmpty) {
      _showAlert(titulo: 'GUARDANDO LAS ASIGNACIONES', msg: msg);
      return;
    }

    msg = 'Estas a punto de modificar datos en el sistema general realizando '
    'cambios importantes en la Base de Datos y demás sistemas.\n¿Estás '
    'segur@ de querer continuar?.';

    bool? acc = await _showAlert(
      titulo: 'GUARDANDO LAS ASIGNACIONES', msg: msg, onlyAlert: false, withYesOrNot: true
    );
    
    acc = (acc == null) ? false : acc;
    if(acc) {
      acc = null;
      acc = await _showDialogToSafe();
      acc = (acc == null) ? false : acc;
      if(_hasErrorSave && !acc) {
        acc = await _showAlert(
          titulo: '¡Ocurrio un Error! :(',
          msg: 'Al intentar guardar las asignaciones ocurrio una excepción inesperada.'
          '\n¿Deseas intentar nuevamente guardar las asignaciones?',
          withYesOrNot: true,
          onlyAlert: false,
          msgOnlyYes: 'INTENTAR'
        );
        acc = (acc == null) ? false : acc;
        if(acc) {
          _guardarAsignacion();
        }
      }

      if(!_hasErrorSave && acc) {
        itemProv.idOrdenSelect = 0;
        itemProv.setOrdenEntitySelect(null);
        setState((){});
      }
    }
    return;
  }

  ///
  Future<bool?> _showDialogToSafe() async {

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: _saveAsignacion(),
      )
    );
  }

  ///
  Future<bool?> _showAlert({
    required String titulo,
    required String msg,
    bool withYesOrNot = false,
    bool onlyAlert = true,
    bool onlyYES = false,
    String msgOnlyYes = 'SI'}) async 
  {

    return await WidgetsAndUtils.showAlert(
      context, titulo: titulo, msg: msg,
      onlyAlert: onlyAlert,
      msgOnlyYes: msgOnlyYes,
      onlyYES: onlyYES,
      withYesOrNot: withYesOrNot
    );
  }

  ///
  Future<void> _getOrdenesByAvo({bool force = false}) async {

    setState(() {
      _isLoad = true;
    });

    bool okGo = false;
    if(!_ordenesAvo.containsKey(_idAvoSelect) && !force) {
      okGo = true;
      await _ordsEm.getAllOrdenesByAvoFromServer(_idAvoSelect);
    }

    if(force) {
      okGo = true;
      await _ordsEm.getAllOrdenesByAvoFromServer(_idAvoSelect);
    }

    if(okGo) {
      if(!_ordsEm.result['abort']) {

        final misOrd = <OrdenEntity>[];
        for (var i = 0; i < _ordsEm.result['body'].length; i++) {
          final o = OrdenEntity();
          o.fromArrayServer(_ordsEm.result['body'][i]);
          misOrd.add(o);
        }

        if(_ordenesAvo.containsKey('$_idAvoSelect')) {
          _ordenesAvo['$_idAvoSelect'] = misOrd;
        }else{
          _ordenesAvo.putIfAbsent('$_idAvoSelect', () => misOrd);
        }
      }
    }

    setState(() {
      _isLoad = false;
    });
  }


}
