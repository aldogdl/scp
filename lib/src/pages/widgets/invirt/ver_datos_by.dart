import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/services/inventario_inject_service.dart';

import '../../../services/get_path_images.dart';
import '../../widgets/texto.dart';
import '../../content/c_solicitudes_page.dart';
import '../../../entity/orden_entity.dart';
import '../../../entity/piezas_entity.dart';
import '../../../providers/invirt_provider.dart';
import '../../../providers/items_selects_glob.dart';
import '../../../repository/inventario_repository.dart';

class VerDatosBy extends StatefulWidget {

  final String cmd;
  const VerDatosBy({
    Key? key,
    required this.cmd
  }) : super(key: key);

  @override
  State<VerDatosBy> createState() => _VerDatosByState();
}

class _VerDatosByState extends State<VerDatosBy> {

  final _invEm = InventarioRepository();
  late final InvirtProvider _invPro;
  late final ItemSelectGlobProvider _itemSel;

  late Future<void> _prepareDatos;
  bool _isInit = false;


  @override
  void initState() {
    super.initState();
    _prepareDatos = _setData();
  }

  @override
  void dispose() {
    _itemSel.isOnlyShow = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: FutureBuilder(
        future: _prepareDatos,
        builder: (_, AsyncSnapshot snap) {

          if(snap.connectionState == ConnectionState.done) {
            return const CSolicitudesPage();
          }
          return const Texto(txt: '');
        },
      )
    );
  }

  ///
  Future<void> _setData() async {

    if(!_isInit) {
      _isInit = true;
      _invPro = context.read<InvirtProvider>();
      _itemSel = context.read<ItemSelectGlobProvider>();
      _itemSel.isOnlyShow = true;
    }

    Map<String, dynamic> cmd = _invPro.speelCmd(widget.cmd);

    await _getOrdenBy(cmd);

  }

  ///
  Future<void> _getOrdenBy(Map<String, dynamic> cmd) async {

    var item = await InventarioInjectService(em: _invEm, prov: _invPro).makeGetMap(cmd);

    if(item.isEmpty) { return; }

    OrdenEntity? ord = OrdenEntity();
    ord.fromFile(item[OrdCamp.orden.name]);
    _itemSel.idOrdenSelect = ord.id;
    _itemSel.setOrdenEntitySelect(ord);

    switch (cmd['campo']) {

      case 'orden':
        _prepareDataByOrden(item);
        break;
      case 'piezas':
        _prepareDataByPieza(item, '${cmd['eval']}');
        break;
      case 'resps':
        _prepareDataByResp(item, '${cmd['eval']}');
        break;
      default:
    }

    ord = null; item = {};
    return;
  }

  ///
  void _prepareDataByOrden(Map<String, dynamic> item) async {

    Map<String, dynamic> pzas = await _piezasGet(
      List<Map<String, dynamic>>.from(item[OrdCamp.piezas.name])
    );
    if(pzas.isNotEmpty) {
      _itemSel.piezas = List<PiezasEntity>.from(pzas['pzas']);
      _itemSel.idPzaSelect = _itemSel.piezas.first.id;
      _itemSel.fotosByPiezas = List<Map<String, dynamic>>.from(await pzas['fpzas']);
    }
  }

  ///
  void _prepareDataByPieza(Map<String, dynamic> item, String idPza) async {

    Map<String, dynamic> pzas = await _piezasGet(
      List<Map<String, dynamic>>.from(item[OrdCamp.piezas.name])
    );

    if(pzas.isNotEmpty) {
      _itemSel.piezas = List<PiezasEntity>.from(pzas['pzas']);
      final pSel = _itemSel.piezas.firstWhere(
        (element) => '${element.id}' == idPza, orElse: () => PiezasEntity(),
      );
      _itemSel.idPzaSelect = (pSel.id != 0) ?  pSel.id : _itemSel.piezas.first.id;
      _itemSel.fotosByPiezas = List<Map<String, dynamic>>.from(await pzas['fpzas']);
    }
  }

  ///
  void _prepareDataByResp(Map<String, dynamic> item, String idPza) async {

    // Convertir las piezas en respuestas
    var pzasR = List<Map<String, dynamic>>.from(item[OrdCamp.piezas.name]);
    var repsR = List<Map<String, dynamic>>.from(item[OrdCamp.resps.name]);
    if(repsR.isNotEmpty) {

      List<PiezasEntity> pzasAsRes = [];
      for (var i = 0; i < repsR.length; i++) {

        final laPza = pzasR.where((r) => r['id'] == repsR[i]['p_id']);
        if(laPza.isNotEmpty) {
          PiezasEntity pob = PiezasEntity();
          pob.fromFile(laPza.first, -1);
          String obs = 'DE: SABE\n'
          'COSTO: \$ ${repsR[i]['r_costo']}\n'
          'OBS.: ${repsR[i]['r_observs']}';
          pob.obs = obs;
          pob.fotos = List<String>.from(repsR[i]['r_fotos']);
          if(pob.fotos.isNotEmpty) {
            _itemSel.fotosByPiezas =  await _fotosGet(pob.id, pob.fotos);
          }
          pzasAsRes.add(pob);
        }
      }

      _itemSel.piezas = pzasAsRes;
      final pSel = _itemSel.piezas.firstWhere(
        (element) => '${element.id}' == idPza, orElse: () => PiezasEntity(),
      );
      _itemSel.idPzaSelect = (pSel.id != 0) ?  pSel.id : _itemSel.piezas.first.id;
    }
  }

  ///
  Future<Map<String, dynamic>> _piezasGet( List<Map<String, dynamic>> piezas ) async {

    Map<String, dynamic> resultados = {};
    List<PiezasEntity> pzas = [];

    for(var i = 0; i < piezas.length; i++) {
      PiezasEntity pz = PiezasEntity();
      pz.fromFile(piezas[i], -1);
      pzas.add(pz);
      if(pz.fotos.isNotEmpty) {
        resultados.putIfAbsent('fpzas', () async => await _fotosGet(pz.id, pz.fotos));
      }
    }

    resultados.putIfAbsent('pzas', () => pzas);
    pzas = [];
    return resultados;
  }

  ///
  Future<List<Map<String, dynamic>>> _fotosGet(int idPza, List<String> fotos) async {

    List<Map<String, dynamic>> fpzas = [];

    for (var i = 0; i < fotos.length; i++) {    
      var fp = <String, dynamic>{
        'id'  : idPza,
        'foto': (fotos[i].startsWith('http'))
          ? fotos[i] : await GetPathImages.getPathPzaTmp(fotos[i])
      };
      fpzas.add(fp);
    }

    return fpzas;
  }
}