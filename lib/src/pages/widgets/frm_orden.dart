import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:blur/blur.dart';

import 'loading_middle.dart';
import 'widgets_utils.dart';
import 'texto.dart';
import '../content/config_sections/widgets/decoration_field.dart';
import '../../config/sng_manager.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/items_selects_glob.dart';
import '../../repository/ordenes_repository.dart';
import '../../services/get_content_files.dart';
import '../../vars/globals.dart';


class FrmOrden extends StatefulWidget {

  final ValueChanged<String> onFinish;
  /// Saber de donde fué solicitado este widget
  /// y saber si se puede editar los datos del auto.
  final String from;
  const FrmOrden({
    Key? key,
    required this.onFinish,
    this.from = 'check',
  }) : super(key: key);

  @override
  State<FrmOrden> createState() => _FrmOrdenState();
}

class _FrmOrdenState extends State<FrmOrden> {

  final Globals _globals = getSngOf<Globals>();
  final GlobalKey<FormState> _frmKey = GlobalKey<FormState>();
  final OrdenesRepository _ordEm = OrdenesRepository();
  final ValueNotifier<int> _idPza = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isNac = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _refreshFotos = ValueNotifier<bool>(true);

  final TextEditingController _ctrPieza = TextEditingController();
  final TextEditingController _ctrPos = TextEditingController();
  final TextEditingController _ctrLad = TextEditingController();
  final TextEditingController _ctrDet = TextEditingController();
  final TextEditingController _ctrOri = TextEditingController();

  final FocusNode _fcsPieza = FocusNode();
  final FocusNode _fcsPos = FocusNode();
  final FocusNode _fcsLad = FocusNode();
  final FocusNode _fcsDet = FocusNode();
  final FocusNode _fcsOri = FocusNode();

  final ScrollController _scrollFotos = ScrollController();
  late final ItemSelectGlobProvider _items;
  late Future _getDatos;

  List<Map<String, dynamic>> autos = [];
  List<Map<String, dynamic>> _fotosCurrents = [];
  int idMark = 0;
  int idModl = 0;
  int anio = 0;
  bool _loading = false;

  @override
  void initState() {
    _getDatos = _getDatosByOrdenAndPieza();
    super.initState();
  }

