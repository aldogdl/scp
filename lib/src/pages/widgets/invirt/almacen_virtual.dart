import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tile_resp.dart';
import 'tile_resp_image.dart';
import '../../widgets/texto.dart';
import '../../../providers/invirt_provider.dart';

class AlmacenVirtual extends StatelessWidget {

  final double maxW;
  const AlmacenVirtual({
    Key? key,
    required this.maxW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: maxW,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          _btnAddAndCant(context),
          _lin(),
          const SizedBox(height: 10),
          Expanded(
            flex: 7,
            child: _buildLstAlmacen(context)
          )
        ],
      ),
    );    
  }

  ///
  Widget _btnAddAndCant(BuildContext context) {

    final invProv = context.read<InvirtProvider>();

    return Padding(
      padding: const EdgeInsets.only(
        left: 20, top: 0, right: 0, bottom: 5
      ),
      child: Row(
        children: [
          Selector<InvirtProvider, List<Map<String, dynamic>>>(
            selector: (_, prov) => prov.cotsAlmacen,
            builder: (_, nVal, __) {
              return Texto(txt: '[${nVal.length}] AUTOPARTES EN ALMACÉN', sz: 13);
            },
          ),
          const Expanded( child: SizedBox() ),
          IconButton(
            onPressed: (){
              invProv.typeViewLst = 'grid';
              invProv.rebuildLstAlmacen = !invProv.rebuildLstAlmacen;
            },
            icon: const Icon(Icons.view_comfy_alt_outlined)
          ),
          IconButton(
            onPressed: (){
              invProv.typeViewLst = 'table';
              invProv.rebuildLstAlmacen = !invProv.rebuildLstAlmacen;
            },
            icon: const Icon(Icons.view_day_outlined)
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
  
  ///
  Widget _buildLstAlmacen(BuildContext context) {

    final invProv = context.read<InvirtProvider>();

    return Selector<InvirtProvider, bool>(
      selector: (_, prov) => prov.rebuildLstAlmacen,
      builder: (_, ref, child) {

        if(invProv.cotsAlmacen.isEmpty){ return child!; }
        return (invProv.typeViewLst == 'table')
          ? _lstViewTable(invProv)
          : _lstViewGrid(invProv);
      },
      child: const Center(
        child: Opacity(
          opacity: 0.4,
          child: Image(
            image: AssetImage('assets/logo_dark.png'),
          ),
        ),
      ),
    );
  }

  ///
  Widget _lstViewGrid(InvirtProvider invProv) {

    return SizedBox(
      width: maxW,
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: invProv.cotsAlmacen.map(
              (e) => TileResp(maxW: maxW, cot: e)
            ).toList()
          ),
        ),
      ),
    );
  }

  ///
  Widget _lstViewTable(InvirtProvider invProv) {

    return ListView.builder(
      controller: ScrollController(),
      padding: const EdgeInsets.only(right: 12, bottom: 20),
      itemCount: invProv.cotsAlmacen.length,
      itemBuilder: (_, int index) {

        final existe = invProv.pzaResults.firstWhere((e) {

          if(e['id'] == invProv.cotsAlmacen[index]['p_id']) {
            
            if(e.containsKey('resps')) {
              final resp = List<Map<String, dynamic>>.from(e['resps']);
              final hay = resp.firstWhere(
                (element) => element['r_id'] == invProv.cotsAlmacen[index]['r_id'],
                orElse: () => {}
              );
              if(hay.isNotEmpty){
                return true;
              }
            }
          }
          return false;

        }, orElse: () => {});

        return TileRespImage(
          maxW: maxW, cot: invProv.cotsAlmacen[index],
          isForSend: (existe.isNotEmpty) ? true : false,
        );
      },
    );
  }

  ///
  Widget _lin() {

    return Column(
      children: const [
        Divider(height: 2, color: Colors.black, indent: 10),
        Divider(height: 2, indent: 10),
      ],
    );
  }


}