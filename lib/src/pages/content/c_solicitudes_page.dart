import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:scp/src/pages/widgets/widgets_utils.dart';
import 'package:scp/src/repository/ordenes_repository.dart';
import 'package:scp/src/services/rutas/est_stt.dart';

import 'widgets/rastrear_lst_contacs.dart';
import '../widgets/frm_orden.dart';
import '../widgets/my_tool_tip.dart';
import '../widgets/pieza_tile.dart';
import '../widgets/texto.dart';
import '../../config/sng_manager.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/items_selects_glob.dart';
import '../../providers/window_cnf_provider.dart';
import '../../services/scm/scm_entity.dart';
import '../../services/scm/scm_repository.dart';
import '../../vars/intents/show_action_main.dart';
import '../../vars/globals.dart';
import '../../vars/shortcut_activators.dart';

class CSolicitudesPage extends StatefulWidget {

  const CSolicitudesPage({Key? key}) : super(key: key);

  @override
  State<CSolicitudesPage> createState() => _CSolicitudesPageState();
}

class _CSolicitudesPageState extends State<CSolicitudesPage> {

  final Globals globals = getSngOf<Globals>();
  final OrdenesRepository _ordenEm = OrdenesRepository();
  final ScmRepository _scmEm = ScmRepository();  
  
  final ExtendedPageController _pageCtl = ExtendedPageController();
  final ScrollController _scrollCtl = ScrollController();
  final ScrollController _scrollTxtCtl = ScrollController();
  final FocusNode _fcuActions = FocusNode();
  final ValueNotifier<bool> _hasFocus = ValueNotifier<bool>(false);
  final ValueNotifier<int> _currentFotoNum = ValueNotifier<int>(1);
  final ValueNotifier<String> _seccView = ValueNotifier<String>('fotos');
  List<GlobalKey<ExtendedImageGestureState>> gestureKey = [];

  late final WindowCnfProvider winCnf;
  late final ItemSelectGlobProvider itemProv;
  final double minScale = 0.03;
  final double defScale = 0.1;
  final double maxScale = 0.6;

  int calls = 0;
  int sIniFotoW = 0;
  int sIniFotoH = 0;
  int currentPage = 0;
  bool _isInit = false;

  @override
  void initState() {

    _fcuActions.addListener(() {
      _hasFocus.value = (_fcuActions.hasFocus) ? true : false;
    });
    _putFocusActions();
    super.initState();
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    _scrollCtl.dispose();
    _fcuActions.removeListener(() { });
    _fcuActions.dispose();
    _scrollTxtCtl.dispose();
    _hasFocus.dispose();
    itemProv.disposeMy();
    _currentFotoNum.dispose();
    _seccView.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      winCnf = context.read<WindowCnfProvider>();
      itemProv = context.read<ItemSelectGlobProvider>();
    }

