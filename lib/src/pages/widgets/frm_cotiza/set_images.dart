import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets_utils.dart';
import '../texto.dart';
import '../../../providers/cotiza_provider.dart';
import '../../../services/get_paths.dart';
import '../../../repository/ordenes_repository.dart';
import '../../../services/status/est_stt.dart';

class SetImages extends StatefulWidget {

  const SetImages({Key? key}) : super(key: key);

  @override
  State<SetImages> createState() => _SetImagesState();
}

class _SetImagesState extends State<SetImages> {

  final _orEm = OrdenesRepository();
  final _urls = TextEditingController();
  final _fUrl = FocusNode();
  final _fotos = ValueNotifier<List<String>>([]);
  final _msgs = ValueNotifier<String>('');
  final _sep = Platform.pathSeparator;
  final permitidas = <String>['jpg', 'jpeg', 'png'];

  late CotizaProvider _ctzP;
  List<Map<String, dynamic>> _pzas = []; 
  bool _onDragIn = false;
  bool _isInit = false;
  int _idOrden = -1;
  int _intento = 1;
  String _idPza = '0';
  
  @override
  void dispose() {
    _fotos.dispose();
    _urls.dispose();
    _msgs.dispose();
    _fUrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _ctzP = context.read<CotizaProvider>();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color.fromARGB(255, 63, 63, 63))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _urlFieldAndIcons(),
          const SizedBox(height: 5),
          ValueListenableBuilder(
            valueListenable: _msgs,
            builder: (_, msg, __) {
              return Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Texto(txt: msg, sz: 13, txtC: Colors.amber),
              );
            }
          ),
          _containerImages(),
          _foot()
        ],
      ),
    );
  }

  ///
  Widget _urlFieldAndIcons() {

    return Row(
      children: [
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 40,
            child: _txtUrlWeb()
          ),
        ),
        IconButton(
          onPressed: () async => await _downLoadFromUrl(),
          icon: const Icon(Icons.download, color: Colors.grey)
        ),
        IconButton(
          onPressed: () async => await _filePicker(),
          icon: const Icon(Icons.create_new_folder_rounded, color: Colors.amber)
        ),
        IconButton(
          onPressed: () async => _launchWeb(),
          icon: const Icon(Icons.public, color: Colors.green)
        ),
      ],
    );
  }

  ///
  Widget _txtUrlWeb() {

    return TextField(
      controller: _urls,
      focusNode: _fUrl,
      onSubmitted: (val) async => await _downLoadFromUrl(),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        enabledBorder: _border(),
        focusedBorder: _border(),
        hintText: 'http://...',
      ),
    );
  }

  ///
  Widget _containerImages() {

    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.18,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (_onDragIn) ?  Colors.black.withOpacity(0.5) : Colors.transparent
      ),
      child: LayoutBuilder(
        builder: (_, constraint) {

          return Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _fotos,
                  builder: (_, fts, child) {

                    if(fts.isEmpty) { return child!; }

                    return ListView.builder(
                      itemCount: fts.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, index) => _tileImage(constraint, index)
                    );
                  },
                  child: _msgEmpty()
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.04,
                child: _dropZone(),
              )
            ],
          );
        },
      )
    );
  }
  
  ///
  Widget _tileImage(BoxConstraints constraint, int index) {

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.only(right: 10),
          width: constraint.maxWidth/4,
            child: AspectRatio(
            aspectRatio: 4/3,
            child: Image.file(
              File(_fotos.value[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 5, left: 5,
          child: Container(
            width: 30, height: 30,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(45),
              color: Colors.black,
              border: Border.all(color: Colors.white)
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.green, size: 18),
              padding: const EdgeInsets.all(0),
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: () => _deleteFoto(index)
            ),
          ),
        )
      ],
    );
  }
  
  ///
  Widget _dropZone() {

    return DropTarget(
      onDragDone: (urls) async => await _fromDrop(urls),
      onDragEntered: (details) => setState(() { _onDragIn = true; }),
      onDragExited: (details) => setState(() { _onDragIn = false; }),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Color.fromARGB(255, 71, 71, 71))
          )
        ),
        child: Center(
          child: TextButton(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
              alignment: Alignment.centerLeft,
              visualDensity: VisualDensity.compact
            ),
            onPressed: () async => await _launchExplorer(),
            child: SizedBox.expand(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _onDragIn ? Icons.data_object_sharp : Icons.drag_indicator_sharp,
                    color: const Color.fromARGB(255, 54, 54, 54), size: 45
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
    
  ///
  Widget _msgEmpty() {

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.photo_album_outlined, color: Color.fromARGB(255, 54, 54, 54), size: 50),
          Texto(
            txt: 'Arrastra y Suelta multiples Fotografías en el Receptor',
            txtC: Color.fromARGB(255, 87, 87, 87),
          ),
          Texto(
            txt: 'ubicador en la parte derecha de este contenedor.',
            txtC: Color.fromARGB(255, 122, 122, 122),
            sz: 13,
          ),
        ],
      )
    );
  }
  
  ///
  Widget _foot() {

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.green, width: 1),
          bottom: BorderSide(color: Colors.green, width: 1),
        )
      ),
      child: Row(
        children: [
          Selector<CotizaProvider, int>(
            selector: (_, prov) => prov.indexPzaCurren,
            builder: (_, index, __) {

              String txt = 'Selecciona una pieza para colocarle fotos.';
              if(index != -1 && _ctzP.piezas.isNotEmpty) {
                if(_idPza != '${_ctzP.piezas[index].id}') {
                  Future.delayed(const Duration(microseconds: 250), (){
                    _fotos.value = [];
                    if(_ctzP.piezas.isNotEmpty) {
                      if(_ctzP.piezas[index].fotos.isNotEmpty) {
                        _fotos.value = _ctzP.piezas[index].fotos;
                      }
                    }
                  });
                }
                _idPza = '${_ctzP.piezas[index].id}';
                txt = 'Fotografías para la pieza: ${_ctzP.formatIdPza(_ctzP.piezas[index].id)}';
              }
              return Texto(txt: txt);
            },
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              bool? res = await _showAlerts('del');
              res = (res == null) ? false : res;
              if(res) {
                _deleteFoto(1000);
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Texto(txt: 'Borrar Todas', txtC: Colors.orange)
          ),
          const SizedBox(width: 15),
          TextButton.icon(
            onPressed: () async {
              bool? res = await _showAlerts('fin');
              res = (res == null) ? false : res;
              if(res) {
                await _enviarToProceso();
              }
            },
            icon: const Icon(Icons.send),
            label: const Texto(txt: 'Enviar Solicitud', txtC: Colors.blue)
          )
        ],
      ),
    );
  }
  
  ///
  Widget _getBodyAlert(String tipo) {

    String txt = 'Se eliminarán todas las imágenes hasta ahora seleccionadas '
    'para esta Autoparte en particular.\n¿Deseas continuar con la operación?';

    if(tipo == 'fin') {
      txt = 'Estás apunto de enviar esta SOLICITUD DE COTIZACIÓN a la Central '
      'para su procesamiento.\n¿Deseas continuar con la operación?';
    }

    if(tipo == 'save') {

      _msgs.value = '';
      txt = 'Estamos creando el contenedor principal para la solicitud de '
      'cotización, Espera un momento por favor.';
    }

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          child: (tipo != 'save')
            ? Texto(txt: txt, sz: 16, isCenter: true)
            : StreamBuilder<String>(
              stream: _buildOrden(),
              initialData: 'Estamos preparando todo, Espera un momento, por favor',
              builder: (_, AsyncSnapshot<String> snap) {

                if(snap.data!.startsWith('ERROR')) {
                  Future.delayed(const Duration(milliseconds: 3000), (){
                    Navigator.of(context).pop(false);
                  });
                }

                if(snap.data!.startsWith('[OK]')) {
                  Future.delayed(const Duration(milliseconds: 500), (){
                    Navigator.of(context).pop(true);
                  });
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Texto(txt: txt, sz: 16, isCenter: true),
                    const SizedBox(height: 8),
                    Texto(
                      txt: snap.data ?? '...',
                      sz: 16, isCenter: true, txtC: Colors.amber,
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 3, width: MediaQuery.of(context).size.width * 0.5,
                      child: const LinearProgressIndicator(),
                    )
                  ],
                );
              }
            ),
        )
      ],
    );
  }

  /// Cuando tenga tiempo se hace bien
  Widget _comoFuture(String txt) {

    return FutureBuilder<void>(
      future: _crearOrdenToServer(),
      builder: (_, AsyncSnapshot snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(snap.hasData) {
            if(snap.data > -1) {
              Navigator.of(context).pop(true);
            }else{
              Future.microtask(() {
                if(_msgs.value.isEmpty) {
                  _msgs.value = '[X] Ocurrio un Error inesperado, Inténtalo nuevamente.';
                }
              });
              Navigator.of(context).pop(false);
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Texto(txt: txt, sz: 16, isCenter: true),
            const SizedBox(height: 8),
            const Texto(
              txt: 'Estamos preparando todo, Espera un momento, por favor',
              sz: 16, isCenter: true, txtC: Colors.amber,
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 3, width: MediaQuery.of(context).size.width * 0.5,
              child: const LinearProgressIndicator(),
            )
          ],
        );
      },
    );
  }

  /// ------------------------ CONTROLADOR -------------------------------------
  
  /// Solo abrimos el explorador de archivos.
  Future<void> _launchExplorer() async {
    
    _msgs.value = '';
    String filePath = '';
    if(_ctzP.inicialDir.isNotEmpty) {
      filePath = _ctzP.inicialDir;
    }else{
      
      final appDocDir = await getApplicationDocumentsDirectory();
      if (!appDocDir.existsSync()) {
        _msgs.value = '${appDocDir.path} no existe!';
      }
      filePath = appDocDir.path;
    }

    final Uri uri = Uri.file(filePath);
    if (!await launchUrl(uri)) {
      _msgs.value = 'No pudimos abrir el Explorador de Archivos';
    }
  }

  /// Capturamos las imagenes que biene de arrastrar y soltar
  Future<void> _fromDrop(DropDoneDetails details) async {
    
    if(_ctzP.piezas.isEmpty) {
      _msgs.value = '[X] No se ha detectado ninguna pieza.';
      return;
    }
    _msgs.value = '';
    if(details.files.isNotEmpty) {
      // Guardamos en memoria el ultimo path
      _setPathOrigin(details.files.first.path);
    }

    for (var i = 0; i < details.files.length; i++) {
      await _inserFoto(details.files[i].path);
    }
  }

  /// Capturamos la imagen que biene de la web
  Future<void> _downLoadFromUrl() async {

    if(_ctzP.piezas.isEmpty) {
      _msgs.value = '[X] No se ha detectado ninguna pieza.';
      return;
    }

    _msgs.value = '';
    var url = _urls.text;
    if(url.isEmpty) {
      _msgs.value = 'Coloca la url de la imagen';
      _fUrl.requestFocus();
      return;
    }
    if(url.startsWith('data:')) {
      await _fromBase64();
      return;
    }
    if(!url.startsWith('http')) {
      await _launchWeb();
      return;
    }

    _urls.text = '';
    var response = await http.get(Uri.parse(url));
    if(response.statusCode == 200) {

      var documentDirectory = GetPaths.getPathRoot();
      var firstPath = '$documentDirectory/images_cache';

      final fileNameTmp = url.split('/').last;
      final partes = fileNameTmp.split('.');
      if(permitidas.contains(partes.last)) {

        final dirTmp = Directory(firstPath);
        String numFt = '1';
        if(!dirTmp.existsSync()) {
          dirTmp.create(recursive: true);
        }else{

          final ftos = dirTmp.listSync().toList();
          int cantF = 0;
          if(ftos.isNotEmpty) {
            for (var i = 0; i < ftos.length; i++) {
              if(ftos[i].path.contains(_idPza)) {
                cantF++;
              }
            }
            numFt = '$cantF';
          }
        }

        var filePathAndName = '$firstPath$_sep$_idPza${'_'}$numFt.jpg';
        File file2 = File(filePathAndName);
        file2.writeAsBytesSync(response.bodyBytes);
        await _inserFoto(file2.path);
      }
    }
  }

  /// Capturamos la imagen que biene de la web
  Future<void> _fromBase64() async {

    _msgs.value = '';
    var url = _urls.text;
    _urls.text = '';

    var partes = url.split(',');
    String tipo = partes.first;
    tipo = tipo.replaceAll('data:', '');
    tipo = tipo.replaceAll(';base64', '');
    if(!tipo.contains('image')) {
      _msgs.value = 'El código proporcionado no es una imagen valida.';
      return;
    }
    tipo = tipo.replaceAll('image/', '').trim().toLowerCase();
    if(!permitidas.contains(tipo)) {
      _msgs.value = '$tipo No es una extención valida.';
      return;
    }
    
    var documentDirectory = GetPaths.getPathRoot();
    var firstPath = '$documentDirectory/images_cache';
    final dirTmp = Directory(firstPath);
    String numFt = '1';
    if(!dirTmp.existsSync()) {
      dirTmp.create(recursive: true);
    }else{

      final ftos = dirTmp.listSync().toList();
      int cantF = 0;
      if(ftos.isNotEmpty) {
        for (var i = 0; i < ftos.length; i++) {
          if(ftos[i].path.contains(_idPza)) {
            cantF++;
          }
        }
        numFt = '$cantF';
      }
    }

    var pathFull = '$firstPath$_sep$_idPza${DateTime.now().millisecondsSinceEpoch}_$numFt.$tipo';

    Uint8List bytes = base64.decode(partes.last);
    File file = File(pathFull);
    file.writeAsBytesSync(bytes);
    await _inserFoto(file.path);

  }

  ///
  Future<void> _launchWeb() async {

    _msgs.value = '';
    String uri = 'https://google.com';
    if(_urls.text.isNotEmpty) {
      uri = '$uri/search?q=${_urls.text}';
    }
    _urls.text = '';
    if (!await launchUrl(Uri.parse(uri))) {
      _msgs.value = 'No pudimos lanzar el Navegador';
      _fUrl.requestFocus();
    }
  }

  /// Capturamos las imagenes que biene del Explorador de archivos
  Future<void> _filePicker() async {

    _msgs.value = '';
    FilePickerResult? result;
    _msgs.value = 'Abriendo Explorador de Archivos';

    try {
      
      result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        dialogTitle: 'Selecciona tus Imágenes',
        lockParentWindow: true,
        initialDirectory: _ctzP.inicialDir,
        withData: false,
        withReadStream: true,
        allowedExtensions: permitidas,
      );
    } on PlatformException catch (_) {
      _msgs.value = 'El sistema no soporta esta acción';
    } catch (e) {
      _msgs.value = 'ERROR ${e.toString()}';
    } finally {
      _msgs.value = '';
    }

    if (result == null || result.files.isEmpty) {
      return;
    }
    
    _setPathOrigin(result.files.first.path!);

    // Recuperamos todos los paths
    for (var i = 0; i < result.files.length; i++) {
      final filePath = result.files[i].path;
      if(filePath != null) {
        _inserFoto(filePath);
      }
    }
  }

  ///
  Future<void> _inserFoto(String path) async {

    List<String> f = List<String>.from(_fotos.value);
    _fotos.value.clear();
    f.insert(0, path);

    // Recuperamos indexPzaCurren en caso de haberlo perdido
    if(_idPza.isNotEmpty && _ctzP.indexPzaCurren == -1) {
      final has = _ctzP.piezas.indexWhere((element) => '${element.id}' == _idPza);
      if(has != -1) {
        _ctzP.indexPzaCurren = has;
      }  
    }

    if(_ctzP.piezas[_ctzP.indexPzaCurren].fotos.isEmpty) {
      _ctzP.fotoThubm = path;
    }
    _fotos.value = List<String>.from(f);
    _ctzP.piezas[_ctzP.indexPzaCurren].fotos = _fotos.value;
    f.clear();
  }

  ///
  Future<void> _deleteFoto(int index) async {

    // Recuperamos indexPzaCurren en caso de haberlo perdido
    if(_idPza.isNotEmpty && _ctzP.indexPzaCurren == -1) {
      final has = _ctzP.piezas.indexWhere((element) => '${element.id}' == _idPza);
      if(has != -1) {
        _ctzP.indexPzaCurren = has;
      }  
    }

    if(index == 1000) {
      _fotos.value = [];
    }else{
      List<String> f = List<String>.from(_fotos.value);
      _fotos.value.clear();
      f.removeAt(index);
      _fotos.value = List<String>.from(f);
      f.clear();
    }
    if(_ctzP.piezas.isEmpty){ return; }
    _ctzP.piezas[_ctzP.indexPzaCurren].fotos = _fotos.value;
    if(_ctzP.piezas[_ctzP.indexPzaCurren].fotos.isNotEmpty) {
      _ctzP.piezas[_ctzP.indexPzaCurren].fotos.sort();
      _ctzP.fotoThubm = _ctzP.piezas[_ctzP.indexPzaCurren].fotos.first;
    }else{
      _ctzP.fotoThubm = '';
    }
  }

  ///
  Future<void> _enviarToProceso() async {

    // Primero recuperamos todos los datos.
    if(_ctzP.piezas.isEmpty) {
      _msgs.value = '[X] No se encontraron Autopartes para Enviar...';
      return;
    }
    
    for (var i = 0; i < _ctzP.piezas.length; i++) {
      if(_ctzP.piezas[i].fotos.isEmpty) {
        _msgs.value = 'La pieza ID: ${_ctzP.piezas[i].id}, necesita fotografías';
        _ctzP.indexPzaCurren = i;
        _fotos.value = [];
        _idPza = '${_ctzP.piezas[i].id}';
        return;
      }
      _pzas.add(_ctzP.piezas[i].toJson());
    }

    bool? isOk = await _showAlerts('save');
    isOk = (isOk == null) ? false : isOk;
    if(isOk) {
      _fotos.value = [];
      _pzas = []; 
      _idOrden = -1;
      _intento = 1;
      _idPza = '0';
      _ctzP.isOrdFinish = 'fin';
    }

    // var orden = _ctzP.orden.toJsonSave();
    // orden['piezas'] = pzas;

    // if(isOk) {
    //   orden['id'] = _idOrden;
    //   _idOrden = -1;
    //   bool res = await ctzSetOrdenInFile(orden);
    //   if(res) {
    //     _ctzP.isOrdFinish = 'fin';
    //   }
    // }
  }

  ///
  Stream<String> _buildOrden() async* {

    await _crearOrdenToServer();
    if(_idOrden == -1) {
      _intento++;
      yield 'ERROR al Guardar la Orden, Inténtalo nuevamente';
      return;
    }

    var orden = _ctzP.orden.toJsonSave();
    orden['piezas'] = List<Map<String, dynamic>>.from(_pzas);
    _pzas = [];
    final nameBase = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < orden['piezas'].length; i++) {

      List<String> fotos = List<String>.from(orden['piezas'][i]['fotos']);
      for (var f = 0; f < fotos.length; f++) {

        final ft = File(fotos[f]);
        orden['piezas'][i]['orden'] = _idOrden;
        if(ft.existsSync()) {
          final filename = ft.path.split(_sep).last;
          String name = '$_idOrden-$nameBase-${f+1}.${filename.split('.').last}';
          final data = {
            'filename': name,
            'bytes': ft.readAsBytesSync(),
          };
          yield 'Subiendo Foto ${f+1} de ${fotos.length}, Pieza: ID [$_idOrden]';
          await _orEm.setFotoCotiza(data, _ctzP.tokenServer);
          if(!_orEm.result['abort']) {
            orden['piezas'][i]['fotos'][f] = name;
          }
        }
      }

      yield 'Guardando datos de la Pieza: ID [${orden['piezas'][i]['id']}]';
      await _orEm.setPiezaByCotiza(orden['piezas'][i], _ctzP.tokenServer);
    }

    yield 'Notificando a la Central...';
    await _orEm.updateCentinelaServer(_idOrden, _ctzP.tokenServer);
    yield '[OK] Listo Orden Enviada';
  }

  ///
  Future<bool?> _showAlerts(String tipo) async {

    bool onlyAlert = false;
    bool withYesOrNot = true;
    bool diss = true;
    if(tipo == 'save') {
      onlyAlert = true;
      withYesOrNot = false;
      diss = false;
    }

    return await WidgetsAndUtils.showAlertBody(
      context,
      titulo: (tipo == 'del') ? 'ELIMINAR TODAS LAS FOTOS' : 'TERMINAR ALTA DE COTIZACIÓN',
      onlyAlert: onlyAlert,
      withYesOrNot: withYesOrNot,
      dismissible: diss,
      body: _getBodyAlert(tipo)
    );
  }

  ///
  Future<void> _crearOrdenToServer() async {

    if(_intento == 1) {
      final stt = await EstStt.getNextSttByEst(_ctzP.orden.toJsonSave());
      _ctzP.orden.est = stt['est'];
      _ctzP.orden.stt = stt['stt'];
    }

    _orEm.result.clear();
    _idOrden = -1;
    await _orEm.setOrdenByCotiza(_ctzP.orden.toJsonSave(), _ctzP.tokenServer);
    if(!_orEm.result['abort']) {
      _ctzP.orden.id = _orEm.result['body']['id'];
      _ctzP.orden.createdAt = DateTime.now().toIso8601String();
      _idOrden = _ctzP.orden.id;
    }else{
      if(_orEm.result['body'].runtimeType == String) {
        String res = _orEm.result['body'];
        if(res.contains('Invalido')) {
          _ctzP.tokenServer = '';
          _msgs.value = res;
        }
      }
    }
  }

  /// Grabamos en memoria el ultimo path para que se habra el explorador en la
  /// misma dirección la siguiente vez.
  void _setPathOrigin(String path) {

    final fileNameTmp = path.split(_sep);
    List<String> ext = fileNameTmp.last.split('.');
    
    if(permitidas.contains(ext.last)) {
      fileNameTmp.removeLast();
      _ctzP.inicialDir = fileNameTmp.join(_sep);
    }
  }

  ///
  OutlineInputBorder _border() {

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color.fromARGB(255, 100, 100, 100))
    );
  }
}