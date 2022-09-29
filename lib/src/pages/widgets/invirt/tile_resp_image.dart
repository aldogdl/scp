import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../texto.dart';
import '../my_tool_tip.dart';
import '../visor_fotografico.dart';
import '../../../services/inventario_service.dart';

class TileRespImage extends StatelessWidget {

  final double maxW;
  final Map<String, dynamic> cot;
  final bool isForSend;
  const TileRespImage({
    Key? key,
    required this.maxW,
    required this.cot,
    required this.isForSend,
  }) : super(key: key);

  
  @override
  Widget build(BuildContext context) {

    return Container(
      width: maxW,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          _laData(),
          _lstFotosContainer(context),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.green),
                bottom: BorderSide(color: Colors.green)
              )
            ),
            child: Row(
              children: [
                const Icon(Icons.comment, size: 18),
                const SizedBox(width: 8),
                Texto(txt: cot['r_observs'])
              ],
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _laData() {

    String por = '...';
    String porTip = '...';
    if(cot.containsKey('cotz')) {
      if(cot['cotz'].isNotEmpty) {
        por = cot['cotz']['e_nombre'];
        porTip = cot['cotz']['c_nombre'];
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [        
        const Texto(
          txt: '[ ',
          txtC: Color.fromARGB(255, 255, 255, 255),
          isBold: false, sz: 13,
        ),
        Texto(
          txt: 'C: ${cot['r_id']}',
          txtC: const Color.fromARGB(255, 255, 255, 255),
          isBold: false, sz: 13,
        ),
        _sw(10),
        Texto(
          txt: 'P: ${cot['p_id']}',
          txtC: const Color.fromARGB(255, 194, 194, 194),
          isBold: false, sz: 13,
        ),
        _sw(10),
        Texto(
          txt: 'O: ${cot['o_id']}',
          txtC: const Color.fromARGB(255, 240, 219, 32),
          isBold: false, sz: 13,
        ),
        const Texto(
          txt: ' ]',
          txtC: Color.fromARGB(255, 255, 255, 255),
          isBold: false, sz: 13,
        ),
        _sw(10),
        MyToolTip(
          msg: porTip,
          child: Texto(
            txt: 'POR: $por',
            txtC: const Color.fromARGB(255, 255, 244, 149),
            isBold: false, sz: 13,
          ),
        ),
        const Spacer(),
        Texto(
          txt: InventarioService.toFormat('${cot['r_costo']}'),
          txtC: const Color.fromARGB(255, 255, 255, 255),
          isBold: false, sz: 13,
        ),
        _sw(10),
        Texto(
          txt: 'PSUG: ${ InventarioService.toFormat('${cot['r_precio']}') }',
          txtC: const Color.fromARGB(255, 255, 244, 149),
          isBold: false, sz: 13,
        ),
        _sw(10),
        const Icon(Icons.star, size: 15, color: Colors.yellow),
        _sw(5),
        Texto(
          txt: InventarioService.calcUtilidad('${cot['r_costo']}', '${cot['r_precio']}'),
          txtC: const Color.fromARGB(255, 116, 116, 116),
          isBold: false, sz: 13,
        ),
      ],
    );
  }

  ///
  Widget _lstFotosContainer(BuildContext context) {

    var fotos = [];
    if(cot.containsKey('r_fotos')) {
      fotos = cot['r_fotos'];
    }
    final cantFotos = fotos.length;
    fotos = [];

    return Container(
      constraints: BoxConstraints.expand(
        width: maxW,
        height: MediaQuery.of(context).size.height * 0.15,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.black.withOpacity(0.8)
          ),
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.8)
          )
        )
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _carrusel(context),
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: Container(
              width: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFF1b1b1b)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              ),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: Container(
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 27, 27, 27),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8)
                )
              ),
              child: Center(
                child: Texto(txt: '$cantFotos'),
              ),
            )
          ),
          if(isForSend)
            Positioned(
              top: 0, left: 0,
              child: Container(
                height: 25,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 235, 59),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(8)
                  ),
                  border: Border.all(color: const Color.fromARGB(255, 27, 27, 27)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)
                  ]
                ),
                child: const Center(
                  child: Icon(
                    Icons.done_all, color: Color.fromARGB(255, 0, 0, 0), size: 18,
                  ),
                ),
              )
            )
        ],
      ),
    );
  }

  ///
  Widget _carrusel(BuildContext context) {

    var fotos = [];
    if(cot.containsKey('r_fotos')) {
      fotos = cot['r_fotos'];
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: fotos.length,
      itemBuilder: (_, int index) => InkWell(
        onTap: () {
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => SimpleDialog(
              children: [
                VisorFotografico(
                  initFoto: index,
                  source: 'resp',
                  titulo: cot['r_observs'],
                  fotos: List<String>.from(fotos),
                  onClose: (_) => Navigator.of(context).pop(),
                )
              ],
            )
          );
          
        },
        child: _img(context, fotos[index]),
      ),
    );
  }

  ///
  Widget _img(BuildContext context, String foto) {

    double w = (maxW/3) - 20;

    return Padding(
      padding: const EdgeInsets.only(
        right: 5
      ),
      child: SizedBox(
        width: w,
        height: MediaQuery.of(context).size.height * 0.15,
        child: AspectRatio(
          aspectRatio: 1024/768,
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
    );
  }

  ///
  Widget _sw(double sep) => SizedBox(width: sep);
  
}