    return Row(
      children: [
        Container(
          width: winCnf.tamMiddle,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.2))
            ),
            color: const Color.fromARGB(255, 22, 22, 22),
          ),
          child: Selector<ItemSelectGlobProvider, List<PiezasEntity>>(
            selector: (_, items) => items.piezas,
            builder: (_, pzas, __) {

              if(pzas.isEmpty) {
                return _sinData(icono: Icons.extension_off);
              }
              return _dataAndPiezas(pzas);
            },
          ),
        ),
        Expanded(
          child: Container(
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height,
            ),
            padding: const EdgeInsets.all(10),
            child: Selector<ItemSelectGlobProvider, List<Map<String, dynamic>>>(
              selector: (_, items) => items.fotosByPiezas,
              builder: (_, fotos, child) {

                if(fotos.isEmpty){ return _sinData(icono: Icons.settings_backup_restore_sharp); }
                return ValueListenableBuilder(
                  valueListenable: _seccView,
                  builder: (_, seccion, __) {

                    switch (seccion) {
                      case 'fotos':
                        return _seccionFotos();
                      case 'rastrear':
                        if(itemProv.fotosByPiezas.isNotEmpty) {
                          return RastrearLstContacs(
                            toSend: (List<int> idCotizadores) async => await _buscarCotizacion(idCotizadores),
                          );
                        }else{
                          return _sinData(icono: Icons.photo_size_select_actual_rounded, opacity: 0.2);
                        }
                      case 'rastreador':
                        if(itemProv.fotosByPiezas.isNotEmpty) {
                          return const Text('Aqui la seccion de Rasteador');
                        }else{
                          return _sinData(icono: Icons.photo_size_select_actual_rounded, opacity: 0.2);
                        }
                      default:
                        return FrmOrden(
                          onFinish: (acc) {
                            if(acc == 'add') {
                              print('adiono una nueva');
                            }
                            setState(() {
                              _seccView.value = 'fotos';
                            });
                          },
                        );
                    }
                  }
                );
              }
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _sinData({
    required IconData icono,
    double opacity = 0.5
  }) {

    return Center(
      child: Icon(
        icono, size: 150,
        color: Colors.black.withOpacity(opacity)
      ),
    );
  }

  ///
  Widget _seccionFotos() {

    return FutureBuilder(
      future: _hidratarKeysAsFotos(),
      builder: (_, AsyncSnapshot snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(itemProv.fotosByPiezas.isNotEmpty) {
            return _visorDeFotos();
          }else{
            return _sinData(icono: Icons.photo_size_select_actual_rounded, opacity: 0.2);
          }
        }
        return _loading();
      }
    );
  }

  ///
  Widget _dataAndPiezas(List<PiezasEntity> pzas) {

    return Column(
      children: [
        Selector<ItemSelectGlobProvider, int>(
          selector: (_, items) => items.idPzaSelect,
          builder: (_, idP, __) => FutureBuilder(
            future: _getDataPiezasById(),
            builder: (_, AsyncSnapshot snapDataPza) {
              if(snapDataPza.connectionState == ConnectionState.done) {
                if(snapDataPza.hasData) {
                  return _dataPza(snapDataPza.data);
                }
              }
              return _containerDataPieza(child: const SizedBox());
            },
          )
        ),
        Container(
          width: winCnf.tamMiddle,
          height: 30,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color.fromARGB(255, 49, 49, 49)
              ),
              bottom: BorderSide(
                color: Color.fromARGB(255, 3, 3, 3)
              ),
            ),
            color: Color.fromARGB(255, 27, 27, 27),
          ),
          child: Center(
            child: Texto(txt: '${pzas.length} Refacciones Solicitadas', txtC: const Color.fromARGB(255, 2, 224, 132), sz: 16,),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollCtl,
            isAlwaysShown: true,
            radius: const Radius.circular(3),
            showTrackOnHover: true,
            trackVisibility: true,
            child: ListView.builder(
              shrinkWrap: true,
              controller: _scrollCtl,
              itemCount: pzas.length,
              itemBuilder: (_, index) => PiezaTile(
                pieza: pzas[index],
                onSelect: (int idPza) {
                  int indexPz = itemProv.fotosByPiezas.indexWhere((element) => element['id'] == idPza);
                  if(_seccView.value == 'fotos') {
                    if(indexPz != -1) {
                      _pageCtl.jumpToPage(indexPz);
                    }
                  }
                  if(_seccView.value == 'editar') {
                    itemProv.piezaSelect = pzas[index];
                  }
                },
              ),
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _containerDataPieza({
    required Widget child
  }) {

    return Container(
      width: winCnf.tamMiddle,
      height: winCnf.tamMiddle,
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromARGB(255, 3, 3, 3)
          ),
        )
      ),
      child: child
    );
  }

  ///
  Widget _dataPza(PiezasEntity pza) {

    return _containerDataPieza(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollTxtCtl,
              isAlwaysShown: true,
              radius: const Radius.circular(3),
              showTrackOnHover: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollTxtCtl,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Texto(txt: pza.obs),
                ),
              ),
            )
          ),
          const Divider(color: Color.fromARGB(255, 48, 48, 48), thickness: 3, height: 20),
          Texto(txt: pza.piezaName, isBold: true, txtC: Colors.white,),
          const SizedBox(height: 5),
          Texto(txt: '${pza.posicion} ${pza.lado}', sz: 12),
          Row(
            children: [
              Texto(txt: pza.origen, sz: 10, txtC: Colors.amber),
              const Spacer(),
              Texto(txt: 'ID: ${pza.id}', sz: 13, txtC: Colors.white),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 1, height: 20),
          Container(
            constraints: const BoxConstraints.expand(
              height: 25,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _shortsCuts(),
                ValueListenableBuilder<bool>(
                  valueListenable: _hasFocus,
                  builder: (_, isFocus, __) {
                    Color cl = const Color.fromARGB(255, 13, 177, 19);
                    if(!isFocus) {
                      cl = const Color.fromARGB(255, 46, 46, 46);
                    }
                    return Positioned(
                      top: 1, left: 1,
                      child: Icon(Icons.circle_rounded, size: 5, color: cl)
                    );
                  }
                )
              ],
            ),
          ),
          const SizedBox(height: 8)
        ],
      )
    );
  }

  ///
  Widget _shortsCuts() {

    return FocusableActionDetector(
      focusNode: _fcuActions,
      autofocus: true,
      shortcuts: <ShortcutActivator, Intent>{
        sigFoto : SigFoto(),
        backFoto: BackFoto(),
        zoomFoto: ZoomFoto(),
        dismFoto: DismFoto(),
        editPza : EditPza(),
        showActionMain: ShowActionMainIntent()
      },
      actions: <Type, Action<Intent>>{
        SigFoto : CallbackAction<Intent>(onInvoke: (intent) => _sigFoto()),
        BackFoto: CallbackAction<Intent>(onInvoke: (intent) => _backFoto()),
        ZoomFoto: CallbackAction<Intent>(onInvoke: (intent) => _zoomFoto()),
        DismFoto: CallbackAction<Intent>(onInvoke: (intent) => _dismFoto()),
        EditPza : CallbackAction<Intent>(onInvoke: (intent) => _editarPieza()),
        ShowActionMainIntent: CallbackAction<Intent>(
          onInvoke: (Intent intent) => ActionShowActionMain.showActionsMain(context)
        )
      },
      child: _actionsBarr()
    );
  }

  ///
  Widget _actionsBarr() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox.expand(
            child: _actionsOrden()
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _actionsFtos(),
                ValueListenableBuilder(
                  valueListenable: _seccView,
                  builder: (_, val, child) {
                    return (val == 'fotos') ? const SizedBox() : child!; 
                  },
                  child: Positioned.fill(
                    child: Container(
                      color: const Color.fromARGB(255, 22, 22, 22)
                    )
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _actionsOrden() {

    return Row(
      children: [
        _icoAction(
          icono: (_seccView.value == 'rastrear') ? Icons.image : Icons.slow_motion_video_sharp,
          icolor: const Color.fromARGB(255, 221, 221, 221),
          tip: (_seccView.value == 'rastrear') ? 'Ver Fotos' : 'Rastrear Orden [Ctr+Alt+R]',
          fnc: () {
            String newSecc = _seccView.value;
            newSecc = (_seccView.value == 'rastrear') ? 'fotos' : 'rastrear';
            if(newSecc == 'rastrear') {
              int? status = int.tryParse(itemProv.ordenEntitySelect!.stt) ?? 0;
              if(status > 2) {
                newSecc = 'rastreador';
              }
            }
            _seccView.value = newSecc;
            setState(() {});
          },
        ),
        _icoAction(
          icono: Icons.not_interested_outlined,
          icolor: const Color.fromARGB(255, 255, 81, 81),
          tip: 'Rechazar Orden [Ctr+Alt+X]',
          fnc: () {
            
          },
        ),
        _icoAction(
          icono: Icons.edit,
          icolor: const Color.fromARGB(255, 81, 177, 255),
          tip: 'Editar Pieza [Ctr+Alt+E]',
          fnc: () => _editarPieza(),
        ),
      ],
    );
  }

  ///
  Widget _actionsFtos() {

    return Row(
      children: [
        _icoAction(
          icono: Icons.arrow_back_ios_new,
          icolor: Colors.grey,
          tip: 'Foto Anterior [Ctr+Alt+Izq]',
          fnc: () => _backFoto(),
        ),
        _icoAction(
          icono: Icons.arrow_forward_ios,
          icolor: Colors.grey,
          tip: 'Foto Siguiente [Ctr+Alt+Der]',
          fnc: () => _sigFoto(),
        ),
        _icoAction(
          icono: Icons.add_circle_outline_rounded,
          icolor: Colors.white,
          tip: 'Aumentar [Ctr+Alt+Down]',
          fnc: () => _zoomFoto(),
        ),
        _icoAction(
          icono: Icons.remove_circle_outline,
          icolor: Colors.white,
          tip: 'Disminuir [Ctr+Alt+Up]',
          fnc: () => _dismFoto(),
        )
      ],
    );
  }

  ///
  Widget _icoAction({
    required IconData icono,
    required Color icolor,
    required Function fnc,
    double iSize = 18,
    String tip = '',
  }) {

    return MyToolTip(
      msg: tip,
      child: IconButton(
        icon: Icon(icono),
        iconSize: iSize,
        color: icolor,
        constraints: const BoxConstraints(
          maxHeight: 25,
          maxWidth: 35
        ),
        onPressed: () => fnc(),
      )
    );
  }

  ///
  Widget _visorDeFotos() {

    return Stack(
      children: [

        ExtendedImageGesturePageView.builder(
          controller: _pageCtl,
          itemCount: itemProv.fotosByPiezas.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, int index) {

            return ExtendedImage.network(
              itemProv.fotosByPiezas[index]['foto'],
              printError: false,
              alignment: Alignment.topCenter,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              extendedImageGestureKey: gestureKey[index],
              initGestureConfigHandler: (ExtendedImageState state) {
                sIniFotoW = state.extendedImageInfo!.image.width;
                sIniFotoH = state.extendedImageInfo!.image.height;
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
          onPageChanged: (int index) async {

            if(itemProv.fotosByPiezas[index]['id'] != itemProv.idPzaSelect) {
              itemProv.idPzaSelect = itemProv.fotosByPiezas[index]['id'];
              _hasFocus.value = false;
              await Future.delayed(const Duration(milliseconds: 100));
              _putFocusActions();
            }
            currentPage = index;
            _currentFotoNum.value = currentPage+1;
          },
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
                valueListenable: _currentFotoNum,
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

  ///
  Future<void> _hidratarKeysAsFotos() async {

    if(itemProv.fotosByPiezas.isEmpty){ return; }

    gestureKey.clear();
    for (var i = 0; i < itemProv.fotosByPiezas.length; i++) {
      gestureKey.add(GlobalKey<ExtendedImageGestureState>());
    }
  }

  ///
  void _sigFoto() {

    if(itemProv.fotosByPiezas.isNotEmpty) {
      if(_pageCtl.page == itemProv.fotosByPiezas.length -1) {
        _pageCtl.animateToPage(_pageCtl.initialPage, duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
      }else{
        _pageCtl.nextPage(duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
      }
      _putFocusActions();
    }
  }

  ///
  void _backFoto() {

    if(itemProv.fotosByPiezas.isNotEmpty) {
      _pageCtl.previousPage(duration: const Duration(milliseconds: 100), curve: Curves.easeIn);
      _putFocusActions();
    }
  }

  ///
  void _zoomFoto() {

    if(itemProv.fotosByPiezas.isNotEmpty) {
      double nt = gestureKey[currentPage].currentState!.gestureDetails!.totalScale! + 0.5;
      gestureKey[currentPage].currentState!.gestureDetails=GestureDetails(
        actionType: ActionType.zoom,
        userOffset: true,
        offset: _calcularCentros(nt, gestureKey[currentPage].currentState!.gestureDetails!.offset!, true),
        totalScale: nt
      );
      _putFocusActions();
    }
  }

  ///
  void _dismFoto() {

    if(itemProv.fotosByPiezas.isNotEmpty) {

      if(gestureKey[currentPage].currentState!.gestureDetails!.totalScale! < 1) {
        gestureKey[currentPage].currentState!.reset();
        return;
      }
      double nt = gestureKey[currentPage].currentState!.gestureDetails!.totalScale! - 0.5;       
      gestureKey[currentPage].currentState!.gestureDetails=GestureDetails(
        actionType: ActionType.zoom,
        userOffset: true,
        offset: _calcularCentros(nt, gestureKey[currentPage].currentState!.gestureDetails!.offset!,false),
        totalScale: nt
      );
      _putFocusActions();
    }
  }

  ///
  void _editarPieza() {

    _seccView.value = (_seccView.value == 'editar') ? 'fotos' : 'editar';
    _putFocusActions();
  }

  ///
  Offset _calcularCentros(double nt, Offset current, bool isAdd) {

    double difToCW = current.dx;
    double difToCH = current.dy;
  
    if(isAdd) {

      double widthOfResto = winCnf.tamToolBar + winCnf.tamMiddle;
      double w = (widthOfResto * 100) / MediaQuery.of(context).size.width;
      double wContainer = MediaQuery.of(context).size.width * ((100 - w) / 100);
      double hContainer = MediaQuery.of(context).size.height;

      double cContainerW = wContainer / 2;
      double cContainerH = hContainer / 2;

      double centerImgWO = sIniFotoW / 2;
      double centerImgHO = sIniFotoW / 2;

      double centerImgW = (sIniFotoW * nt) / 2;
      double centerImgH = (sIniFotoH * nt) / 2;
      double difW = centerImgW - centerImgWO;
      double difH = centerImgH - centerImgHO;

      difToCW = cContainerW - difW;
      difToCH = cContainerH - difH;

      if(difToCW < -cContainerW) {
        difToCW = current.dx - (cContainerW * 0.5);
      }
      if(difToCH < -cContainerH) {
        difToCH = current.dy - (cContainerH * 0.5);
      }
    }
    return Offset(difToCW, difToCH);
  }

  ///
  Future<PiezasEntity?> _getDataPiezasById() async {

    final data = itemProv.piezas.where((element) => element.id == itemProv.idPzaSelect);
    if(data.isNotEmpty) {
      return data.first;
    }
    return null;
  }

  ///
  void _putFocusActions() {
    _fcuActions.requestFocus();
    _hasFocus.value = true;
  }

  ///
  Future<void> _buscarCotizacion(List<int> idCotizadores) async {

    int codeStatus = 1;

    await WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'Buscar Cotizaciones',
      dismissible: false,
      body: StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateIn) {
          
          return Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(codeStatus == 1)
                  ..._dialogBskOkTask((value) {
                      setStateIn((){
                        codeStatus = 2;
                      });
                    },
                  ),
                if(codeStatus == 2)
                  ..._dialogBskLoading(idCotizadores)
              ]
            ),
          );
        }
      )
    );
  }

  ///
  List<Widget> _dialogBskOkTask(ValueChanged<void> onTap) {

    String msg = 'Estás a punto de enviar esta solicitud '
    'al Servidor Central de Mensajería con el objetivo '
    'de encontrar entre los cotizadores seleccionados '
    'el mejor precio.';

    return [
      Texto(txt: msg, isCenter: true),
      const SizedBox(height: 8),
      const Texto(
        txt: '¿Estás segur@ de continuar?',
        txtC: Colors.white, isCenter: true
      ),
      const SizedBox(height: 15),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red)
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Texto(txt: 'NO ENVIAR', txtC: Colors.white)
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.purple)
            ),
            onPressed: () => onTap(null),
            child: const Texto(txt: 'SI ENVIAR', txtC: Colors.white)
          ),
        ],
      )
    ];
  }

  ///
  List<Widget> _dialogBskLoading(List<int> idCotizadores) {

    return [
      const Texto(
        txt: 'Estamos actualizando las Base de Datos, espera un momento por favor',
        isCenter: true
      ),
      const SizedBox(height: 10),
      StreamBuilder<String>(
        initialData: 'Iniciando',
        stream: _sendToCotizar(idCotizadores),
        builder: (_, AsyncSnapshot<String> snap) {

          if(snap.data!.contains('ok')) {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 1000), (){
              _seccView.value = 'rastreador';
            });
          }
          if(snap.data!.contains('ERROR') || snap.data!.isEmpty) {
            return _dialogBskHasError(snap.data);
          }else{
            return _dialogBskInProcess(snap.data);
          }
        }
      )
    ];
  }

  ///
  Widget _dialogBskInProcess(String? txt) {

    return Column(
      children: [
        const SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator()
        ),
        const SizedBox(height: 10),
        Texto(txt: txt ?? '', isCenter: true, txtC: Colors.white)
      ],
    );
  }

  ///
  Widget _dialogBskHasError(String? txt) {

    return Column(
      children: [
        Texto(txt: txt ?? '', isCenter: true),
        const SizedBox(height: 15),
        const Texto(
          txt: 'POR FAVOR INTÉNTALO DE NUEVO',
          txtC: Colors.amber,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red)
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Texto(txt: 'ENTENDIDO', txtC: Colors.white)
        ),
      ],
    );
  }

  ///
  Stream<String> _sendToCotizar(List<int> idCotizadores) async* {

    final scm = ScmEntity();
    var data = scm.jsonToCotizar(
      idOrden: itemProv.idOrdenSelect,
      idOwn: itemProv.ordenEntitySelect!.uId,
      idAvo: globals.idUser
    );
    
    final version = DateTime.now().millisecondsSinceEpoch;
    await Future.delayed(const Duration(milliseconds: 2000));

    // Guardamos en la base de datos remota el registro de la orden de busqueda
    // para la SCM, solo para que ya este enterada de un nuevo mensaje.
    // NOTA: No es necesario que el registro este en la BD local, ya que solo es
    // utilizado por la SCM para enterarce de una nueva tarea.
    yield 'Enviando al Servidor Principal';
    
    await _scmEm.setBuscarCotizacionesOrden(data, isLocal: false);
    if(!_scmEm.result['abort']) {

      yield 'Actualizaremos Status de la Orden';
      final oStt = await EstStt.getNextSttByEst(itemProv.ordenEntitySelect!.status());
      data = {
        'orden': itemProv.idOrdenSelect,
        'version': 0,
        'est': oStt['est'],
        'stt': oStt['stt'],
        'rta': oStt['rta']
      };
      
      // Actualizamos el Status de la orden en el archivo centinela tanto en
      // remoto como en local para que HARBI actualice las aplicaciones.
      await Future.delayed(const Duration(milliseconds: 500));
      yield 'Actualizando Orden en LOCAL';
      await _ordenEm.changeStatusToServer(data, isLocal: true);
      yield 'Actualizando Orden en REMOTO';
      await _ordenEm.changeStatusToServer(data, isLocal: false);
      
      if(!_ordenEm.result['abort']) {

        yield 'Las Piezas obtendrán un nuevo Status.';
        final pStt = await EstStt.getFirstSttByEstBusqueda(itemProv.ordenEntitySelect!.status());
        data = {
          'version': version,
          'orden': itemProv.idOrdenSelect,
          'est': pStt['est'],
          'stt': pStt['stt'],
          'rta': pStt['rta'],
          'cotz': idCotizadores,
        };

        await Future.delayed(const Duration(milliseconds: 500));
        yield 'Actualizando Piezas en LOCAL.';
        await _ordenEm.buildStatusForBuscarPiezas(data, isLocal: true);
        yield 'Actualizando Piezas en REMOTO.';
        await _ordenEm.buildStatusForBuscarPiezas(data, isLocal: false);

        if(!_ordenEm.result['abort']) {
          yield 'ok';
        }else{
          yield '${_scmEm.result['body']}';
        }
      }else{
        yield '${_scmEm.result['body']}';
      }
    }else{
      yield '${_scmEm.result['body']}';
    }
  }

}