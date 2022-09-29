import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';

import 'widgets/data_basic_pza.dart';
import 'widgets/dialog_rastrear_cot.dart';
import 'widgets/sin_data.dart';
import 'widgets/visor_fotos.dart';
import '../widgets/frm_orden.dart';
import '../widgets/my_tool_tip.dart';
import '../widgets/pieza_tile.dart';
import '../widgets/texto.dart';
import '../../config/sng_manager.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/pages_provider.dart';
import '../../providers/items_selects_glob.dart';
import '../../providers/window_cnf_provider.dart';
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
  
  final _pageCtl = ExtendedPageController();
  final _scrollCtl = ScrollController();
  final _scrollTxtCtl = ScrollController();
  final _fcuActions = FocusNode();
  final _hasFocus = ValueNotifier<bool>(false);
  final _currentFotoNum = ValueNotifier<int>(1);
  final _seccView = ValueNotifier<String>('fotos');
  
  late final WindowCnfProvider winCnf;
  late final ItemSelectGlobProvider itemProv;

  final double minScale = 0.03;
  final double defScale = 0.1;
  final double maxScale = 0.6;

  int calls = 0;
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
    _currentFotoNum.dispose();
    _seccView.dispose();
    itemProv.disposeMy();
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
                return const SinData(icono: Icons.extension_off);
              }
              return _dataAndPiezas();
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
              builder: (_, fotos, __) {

                if(fotos.isEmpty){
                  return const SinData(icono: Icons.settings_backup_restore_sharp);
                }

                return ValueListenableBuilder<String>(
                  valueListenable: _seccView,
                  builder: (_, seccion, __) => _determinarWidget(seccion)
                );
              }
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _determinarWidget(String seccion) {

    switch (seccion) {

      case 'fotos':
        return VisorFotos(
          itemProv: itemProv,
          currentFotoNum: _currentFotoNum,
          pageCtl: _pageCtl,
          onPageChanged: (int index) async {

            if(itemProv.fotosByPiezas[index]['id'] != itemProv.idPzaSelect) {
              itemProv.idPzaSelect = itemProv.fotosByPiezas[index]['id'];
              _hasFocus.value = false;
              await Future.delayed(const Duration(milliseconds: 100));
              _putFocusActions();
            }
            itemProv.currentPage = index;
            _currentFotoNum.value = itemProv.currentPage+1;

          },
        );
      default:
        return FrmOrden(
          onFinish: (acc) {
            if(acc == 'add') {
              // TODO adiciono una nueva
            }
            setState(() {
              _seccView.value = 'fotos';
            });
          },
        );
    }
  }

  ///
  Widget _dataAndPiezas() {

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
            child: Texto(
              txt: '${itemProv.piezas.length} Autopartes Solicitadas',
              txtC: const Color.fromARGB(255, 2, 224, 132),
              sz: 16
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollCtl,
            thumbVisibility: true,
            radius: const Radius.circular(3),
            trackVisibility: true,
            child: ListView.builder(
              shrinkWrap: true,
              controller: _scrollCtl,
              physics: const BouncingScrollPhysics(),
              itemCount: itemProv.piezas.length,
              itemBuilder: (_, index) => PiezaTile(
                pieza: itemProv.piezas[index],
                onSelect: (int idPza) {
                  _selectPieza(idPza);
                  _putFocusActions();
                },
              ),
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _containerDataPieza({ required Widget child }) {

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
        children: [
          Expanded(
            child: DataBasicPza(pza: pza, scrollTxtCtl: _scrollTxtCtl),
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
        prevPza : PrevPza(),
        nextPza : NextPza(),
        salirPop: SalirPop(),
        showActionMain: ShowActionMainIntent()
      },
      actions: <Type, Action<Intent>>{
        SigFoto : CallbackAction<Intent>(onInvoke: (intent) => itemProv.sigFoto(
          _pageCtl, (_) => _putFocusActions()
        )),
        BackFoto : CallbackAction<Intent>(onInvoke: (intent) => itemProv.backFoto(
          _pageCtl, (_) => _putFocusActions()
        )),
        ZoomFoto: CallbackAction<Intent>(onInvoke: (intent) => itemProv.zoomFoto(
          MediaQuery.of(context).size, winCnf.tamMiddle, (_) {
            _putFocusActions();
          }
        )),
        SalirPop: CallbackAction<Intent>(onInvoke: (intent) {
          if(itemProv.isOnlyShow) {
            Navigator.of(context).pop();
          }
          return (){};
        }),
        DismFoto: CallbackAction<Intent>(onInvoke: (intent) => itemProv.dismFoto(
          MediaQuery.of(context).size, winCnf.tamMiddle, (_) {
            _putFocusActions();
          }
        )),
        EditPza : CallbackAction<Intent>(onInvoke: (intent) => _editarPieza()),
        PrevPza : CallbackAction<Intent>(onInvoke: (intent) => _getPrevPieza()),
        NextPza : CallbackAction<Intent>(onInvoke: (intent) => _getNextPieza()),
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
            child: (itemProv.isOnlyShow)
              ? _btnSalirPop() : _actionsOrden()
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
  Widget _btnSalirPop() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 5),
        SizedBox(
          height: 20,
          child: MyToolTip(
            msg: 'Ctrl+shift+O',
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
                elevation: MaterialStateProperty.all(0),
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 5)),
                visualDensity: VisualDensity.compact
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Texto(txt: 'CERRAR VENTANA', sz: 13, txtC: Colors.white)
            )
          )
        )
      ],
    );
  }

  ///
  Widget _actionsOrden() {

    return Row(
      children: [
        DialogRastrearCot(
          onEmptyList: (_) {
            context.read<PageProvider>().refreshLsts = true;
            if(mounted) {
              setState(() {});
            }
          },
        ),
        _icoAction(
          icono: Icons.not_interested_outlined,
          icolor: const Color.fromARGB(255, 255, 81, 81),
          tip: 'Rechazar Orden [Ctr+Alt+X]',
          fnc: () async {},
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
          fnc: () => itemProv.backFoto(
            _pageCtl, (_) => _putFocusActions()
          ),
        ),
        _icoAction(
          icono: Icons.arrow_forward_ios,
          icolor: Colors.grey,
          tip: 'Foto Siguiente [Ctr+Alt+Der]',
          fnc: () => itemProv.sigFoto(
            _pageCtl, (_) => _putFocusActions()
          ),
        ),
        _icoAction(
          icono: Icons.add_circle_outline_rounded,
          icolor: Colors.white,
          tip: 'Aumentar [Ctr+Alt+Down]',
          fnc: () => itemProv.zoomFoto(
            MediaQuery.of(context).size, winCnf.tamMiddle, (_) {
              _putFocusActions();
            }
          ),
        ),
        _icoAction(
          icono: Icons.remove_circle_outline,
          icolor: Colors.white,
          tip: 'Disminuir [Ctr+Alt+Up]',
          fnc: () => itemProv.dismFoto(
            MediaQuery.of(context).size, winCnf.tamMiddle, (_) {
              _putFocusActions();
            }
          ),
        )
      ],
    );
  }

  ///
  Widget _icoAction
    ({required IconData icono,
    required Color icolor,
    required Function fnc,
    double iSize = 18,
    String tip = ''})
 {

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
  void _getPrevPieza() {

    int indexPz = itemProv.piezas.indexWhere((element) => element.id == itemProv.idPzaSelect);
    indexPz = indexPz-1;
    indexPz = (indexPz < 0) ? 0 : indexPz;
    int idPza = -1;
    if(indexPz <= (itemProv.piezas.length-1)) {
      idPza = itemProv.piezas[indexPz].id;
    }else{
      idPza = itemProv.piezas.last.id;
    }
    _selectPieza(idPza);
  }

  ///
  void _getNextPieza() {

    int indexPz = itemProv.piezas.indexWhere((element) => element.id == itemProv.idPzaSelect);
    indexPz = indexPz+1;
    int idPza = -1;
    if(indexPz <= (itemProv.piezas.length-1)) {
      idPza = itemProv.piezas[indexPz].id;
    }else{
      idPza = itemProv.piezas.first.id;
    }
    _selectPieza(idPza);
  }

  ///
  void _selectPieza(int idPza) {

    int indexPz = itemProv.fotosByPiezas.indexWhere((element) => element['id'] == idPza);
    if(_seccView.value == 'fotos') {
      if(indexPz != -1) {
        _pageCtl.jumpToPage(indexPz);
      }
    }
    if(_seccView.value == 'editar') {
      itemProv.piezaSelect = itemProv.piezas[indexPz];
      itemProv.idPzaSelect = idPza;
    }
  }

  ///
  void _editarPieza() {

    _seccView.value = (_seccView.value == 'editar') ? 'fotos' : 'editar';
    _putFocusActions();
  }

  ///
  void _putFocusActions() {
    _fcuActions.requestFocus();
    _hasFocus.value = true;
  }

  ///
  Future<PiezasEntity?> _getDataPiezasById() async {

    final data = itemProv.piezas.where((e) => e.id == itemProv.idPzaSelect);

    if(data.isNotEmpty) {
      return data.first;
    }
    return null;
  }

}