import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'texto.dart';
import 'my_tool_tip.dart';
import '../../entity/orden_entity.dart';
import '../../providers/items_selects_glob.dart';
import '../../services/get_path_images.dart';
import '../../services/status/est_stt.dart';

const Color clrSelec = Color.fromARGB(255, 19, 84, 138);

class OrdenTile extends StatelessWidget {

  final OrdenEntity orden;
  final int cantPzas;
  const OrdenTile({
    required this.orden,
    this.cantPzas = 0,
    Key? key
  }) : super(key: key);

  final Widget sp10 = const SizedBox(width: 10);

  @override
  Widget build(BuildContext context) {

    bool isVisible = true;
    context.read<ItemSelectGlobProvider>().ordenesAsignadas.forEach((idAvo, lstOrdenes) {
      if(lstOrdenes.contains(orden.id)) {
        isVisible = false;
      }
    });

    return Visibility(
      visible: isVisible,
      child: Center(
        child: _body(context),
      ),
    );
  }

  ///
  Widget _body(BuildContext context) {

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Selector<ItemSelectGlobProvider, int>(
        selector: (_, items) => items.idOrdenSelect,
        builder: (_, idOrd, child) {

          return Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            margin: const EdgeInsets.only(top: 0, right: 15, bottom: 10, left: 5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 30, 30, 30),
              border: Border.all(
                color: (idOrd == orden.id)
                ? clrSelec : const Color.fromARGB(255, 53, 53, 53),
              ),
              borderRadius: BorderRadius.circular(5)
            ),
            child: Stack(
              children: [
                _content(),
                if(idOrd == orden.id)
                  child!
              ],
            ),
          );
        },
        child: Positioned(
          top: 0, right: 0,
          child: SizedBox(
            width: 20, height: 25,
            child: CustomPaint(
              painter: MarkSeeCurrent(),
                child: const Center(
                child: Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 12),
              ),
            )
          )
        ),
      ),
    );
  }

  ///
  Widget _content() {
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        _listTile(),
        const Divider(color: Color.fromARGB(255, 71, 71, 71), height: 1),
        const Divider(color: Colors.black, height: 1),
        Row(
          children: [
            Row(
              children: [
                const Icon(Icons.extension, size: 13, color: Colors.grey),
                Texto(txt: ' $cantPzas Pza(s).', sz: 14),
              ],
            ),
            const Spacer(),
            MyToolTip(
              msg: EstStt.getEst(orden.status()),
              child: Texto(
                txt: EstStt.getSttByEst(orden.status()), sz: 11, txtC: Colors.blue,
              ),
            )
          ],
        )
      ],
    );
  }

  ///
  Widget _listTile() {

    return ListTile(
      isThreeLine: true,
      mouseCursor: SystemMouseCursors.click,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.all(0),
      visualDensity: VisualDensity.compact,
      minLeadingWidth: 30,
      leading: _logoMarca(),
      title: Row(
        children: [
          Texto(txt: orden.modelo, isBold: true),
          sp10,
          Texto(txt: '${orden.anio}', txtC: Colors.amber),
        ],
      ),
      subtitle: Column(
        children: [
          Row(
            children: [
              Texto(txt: orden.marca, sz: 11, txtC: Colors.white),
              sp10,
              Texto(txt: (orden.isNac) ? 'NACIONAL' : 'IMPORTADO', sz: 11, txtC: Colors.white),
            ],
          ),
          Row(
            children: [
              MyToolTip(
                msg: '${orden.own} Cel: ${ orden.celular }',
                child: Texto(txt: orden.empresa, sz: 11)
              ),
              const Spacer(),
              Texto(txt: 'Ord: ${orden.id}', sz: 11, txtC: Colors.white),
            ],
          )
        ],
      )
    );
  }
  
  ///
  Widget _logoMarca() {

    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white.withOpacity(0.8)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: (orden.mkLogo == '0')
        ? const Icon(Icons.car_repair, color: Colors.black)
        : FutureBuilder(
            future: GetPathImages.getPathToLogoMarcaOf(orden.mkLogo),
            builder: (_, AsyncSnapshot dataUri) {
              if(dataUri.connectionState == ConnectionState.done) {
                if(dataUri.hasData) {
                  return CachedNetworkImage(
                    imageUrl: dataUri.data,
                    fit: BoxFit.contain,
                  );
                }
              }
              return const SizedBox();
            },
          ),
      ),
    );
  }
  
}

class MarkSeeCurrent extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    
    Path path = Path();
    Paint paint = Paint();
    paint.color = clrSelec;
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.5, size.height * 0.90);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    return canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}