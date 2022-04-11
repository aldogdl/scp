import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/entity/orden_entity.dart';
import 'package:scp/src/entity/piezas_entity.dart';
import 'package:scp/src/pages/widgets/my_tool_tip.dart';
import 'package:scp/src/pages/widgets/orden_tile.dart';
import 'package:scp/src/providers/items_selects_glob.dart';
import 'package:scp/src/repository/ordenes_repository.dart';
import 'package:scp/src/repository/piezas_repository.dart';
import 'package:scp/src/services/rutas/est_stt.dart';
import 'package:scp/src/services/rutas/rutas_cache.dart';
import 'package:scp/src/vars/globals.dart';
import 'package:scp/src/vars/shortcut_activators.dart';

import '../../services/get_path_images.dart';
import '../widgets/texto.dart';

class SolicitudesPage extends StatefulWidget {

  const SolicitudesPage({Key? key}) : super(key: key);

  @override
  State<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends State<SolicitudesPage> {

  final Globals globals = getSngOf<Globals>();
  final RutasCache rutasCache = getSngOf<RutasCache>();
  final OrdenesRepository _ordenEm = OrdenesRepository();
  final PiezasRepository _pzasEm = PiezasRepository();

  final ScrollController _scrollCtr = ScrollController();
  final TextEditingController _txtCtr = TextEditingController();
  final FocusNode _fcsTxt = FocusNode();
  final ValueNotifier<String> _msg = ValueNotifier<String>('Buscar Orden');
  final ValueNotifier<List<OrdenEntity>> _ordenes = ValueNotifier<List<OrdenEntity>>([]);

  String _accTxt = 'bsk';
  String _txtLoading = 'Ordenes';
  bool _isLoading = true;
  late Future<void> _getOrdenes;

  @override
  void initState() {
    _getOrdenes = _recuperarTodasLasOrdenes();
    super.initState();
  }

  @override
  void dispose() {
    _txtCtr.dispose();
    _fcsTxt.dispose();
    _scrollCtr.dispose();
    _msg.dispose();
    _ordenes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      fit: StackFit.expand,
      children: [
        _body(),
        if(_isLoading)
          Positioned.fill(
            child: _loading(),
          )
      ],
    );
  }

