import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:scp/src/pages/content/widgets/sin_data.dart';

import '../../../providers/items_selects_glob.dart';
import '../../widgets/texto.dart';

class VisorFotos extends StatelessWidget {

  final ItemSelectGlobProvider itemProv;
  final ExtendedPageController pageCtl;
  final ValueNotifier<int> currentFotoNum;
  final ValueChanged<int> onPageChanged;
  const VisorFotos({
    Key? key,
    required this.itemProv,
    required this.pageCtl,
    required this.currentFotoNum,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: itemProv.hidratarKeysAsFotos(),
      builder: (_, AsyncSnapshot snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(itemProv.fotosByPiezas.isNotEmpty) {
            return MouseRegion(
              cursor: SystemMouseCursors.move,
              child: _visorDeFotos(),
            );
          }else{
            return const SinData(icono: Icons.photo_size_select_actual_rounded, opacity: 0.2);
          }
        }
        return _loading();
      }
    );
  }

  ///
  Widget _visorDeFotos() {

    return Stack(
      children: [

        ExtendedImageGesturePageView.builder(
          controller: pageCtl,
          itemCount: itemProv.fotosByPiezas.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, int index) {

            return ExtendedImage.network(
              itemProv.fotosByPiezas[index]['foto'],
              printError: false,
              alignment: Alignment.topCenter,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              extendedImageGestureKey: itemProv.gestureKey[index],
              initGestureConfigHandler: (ExtendedImageState state) {
                itemProv.sIniFotoW = state.extendedImageInfo!.image.width;
                itemProv.sIniFotoH = state.extendedImageInfo!.image.height;
                return GestureConfig(
                  minScale: 0.9,
                  animationMinScale: 0.7,
                  maxScale: 4.0,
                  animationMaxScale: 4.5,
                  speed: 1.0,
                  inertialSpeed: 100.0,
                  initialScale: 1.0,
                  inPageView: false,
                  initialAlignment: InitialAlignment.center,
                  reverseMousePointerScrollDirection: true,
                );
              },
              enableSlideOutPage: true,
            );
          },
          onPageChanged: (int index) => onPageChanged(index),
        ),
        Positioned(
          child: Container(
            height: 35,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              )
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<int>(
                valueListenable: currentFotoNum,
                builder: (_, val, __) {
                  return Texto(
                    txt: 'Visualizando la foto $val de ${itemProv.fotosByPiezas.length}',
                    txtC: Colors.yellow,
                  );
                },
              ),
            ),
          )
        )
      ]
    );
  }

  ///
  Widget _loading() {

    return const Center(
      child: SizedBox(
        height: 40, width: 40,
        child: CircularProgressIndicator(),
      ),
    );
  }

}