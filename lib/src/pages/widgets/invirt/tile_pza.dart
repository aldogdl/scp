import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'tile_resps_cant.dart';
import '../../widgets/my_tool_tip.dart';
import '../../widgets/texto.dart';
import '../../../services/inventario_service.dart';
import '../../../config/sng_manager.dart';
import '../../../services/get_path_images.dart';
import '../../../providers/invirt_provider.dart';
import '../../../vars/globals.dart';

class TilePza extends StatefulWidget {

  final Map<String, dynamic> pieza;
  const TilePza({
    Key? key,
    required this.pieza
  }) : super(key: key);

  @override
  State<TilePza> createState() => _TilePzaState();
}

class _TilePzaState extends State<TilePza> {

  late InvirtProvider _invir;
  final _setStateInt = ValueNotifier<bool>(false);
  bool _isInit = false;
  List<Map<String, dynamic>> _resps = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _setStateInt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _invir = context.read<InvirtProvider>();
      _resps = List<Map<String, dynamic>>.from(widget.pieza['resps']);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          _autoparte(context),
          Column(
            children: _resps.map((rs) => _tileResp(rs)).toList(),
          )
        ],
      ),
    );
  }

  ///
  Widget _tileResp(Map<String, dynamic> rsp) {

    String label = 'Desconocido...';
    if(rsp.containsKey('cotz')) {
      if(rsp['cotz'].isNotEmpty) {
        label = rsp['cotz']['c_nombre'];
      }
    }

    label = (label.length > 20) ? '${label.substring(0, 20)}...' : label;

    return Padding(
      padding: const EdgeInsets.only(
        left: 10, top: 0, right: 0, bottom: 0
      ),
      child: Row(
        children: [
          IconButton(
            constraints: const BoxConstraints(
              maxHeight: 20, maxWidth: 20
            ),
            tooltip: 'Quitar de la cotización',
            padding: const EdgeInsets.all(0),
            onPressed: () => _delResp(rsp['r_id'], rsp['p_id']),
            icon: const Icon(Icons.close, size: 15, color: Colors.orange)
          ),
          const SizedBox(width: 8),
          MyToolTip(
            msg: '${rsp['cotz']['c_curc']}',
            child: Texto(txt: label, sz: 13, txtC: Colors.grey.withOpacity(0.6)),
          ),
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: _setStateInt,
            builder: (_, __, ___) {

              Color txtC = Colors.grey;
              if(_invir.costosSel.containsKey(rsp['p_id'])) {
                if(_invir.costosSel[rsp['p_id']]['r_id'] == rsp['r_id']) {
                  txtC = Colors.white;
                }
              }

              return TextButton(
                onPressed: (){
                  _invir.setCostosSel(
                    {
                      'p_id': rsp['p_id'],
                      'costo':{'r_id': rsp['r_id'], 'r_costo':rsp['r_costo']}
                    }
                  );
                  _setStateInt.value = !_setStateInt.value;
                },
                child: Texto(
                  txt: InventarioService.toFormat(rsp['r_costo']),
                  txtC: txtC
                ),
              );
            }
          ),
          const SizedBox(width: 5),
          Texto(txt: 'C.${rsp['r_id']}', sz: 12, txtC: Colors.green),
        ],
      ),
    );
  }

  ///
  Widget _autoparte(BuildContext context) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            context.read<InvirtProvider>().cmd = {'cmd':'vd.o.${widget.pieza['orden']}'};
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _foto(context),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              context.read<InvirtProvider>().cmd = {'cmd':'p.${widget.pieza['id']}'};
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _data(),
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _foto(BuildContext context) {

    double sf = 35.0;

    return SizedBox(
      width: 40, height: 40,
      child: Container(
        width: sf, height: sf,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(sf),
          border: Border.all(color: Colors.white)
        ),
        child: FutureBuilder(
          future: _getPathImage(widget.pieza['fotos'][0].toString()),
          builder: (_, AsyncSnapshot path) {

            if(path.connectionState == ConnectionState.done) {
              if(path.hasData) {
                
                return ClipRRect(
                  borderRadius: BorderRadius.circular(sf),
                    child: CachedNetworkImage(
                    imageUrl: path.data,
                    fit: BoxFit.cover,
                  ),
                );
              }
            }

            return const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        )
      )
    );
  }

  ///
  Widget _data() {

    String ori = widget.pieza['origen'].toString().contains('SEMINUEVA')
      ? 'S'
      : widget.pieza['origen'].toString().contains('GENERICA') ? 'G' : 'SG';

    final globals = getSngOf<Globals>();

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Texto(txt: '[ $ori ]', txtC: Colors.blue, sz: 12),
              const SizedBox(width: 5),
              Texto(txt: widget.pieza['piezaName'], txtC: Colors.white),
              const Spacer(),
              Texto(txt: 'P. ${widget.pieza['id']}', sz: 11),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Texto(txt: '${globals.lugAbr[widget.pieza['lado']]} ${widget.pieza['posicion']}', sz: 11),
              const Spacer(),
              TileRespsCant(
                idPza: widget.pieza['id'], respCant: widget.pieza['resp'],
                filename: widget.pieza['filename'], from: 'tile', idOrd: widget.pieza['orden'],
              ),
              const SizedBox(width: 8),
              Texto(txt: 'O. ${widget.pieza['orden']}', sz: 11, txtC: const Color.fromARGB(255, 240, 219, 32)),
            ],
          ),
        ],
      ),
    );
  }

  ///
  Future<String> _getPathImage(String foto) async {

    if(foto.startsWith('http')) {
      return foto;
    }else{
      return await GetPathImages.getPathPzaTmp(foto);
    }
  }

  ///
  void _delResp(int idR, int idP) {

    var cur = List<Map<String, dynamic>>.from(_invir.pzaResults);
    if(cur.isNotEmpty) {

      var pzas = cur.indexWhere((element) => element['id'] == idP);
      if(pzas != -1) {        
        var resp = List<Map<String, dynamic>>.from(cur[pzas]['resps']);
        if(resp.isNotEmpty) {
          resp.removeWhere((element) => element['r_id'] == idR);
          cur[pzas]['resps'] = resp;
          _invir.pzaResults = cur;
        }
      }
    }

    if(_invir.costosSel.containsKey(idP)) {
      _invir.costosSel.removeWhere((key, value) => key == idP);
    }
    _resps.removeWhere((element) => element['r_id'] == idR);

    if(_resps.isNotEmpty) {
      _invir.setCostosSel(
        {
          'p_id': _resps.first['p_id'],
          'costo': {'r_id':_resps.first['r_id'], 'r_costo':_resps.first['r_costo']}
        }
      );
    }

    if(mounted) {
      setState(() {});
      Future.microtask(() => _invir.rebuildLstAlmacen = !_invir.rebuildLstAlmacen);
    }
  }

}