  ///
  Widget _body() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _txtDownSearch(),
        const SizedBox(height: 5),
        ValueListenableBuilder<String>(
          valueListenable: _msg,
          builder: (_, val, __) {

            Color txtC = Colors.grey.withOpacity(0.9);
            if(val.startsWith('alert')) {
              txtC = Colors.amber;
              val = val.replaceAll('alert', '').trim();
            }
            return Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Texto(txt: val, sz: 12, txtC: txtC)
            );
          },
        ),
        const SizedBox(height: 10),
        const Divider(color: Color.fromARGB(255, 0, 0, 0), height: 1),
        const Divider(color: Color.fromARGB(255, 83, 83, 83), height: 1),
        const SizedBox(height: 10),
        
        Expanded(
          child: ValueListenableBuilder<List<OrdenEntity>>(
            valueListenable: _ordenes,
            builder: (_, ords, __) {
             
              return Scrollbar(
                controller: _scrollCtr,
                isAlwaysShown: true,
                radius: const Radius.circular(3),
                showTrackOnHover: true,
                trackVisibility: true,
                child: ListView.builder(
                  controller: _scrollCtr,
                  itemCount: ords.length,
                  itemBuilder: (_, index) {
                    
                    return GestureDetector(
                      onTap: () => _selectedOrden(index),
                      child: Center(
                        child: OrdenTile(orden: ords[index]),
                      ),
                    );
                  }
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  ///
  Widget _loading() {

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Texto(txt: 'Recuperando $_txtLoading', sz: 12, txtC: Colors.amber),
          )
        ],
      ),
    );
  }

  ///
  Widget _txtDownSearch() {

    return SizedBox(
      height: 35,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: FocusableActionDetector(
                focusNode: _fcsTxt,
                shortcuts: <ShortcutActivator, Intent>{
                  downElement: DownElement(),
                  searchElement: SearchElement(),
                },
                actions: <Type, Action<Intent>>{
                  DownElement: CallbackAction<Intent>(
                    onInvoke: (intent) async => await _searchOrDown('down')
                  ),
                  SearchElement: CallbackAction<Intent>(
                    onInvoke: (intent) async => await _searchOrDown('bsk')
                  )
                },
                child: TextField(
                  controller: _txtCtr,
                  onSubmitted: (v) async => await _searchOrDown(_accTxt),
                  onChanged: (v) {
                    if(v.isEmpty) {
                      _msg.value = (_accTxt == 'bsk') ? 'Buscar Orden' : 'Recuperar Orden por ID';
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 1
                      )
                    )
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MyToolTip(
              msg: 'Buscar [ctrl-alt-b]',
              child: IconButton(
                onPressed: () async => await _searchOrDown('bsk'),
                icon: Icon(
                  Icons.search,
                  color: (_accTxt == 'bsk') ? Colors.blue : Colors.grey,
                )
              ),
            ),
            MyToolTip(
              msg: 'Descargar [ctrl-alt-d]',
              child: IconButton(
                onPressed: () async => await _searchOrDown('down'),
                icon: Icon(
                  Icons.download,
                  color: (_accTxt == 'down') ? Colors.blue : Colors.grey,
                )
              )
            )
          ],
        )
      )
    );
  }

  ///
  Future<void> _searchOrDown(String acc) async {

    _accTxt = acc;
    _txtLoading = 'Ordenes';
    if(acc == 'bsk') {
      _msg.value = 'Buscar Orden';
    }

    if(_accTxt == 'down') {

      _msg.value = 'Recuperar Orden por ID';
      int? idOrden = int.tryParse(_txtCtr.text);
      if(idOrden == null) {
        _msg.value = 'El Id no es valido';
      }else{
        _msg.value = 'Descargando, espera por favor';
        await _ordenEm.getOrdenById(idOrden);
        if(_ordenEm.result['body'].isNotEmpty) {
          _msg.value = 'Listo...';
          var ord = OrdenEntity();
          ord.fromServer(_ordenEm.result['body']);
          Future.delayed(const Duration(seconds: 1), (){
            _msg.value = 'Recuperar Orden por ID';
          });
          _ordenes.value.insert(0, ord);
        }else{
          _msg.value = 'alert No existe la Orden $idOrden';
          Future.delayed(const Duration(seconds: 3), (){
            _msg.value = 'Recuperar Orden por ID';
          });
        }
        setState(() {});
      }
    }
  }

  ///
  Future<void> _recuperarTodasLasOrdenes() async {

    await rutasCache.hidratar();
    await _ordenEm.getAllOrdenesByAvo(0);

    if(_ordenEm.result['body'].isNotEmpty) {
      for (var i = 0; i < _ordenEm.result['body'].length; i++) {
        OrdenEntity ent = OrdenEntity();
        ent.fromServer(_ordenEm.result['body'][i]);
        _ordenes.value.add(ent);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  ///
  Future<void> _selectedOrden(int indexOrden) async {

    // Evitar que se gasten recursos al precionar la misma orden
    final items = context.read<ItemSelectGlobProvider>();
    if(items.idOrdenSelect == _ordenes.value[indexOrden].id) {
      if(items.piezas.isNotEmpty) {
        return;
      }
    }
    await _determinarAccionSegunStatus(items, indexOrden);
  }

  ///
  Future<void> _determinarAccionSegunStatus(ItemSelectGlobProvider items, int index) async {

    var cStt = _ordenes.value[index].status();
    var nStt = <String, dynamic>{};

    // Si el status esta entre los casos siguientes su cambio de Status es en
    // automático en caso contrario el cambio es manual realizado por el usuario
    switch (cStt['stt']) {
      case "1": // Orden en Fila
        // Buscamos el siguiente status de la estación
        nStt = await EstStt.getNextSttByEst(cStt);
        break;
      default:
        // La reaccion normal de esta seccion es visualizar las piezas.
        await _recuperarPiezasFromDb(items, index);
    }

    if(nStt.isNotEmpty && !nStt.containsKey('error')) {

      bool changeStt = true;
      // Acciones automáticas según el status
      switch (nStt['stt']) {
        case "2": // Orden en revisión
          await _recuperarPiezasFromDb(items, index);
          break;
        default:
          changeStt = false;
      }

      if(changeStt) {
        _ordenes.value[index].est = nStt['est'];
        _ordenes.value[index].stt = nStt['stt'];
        nStt['orden'] = _ordenes.value[index].id;
        nStt['version'] = DateTime.now().millisecondsSinceEpoch;
        _ordenEm.changeStatusToRemoto(nStt);
      }
    }
  }

  /// Cuando el status requiere que revisemos los datos de las piezas
  Future<void> _recuperarPiezasFromDb(ItemSelectGlobProvider items, int inxOrd) async {

    items.fotosByPiezas = [];
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() {
      _txtLoading = 'Piezas';
      _isLoading = true;
    });

    await _pzasEm.getPiezasByOrden(_ordenes.value[inxOrd].id);
    if(_pzasEm.result['body'].isNotEmpty) {

      List<PiezasEntity> pzas = [];
      List<Map<String, dynamic>> fpzas = [];

      for (var i = 0; i < _pzasEm.result['body'].length; i++) {
        PiezasEntity ent = PiezasEntity();
        ent.fromServer(_pzasEm.result['body'][i]);
        if(ent.fotos.isNotEmpty) {
          for (var i = 0; i < ent.fotos.length; i++) {    
            var fp = <String, dynamic>{
              'id' : ent.id,
              'foto': await GetPathImages.getPathPzaTmp(ent.fotos[i])
            };
            fpzas.add(fp);
          }
        }
        pzas.add(ent);
      }
      
      if(pzas.isNotEmpty) {
        items.piezas = pzas;
        items.fotosByPiezas = fpzas;
        items.idPzaSelect = fpzas.first['id'];
        items.idOrdenSelect = _ordenes.value[inxOrd].id;
        items.setOrdenEntitySelect(_ordenes.value[inxOrd]);
        pzas = [];
        fpzas= [];
      }
    }

    setState(() {
      _isLoading = false;
      _txtLoading = 'Ordenes';
    });
  }

}
