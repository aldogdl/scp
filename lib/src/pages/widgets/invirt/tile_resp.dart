import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/my_tool_tip.dart';

import 'tile_resp_check_pza.dart';
import '../../widgets/texto.dart';
import '../../../providers/invirt_provider.dart';
import '../../../services/inventario_service.dart';

class TileResp extends StatelessWidget {

  final double maxW;
  final Map<String, dynamic> cot;
  const TileResp({
    Key? key,
    required this.maxW,
    required this.cot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    double w = (maxW/3) - 20;
    
    return Container(
      width: w,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.2
      ),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.blueGrey)
      ),
      child: (cot.isNotEmpty) ? _conData(context) : _sinData(),
    );
  }

  ///
  Widget _conData(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _foto(MediaQuery.of(context).size.height),
        _cstUtl(),
        _dataPza(context),
        _dataAuto(context),
      ],
    );
  }

  ///
  Widget _sinData() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Icon(Icons.safety_check, size: 150, color: Color.fromARGB(255, 34, 34, 34)),
      ],
    );
  }

  ///
  Widget _foto(double alto) {

    double w = (maxW/3) - 20;
    final fotos = cot['r_fotos'];
    String foto = '';
    if(fotos.isNotEmpty) {
      foto = fotos.first;
    }

    return Stack(
      children: [
        SizedBox(
          width: w,
          height: alto * 0.15,
          child: AspectRatio(
            aspectRatio: 1024/768,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
              child: FutureBuilder<String>(
                future: InventarioService.getPathImage(foto),
                builder: (_, AsyncSnapshot<String> path) {

                  if(path.connectionState == ConnectionState.done) {
                    return CachedNetworkImage(
                      imageUrl: path.data!,
                      fit: BoxFit.cover,
                    );
                  }
                  return const SizedBox();
                },
              )
            ),
          ),
        ),
      ],
    );
  }

  ///
  Widget _cstUtl() {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 43, 43, 43),
      ),
      child: Row(
        children: [
          Texto(
            txt: InventarioService.toFormat('${cot['r_costo']}'),
            txtC: const Color.fromARGB(255, 255, 244, 149),
            isBold: false, sz: 13,
          ),
          const Spacer(),
          const Texto(
            txt: 'PSUG:', sz: 11,
            width: 19,
            txtC: Colors.white
          ),
          const SizedBox(width: 5),
          Texto(
            txt: InventarioService.toFormat(cot['r_precio']), sz: 11,
            width: 19,
            txtC: Colors.white
          ),
        ],
      ),
    );
  }
  
  ///
  Widget _dataPza(BuildContext context) {

    final invProv = context.read<InvirtProvider>();
    final pza = invProv.pzaResults.firstWhere(
      (p) => p['id'] == cot['p_id'], orElse: () => {}
    );
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Texto(
                txt: (pza.isNotEmpty) ? pza['piezaName'] : '',
                width: 19,
                txtC: Colors.white
              ),
              const Spacer(),
              const Icon(Icons.star, size: 15, color: Colors.yellow),
              const SizedBox(width: 5),
              Texto(
                txt: InventarioService.calcUtilidad('${cot['r_costo']}', '${cot['r_precio']}'), sz: 11,
                txtC: Colors.white
              ),
            ],
          ),
          const SizedBox(height: 8),
          Texto(
            txt: (pza.isNotEmpty)
            ? '${pza['lado']} ${pza['posicion']}' : '', sz: 11,
            width: 19,
            txtC: Colors.white.withOpacity(0.4)
          ),
        ],
      ),
    );
  }

  ///
  Widget _dataAuto(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          TileRespCheckPza(
            data: {
              'orden': cot['o_id'],
              'pieza': cot['p_id'],
              'cot': cot['r_id'],
              'piezaName': ''
            },
            onCheck: (val) {
              // TODO Que hacer al seleccionar esta
            }
          ),
          MyToolTip(
            msg: 'cmd:<pull.${cot['r_id']}>',
            child: _btn(
              Icons.close,
              'Quitar Cotización',
              c: const Color.fromARGB(255, 255, 74, 29),
              padd: 0,
              fnc: () {
                final invProv = context.read<InvirtProvider>();
                invProv.cmd = {'cmd':'pull.${cot['r_id']}'};
              }
            ),
          ),
          const Spacer(),
          Texto(
            txt: 'C: ${cot['r_id']}',
            txtC: const Color.fromARGB(255, 255, 255, 255),
            isBold: false, sz: 13,
          ),
          const SizedBox(width: 10),
          Texto(
            txt: 'P: ${cot['p_id']}',
            txtC: const Color.fromARGB(255, 165, 165, 165),
            isBold: false, sz: 13,
          ),
          const SizedBox(width: 10),
          Texto(
            txt: 'O: ${cot['o_id']}',
            txtC: const Color.fromARGB(255, 240, 219, 32),
            isBold: false, sz: 13,
          ),
          const SizedBox(width: 10),
          // Color.fromARGB(255, 44, 233, 50)
          _btn(
            Icons.check,
            'Cotizacion en Almacen',
            c: const Color.fromARGB(255, 87, 87, 87),
            padd: 0,
            fnc: (){}
          ),
        ],
      ),
    );
  }

  ///
  Widget _btn(IconData ico, String tip, {
    required Color c, required Function fnc, double padd = 8
  }) {

    return Padding(
      padding: EdgeInsets.only(right: padd),
      child: MouseRegion(
        child: IconButton(
          icon: Icon(ico, size: 15, color: c),
          iconSize: 15,
          onPressed: () => fnc(),
          tooltip: tip,
          padding: const EdgeInsets.all(0),
          constraints: const BoxConstraints(
            maxWidth: 40, maxHeight: 18, minWidth: 30
          ),
        ),
      )
    );
  }

}