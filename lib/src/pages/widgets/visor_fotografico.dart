import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:scp/src/services/get_path_images.dart';

import 'texto.dart';
import 'widgets_utils.dart';
import '../content/widgets/visor_fotos.dart';
import '../../providers/items_selects_glob.dart';

class VisorFotografico extends StatefulWidget {

  final List<String> fotos;
  final int initFoto;
  final String titulo;
  final String source;
  final ValueChanged<void> onClose;
  const VisorFotografico({
    Key? key,
    required this.titulo,
    required this.source,
    required this.fotos,
    required this.onClose,
    required this.initFoto
  }) : super(key: key);

  @override
  State<VisorFotografico> createState() => _VisorFotograficoState();
}

class _VisorFotograficoState extends State<VisorFotografico> {

  late final ExtendedPageController ctrPage;
  final _ftosSel = ValueNotifier<int>(0);

  late ItemSelectGlobProvider iprov;
  late Future<void> _getPath;
  String _pathFto = '';
  bool _isInit = false;
  bool _isBack = false;

  @override
  void initState() {

    ctrPage = ExtendedPageController(initialPage: widget.initFoto);
    _getPath = _getPathSegunSource();
    _ftosSel.value = widget.initFoto + 1;
    super.initState();
  }

  @override
  void dispose() {
    _ftosSel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _getPath,
      builder: (_, AsyncSnapshot snap) {

        if(_pathFto.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 250), (){
            _showVisor();
          });
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Texto(txt: 'Cargando...', isCenter: true)
          ],
        );
      },
    );
  }
  
  ///
  Widget _controles
    (BuildContext context, ItemSelectGlobProvider prov, ExtendedPageController pageCtl)
  {

    Size size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.045,
      height: size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _btn(
            () {
              Navigator.of(context).pop();
              widget.onClose(null);
            },
            Icons.close, 'CERRAR'
          ),
          _btn(
            () => prov.zoomFoto(size, size.width * 0.09, (_) {}),
            Icons.zoom_in, 'ZOOM'
          ),
          _btn(
            () => prov.dismFoto(size, size.width * 0.09, (_) {}),
            Icons.zoom_out, 'MIN.'
          ),
          _btn(
            () {
              _isBack = false;
              prov.sigFoto(pageCtl, (_) {});
            },
            Icons.arrow_circle_right_outlined, 'SIG.'
          ),
          _btn(
            () {
              _isBack = true;
              prov.backFoto(pageCtl, (_) {});
            },
            Icons.arrow_circle_left_outlined, 'ATRAS'
          ),
        ],
      ),
    );
  }

  ///
  Widget _btn(Function fnc, IconData ico, String label) {

    return InkWell(
      onTap: () => fnc(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Icon(ico, size: 35, color: Colors.green),
            Texto(txt: label, sz: 11.5),
          ],
        ),
      ),
    );
  }

  ///
  Future<void> _getPathSegunSource( ) async {

    if(!_isInit) {
      _isInit = true;
      iprov = context.read<ItemSelectGlobProvider>();
    }

    switch (widget.source) {
      case 'cotz':
        _pathFto = await GetPathImages.getPathPzaTmp('__foto__');
        break;
      case 'resp':
        _pathFto = await GetPathImages.getPathCots('__foto__');
        break;
      default:
    }

    if(_pathFto.contains('__foto__')) {
      _pathFto = _pathFto.replaceAll('__foto__', '');
    }
    iprov.fotosByPiezas = widget.fotos.map((e) => {'foto':'$_pathFto$e'}).toList();
  }

  ///
  void _showVisor() {

    WidgetsAndUtils.showAlertBody(
      context,
      titulo: widget.titulo,
      dismissible: false,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Row(
          children: [
            _controles(context, iprov, ctrPage),
            Expanded(
              child: VisorFotos(
                itemProv: iprov,
                currentFotoNum: _ftosSel,
                pageCtl: ctrPage,
                onPageChanged: (int index) async {
                  if(!_isBack) {
                    _ftosSel.value = _ftosSel.value + 1;
                  }else{
                    _ftosSel.value = _ftosSel.value - 1;
                  }
                  iprov.currentPage = index;
                },
              ),
            ),
            _controles(context, iprov, ctrPage)
          ],
        )
      )
    );
  }
}