  @override
  void dispose() {
    _scrollFotos.dispose();
    _ctrPieza.dispose();
    _fcsPieza.dispose();
    _isNac.dispose();
    _idPza.dispose();
    _ctrLad.dispose();
    _ctrDet.dispose();
    _ctrOri.dispose();
    _fcsLad.dispose();
    _fcsDet.dispose();
    _fcsOri.dispose();
    _refreshFotos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _getDatos,
      builder: (_, AsyncSnapshot snapshot) {

        if(snapshot.hasData) {
          if(snapshot.data) {
            return _body();
          }else{
            return const Center(child: Texto(txt: 'No se encontró la pieza'));    
          }
        }
        return const Center(child: Texto(txt: 'Cargando...'));
      }
    );
  }
  
  ///
  Widget _body() {

    Widget child = (_loading) ? _frmWithBlur(child: _frm()) : _frm();
    
    return Column(
      children: [
        _containerFotos(),
        const Divider(color: Colors.green, height: 1),
        Expanded(
          child: child,
        )
      ],
    );
  }

  ///
  Widget _frmWithBlur({required Widget child}) {

    return Blur(
      blur: (_loading) ? 2.5 : 0, colorOpacity: 0,
      blurColor: Colors.black,
      overlay: const LoadingMiddle(msg: 'y Guardando DATOS...'),
      child: child,
    );
  }

  ///
  Widget _frm() {

    return Form(
      key: _frmKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        descendantsAreFocusable: true,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              _dataAuto(),
              const SizedBox(width: 10),
              _dataPieza()
            ],
          ),
        )
      ),
    );
  }

  ///
  List<Widget> _div() {
    return const [
      SizedBox(height: 10),
      Divider(color: Color.fromARGB(255, 0, 0, 0), height: 2),
      Divider(color: Color.fromARGB(255, 78, 78, 78), height: 1),
      SizedBox(height: 10),
    ];
  }

  ///
  Widget _dataAuto() {

    return Expanded(
      flex: 2,
      child: (widget.from == 'check')
      ? GestureDetector(
        onTap: () async {
          await WidgetsAndUtils.showAlert(
            context,
            titulo: 'Revisando Datos de la solicitud',
            msg: 'Lo sentimos, no puedes editar los datos del auto de esta '
            'orden, ya que la sección de revisión permite cambiar sólo '
            'datos mal formateados de la refacción seleccionada.'
          );
        },
        child: Blur(
          blur: 0,
          colorOpacity: 0,
          overlay: const SizedBox(),
          child: _inputsAuto(),
        ),
      )
      : _inputsAuto()
    );
  }
  
  ///
  Widget _inputsAuto() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.center,
          child: Texto(txt: 'Datos del Auto', txtC: Colors.blue, sz: 18),
        ),
        ..._div(),
        FocusTraversalOrder(
          order: const NumericFocusOrder(1),
          child: _auto('marca'),
        ),
        const SizedBox(height: 10),
        FocusTraversalOrder(
          order: const NumericFocusOrder(2),
          child: _auto('modelo'),
        ),
        const SizedBox(height: 10),
        FocusTraversalOrder(
          order: const NumericFocusOrder(3),
          child: _auto('anio'),
        ),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.center,
          child: Texto(txt: 'EL VEHÍCULO ES...', isCenter: true),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isNac,
          builder: (_, isNacio, __) {
            return Row(
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: _checkNac(value: isNacio),
                ),
                const Texto(txt: 'NACIONAL', isCenter: true, txtC: Colors.white),

                const Spacer(),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: _checkNac(value: !isNacio),
                ),
                const Texto(txt: 'IMPORTADO', isCenter: true, txtC: Colors.white),
              ],
            );
          }
        ),
        if(_items.ordenEntitySelect != null)
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Texto(
                  txt: 'DATOS DEL SOLICITANTE', isCenter: true,
                  txtC: Colors.blue
                ),
                const Divider(height: 5),
                _tileDataSol(
                  _items.ordenEntitySelect!.own,
                  'ID: ${_items.ordenEntitySelect!.uId} - Nombre del Solicitante'
                ),
                _tileDataSol(_items.ordenEntitySelect!.empresa, 'Nombre de la Empresa'),
                _tileDataSol(
                  _items.ordenEntitySelect!.celular, 'Número de Celular'
                ),
              ],
            )
          )
      ],
    );
  }
  
  ///
  Widget _checkNac({required value}) {

    return Checkbox(
      value: value,
      checkColor: Colors.white,
      activeColor: Colors.transparent,
      onChanged: (val) {
        _isNac.value = !_isNac.value;
      }
    );
  }

  ///
  Widget _dataPieza() {

    return Expanded(
      flex: 3,
      child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _idPza,
              builder: (_, id, __) {
                return Texto(
                  txt: 'Datos de la Pieza [ID: $id]', 
                  txtC: Colors.blue, sz: 18,
                );
              }
            ),
            ..._div(),
            Expanded(
              child: Selector<ItemSelectGlobProvider, PiezasEntity>(
                selector: (_, prov) => prov.piezaSelect!,
                builder: (_, pza, __) {

                  if(mounted) {
                    Future.delayed(const Duration(milliseconds: 600), (){
                      _ctrPieza.text = pza.piezaName;
                      _ctrPos.text = pza.posicion;
                      _ctrLad.text = pza.lado;
                      _ctrDet.text = pza.obs;
                      _ctrOri.text = pza.origen;
                      _idPza.value = pza.id;
                    });
                  }

                  return _inputsDataPza();
                }
              ),
            )
            
          ],
        )
    );
  }

  ///
  Widget _inputsDataPza() {

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DecorationField.fieldBy(
                ctr: _ctrPieza,
                fco: _fcsPieza,
                orden: 6,
                help: 'Nombre de la Pieza',
                validate: (val){},
                iconoPre: Icons.extension,
              ),
            ),
            const SizedBox(width: 10),
            Align(
              alignment: Alignment.center,
              child: Center(
                child: IconButton(
                  constraints: const BoxConstraints(
                    maxHeight: 25
                  ),
                  iconSize: 25,
                  padding: const EdgeInsets.all(0),
                  visualDensity: VisualDensity.compact,
                  onPressed: (){},
                  icon: const Icon(Icons.add)
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        DecorationField.dropBy(
          fco: _fcsPos,
          items: _globals.posic,
          onChange: (val){
            _ctrPos.text = val!;
          },
          defaultValue: (_ctrPos.text.isEmpty) ? _globals.posic.first : _ctrPos.text,
          orden: 7,
          help: 'Posición de la Pieza',
          iconoPre: Icons.panorama_horizontal_select_sharp,
        ),
        const SizedBox(height: 10),
        DecorationField.dropBy(
          fco: _fcsLad,
          items: _globals.lugar,
          onChange: (val){
            _ctrLad.text = val!;
          },
          defaultValue: (_ctrLad.text.isEmpty) ? _globals.lugar.first : _ctrLad.text,
          orden: 8,
          help: 'Lado de la Pieza',
          iconoPre: Icons.panorama_vertical_select_outlined,
        ),
        const SizedBox(height: 10),
        DecorationField.dropBy(
          fco: _fcsOri,
          items: _globals.origenes,
          onChange: (val){
            _ctrOri.text = val!;
          },
          defaultValue: (_ctrOri.text.isEmpty) ? _globals.origenes.first : _ctrOri.text,
          orden: 9,
          help: 'Origen de la Refacción',
          iconoPre: Icons.drive_file_move,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecorationField.fieldBy(
                ctr: _ctrDet,
                fco: _fcsDet,
                orden: 10,
                minLines: 3,
                help: 'Observaciones',
                validate: (val){},
                iconoPre: Icons.note_rounded,
              ),
            ),
            const SizedBox(width: 10),
            _btnsFrm()
          ],
        )
      ],
    );
  }

  ///
  Widget _btnsFrm() {

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 100, height: 40,
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(11),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green)
              ),
              onPressed: () async {
                String msg = 'Estás a punto de cambiar permanentemente los '
                'datos de ésta solicitud. Asegúrate de que el Solicitante esté '
                'enterado y de acuerdo con tus cambios, por favor.\n'
                '¿Estás segur@ de querer continuar?';
                bool? acc = await _alertAccion('EDITANDO DATOS DE LA SOLICITUD', msg);
                acc = (acc == null) ? false : acc;
                if(acc){ await _sendData('edd'); }
              },
              child: const Texto(txt: 'EDITAR', txtC: Colors.black, isBold: true),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: 100, height: 40,
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(12),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red)
              ),
              onPressed: () async {
                String msg = 'Se agregará una nueva autoparte a esta solicitud.'
                '\n Por favor, sólo asegúrate de que el solicitante esté '
                'enterado y de acuerdo con éste movimiento.\n'
                '¿Estás segur@ de querer continuar?';
                bool? acc = await _alertAccion('ADICIONANDO NUEVA REFACCIÓN', msg);
                acc = (acc == null) ? false : acc;
                if(acc){ await _sendData('add'); }
              },
              child: const Texto(txt: 'AGREGAR', txtC: Colors.black, isBold: true),
            ),
          ),
        )
      ],
    );
  }

  ///
  Widget _auto(String tipo) {

    List<Map<String, dynamic>> items = [{'nombre':'CARGANDO...'}];
    Map<String, dynamic> itemSelected = items.first;
    String help = '';
    IconData icono = Icons.directions_car_filled;

    if(autos.isNotEmpty) {
      
      switch (tipo) {
        case 'modelo':
          if(idMark != 0) {
            final carros = autos.firstWhere((element) => element['id'] == idMark);
            items = List<Map<String, dynamic>>.from(carros['modelos']);
            itemSelected = items.firstWhere((element) => element['id'] == idModl);
          }else{
            items = [{'nombre':'MODELOS'}];
            itemSelected = items.first;
          }
          help = 'Modelos';
          icono= Icons.directions_bus_filled;
          break;
        case 'anio':
          int init = 1930;
          int fin  = DateTime.now().year;
          items = List.generate((fin-init), (index) => {'nombre':'${init+index}'});
          items = items.reversed.toList();
          help = 'Años';
          icono= Icons.directions;
          itemSelected = (anio != 0) ? {'nombre':'$anio'} : items.first;
          break;
        default:
          items = autos;
          if(idMark != 0) {
            itemSelected = autos.firstWhere((element) => element['id'] == idMark);
          }
          help = 'Marcas';
      }
    }

    return DropdownSearch<Map<String, dynamic>>(
        // mode: Mode.MENU,
        // showSelectedItems: false,
        // showSearchBox: true,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            prefixIcon: Icon(icono, size: 15, color: Colors.white.withOpacity(0.2)),
            helperText: help
          )
        ),
        items: items,
        selectedItem: itemSelected,
        itemAsString: (Map<String, dynamic>? u) =>  u!['nombre'],
        
        //popupItemDisabled: (Map<String, dynamic> s) => s['nombre'].startsWith('I'),
        onChanged: (valSel){
          if(valSel != null) {
            if(valSel.isNotEmpty) {
              switch (tipo) {
                case 'modelo':
                  idModl = valSel['id'];
                  break;
                case 'anio':
                  anio = int.parse(valSel['nombre']);
                  break;
                default:
                  if(idMark != valSel['id']) {
                    idMark = valSel['id'];
                    idModl = 0;
                  }
              }
              // setState(() { });
            }
          }
        },
    );
  }

  ///
  Widget _containerFotos() {

    return Container(
      constraints: const BoxConstraints.expand(
        height: 130
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(10),
      child: FutureBuilder(
        future: _getFotosByIdPieza(),
        builder: (_, AsyncSnapshot snap) {

          if(snap.connectionState == ConnectionState.done) {
            return (_fotosCurrents.isNotEmpty)
            ?_fotosViewer()
            : Center(
              child: Texto(
                txt: 'Sin Fotos', txtC: Colors.amber.withOpacity(0.5)
              )
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  ///
  Widget _fotosViewer() {

    return Scrollbar(
      controller: _scrollFotos,
      trackVisibility: true,
      child: ListView.builder(
        controller: _scrollFotos,
        scrollDirection: Axis.horizontal,
        itemCount: _fotosCurrents.length,
        itemBuilder: (_, index) {

          return ValueListenableBuilder<bool>(
            valueListenable: _refreshFotos,
            builder: (_, isR, __) => _tileFoto(index)
          );
        }
      )
    );
  }

  ///
  Widget _tileFoto(int index) {

    return Container(
      padding: const EdgeInsets.all(10),
      width: 200,
      height: 150,
      child: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: 4/3,
              child: CachedNetworkImage(
                imageUrl: _fotosCurrents[index]['foto'],
                fit: BoxFit.cover,
              ),
            )
          ).blurred(
            blur: (_fotosCurrents[index]['isDelete']) ? 2.5 : 0,
            blurColor: Colors.white,
            colorOpacity: (_fotosCurrents[index]['isDelete']) ? 0.5 : 0,
            alignment: Alignment.center,
            overlay: (_fotosCurrents[index]['isDelete'])
              ? Texto(
                txt: 'BORRADA', sz: 25, isBold: true,
                txtC: Colors.black.withOpacity(0.5)
              )
              : const SizedBox()
          ),
          Positioned(
            top: 1, left: 1,
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 14,
              child: IconButton(
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  maxHeight: 28, maxWidth: 28
                ),
                onPressed: () {
                  _fotosCurrents[index]['isDelete'] = !_fotosCurrents[index]['isDelete'];
                  _refreshFotos.value = !_refreshFotos.value;
                },
                icon: Icon(
                  (!_fotosCurrents[index]['isDelete'])
                  ? Icons.remove_circle_outline_sharp
                  : Icons.undo_sharp,
                  color: Colors.white
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  
  ///
  Widget _tileDataSol(String valor, String label) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texto(txt: valor, sz: 16, isBold: false),
        const SizedBox(height: 3),
        Texto(txt: label, txtC: Colors.white, sz: 11, isBold: false),
      ],
    );
  }

  ///
  Future<void> _getFotosByIdPieza() async {

    if(_fotosCurrents.isEmpty) {
      _fotosCurrents = _items.fotosByPiezas.where(
        (element) => element['id'] == _items.piezaSelect!.id
      ).toList();

      // Colocamos un campo para marcar como borrada en caso de requerirlo
      _fotosCurrents.map((e) {
        e['isDelete'] = false;
      }).toList();
    }
  }

  ///
  Future<bool> _getDatosByOrdenAndPieza() async {

    _items = context.read<ItemSelectGlobProvider>();
    if(autos.isEmpty) {
      autos = await GetContentFile.getAllAuto();
    }
    if(_items.ordenEntitySelect != null) {
      idMark = _items.ordenEntitySelect!.mkId;
      idModl = _items.ordenEntitySelect!.mdId;
      anio = _items.ordenEntitySelect!.anio;
      _isNac.value = _items.ordenEntitySelect!.isNac;
    }
    
    final has = _items.piezas.where((element) => element.id == _items.idPzaSelect);
    if(has.isNotEmpty) {
      _items.piezaSelect = has.first;
      _ctrPieza.text = _items.piezaSelect!.piezaName;
      return true;
    }
    return false;
  }

  ///
  Future<bool?> _alertAccion(String titulo, String msg) async {

    return await WidgetsAndUtils.showAlert(
      context,
      titulo: titulo,
      msg: msg,
      onlyYES: false,
      onlyAlert: false,
      withYesOrNot: true,
      focusOnConfirm: true
    );
  }

  ///
  Future<void> _sendData(String acc) async {

    setState(() {
      _loading = true;
    });


    PiezasEntity? piezaData = PiezasEntity();
    if(acc == 'add') {
      piezaData.orden = _items.idOrdenSelect;
      piezaData.est = (_items.piezaSelect!.est == '0') ? '3' : _items.piezaSelect!.est;
      piezaData.stt = (_items.piezaSelect!.stt == '0') ? '1' : _items.piezaSelect!.stt;
      _fotosCurrents = [];
      _items.piezaSelect = piezaData;
    }

    Map<String, dynamic> data = _getDataPiezasFromScreen();
    
    await _ordEm.editarDataPieza(data, isLocal: true);
    if(!_ordEm.result['abort']) {

      await _ordEm.editarDataPieza(data, isLocal: false);
      piezaData.fromScreen(data);

      if(acc == 'add') {
        piezaData.id = _ordEm.result['body'];
        _items.piezas.insert(0, piezaData);
      } else {

        for (var i = 0; i < _items.piezas.length; i++) {

          if(_items.piezas[i].id == data['id']) {
            _items.piezas[i] = piezaData;

            if(data['fotosD'].isNotEmpty) {
              if(_items.fotosByPiezas.isNotEmpty) {
                
                for (var ft = 0; ft < data['fotosD'].length; ft++) {
                  _items.fotosByPiezas.removeWhere(
                    (element) => element['foto'].endsWith(data['fotosD'][ft])
                  );
                }
              }
            }
          }
        }
      }

      _items.piezaSelect = PiezasEntity();
      _fotosCurrents = [];
      _loading = false;
      piezaData = null;
      widget.onFinish(acc);
    }
    
  }

  ///
  Map<String, dynamic> _getDataPiezasFromScreen() {

    String deta = _ctrDet.text.toLowerCase();
    List<String> fotos = [];
    List<String> fotosD = [];
    String pathF = '';
    _fotosCurrents.map((foto){
      Uri uri = Uri.parse(foto['foto']);
      List<String> segmentos = uri.pathSegments;
      if(!foto['isDelete']) {
        if(pathF.isEmpty) {
          pathF = segmentos.getRange(0, segmentos.length-1).last;
        }
        fotos.add(segmentos.last);
      }else{
        fotosD.add(segmentos.last);
      }
    }).toList();
    
    return {
      'id': _items.piezaSelect!.id,
      'est': _items.piezaSelect!.est,
      'stt': _items.piezaSelect!.stt,
      'piezaName': _ctrPieza.text.toUpperCase().trim(),
      'origen': _ctrOri.text,
      'lado': _ctrLad.text,
      'posicion': _ctrPos.text,
      'fotos': fotos,
      'fotosD': fotosD,
      'pathF': pathF,
      'obs': deta.replaceFirst(deta[0], deta[0].toUpperCase()),
      'orden': _items.piezaSelect!.orden
    };
  }

}