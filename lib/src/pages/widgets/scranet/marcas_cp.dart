import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';

import '../widgets_utils.dart';
import 'tile_marcas_anet.dart';
import 'console_proccs.dart';
import '../my_tool_tip.dart';
import '../texto.dart';
import '../../../entity/marcas_entity.dart';
import '../../../repository/autos_repository.dart';
import '../../../services/scranet/system_file_scrap.dart';

class MarcasCp extends StatefulWidget {

  const MarcasCp({Key? key}) : super(key: key);

  @override
  State<MarcasCp> createState() => _MarcasCpState();
}

class _MarcasCpState extends State<MarcasCp> {

  final _auto = ValueNotifier<Map<String, dynamic>>({});
  final _lstMrkAnet = ValueNotifier<List<MarcasEntity>>([]);
  final _lstMrkRadec = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _lstMrkAldo = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _refreshLstConsole = ValueNotifier<bool>(false);
  final _hasChanges = ValueNotifier<bool>(false);

  final _scrollAnetCtr = ScrollController();
  final _scrollRadecCtr = ScrollController();
  final _scrollAldoCtr = ScrollController();
  final _autoEm = AutosRepository();

  List<Map<String, dynamic>> _lstMrkRadecBup = [];
  List<Map<String, dynamic>> _lstMrkAldoBup = [];

  List<Map<String, dynamic>> _autos = [];
  final List<String> _lstConsola = [];

  late Future<void> _getMarcasAutopanet;

  @override
  void initState() {
    _getMarcasAutopanet = _getMrksAutoparnet();
    super.initState();
  }

  @override
  void dispose() {
    _auto.dispose();
    _lstMrkAnet.dispose();
    _lstMrkRadec.dispose();
    _lstMrkAldo.dispose();
    _scrollAnetCtr.dispose();
    _scrollRadecCtr.dispose();
    _scrollAldoCtr.dispose();
    _hasChanges.dispose();
    _refreshLstConsole.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _marcasAutoparnet()
        ),
        Expanded(
          flex: 2,
          child: _marcasRadec()
        ),
        Expanded(
          flex: 2,
          child: _marcasAldo()
        ),
        Expanded(
          flex: 2,
          child: _panel()
        )
      ],
    );
  }

  ///
  Widget _marcasAutoparnet() {

    return FutureBuilder(
      future: _getMarcasAutopanet,
      builder: (_, AsyncSnapshot snap) {
        if(snap.connectionState == ConnectionState.done) {
          return (_lstMrkAnet.value.isNotEmpty) ? _lista('anet') : _sinData();
        }
        return _load();
      },
    );
  }

  ///
  Widget _marcasRadec() {

    return ValueListenableBuilder(
      valueListenable: _lstMrkRadec,
      builder: (_, lst, child) {
        return (lst.isNotEmpty) ? _lista('radec') : child!;
      },
      child: _sinData(),
    );
  }

  ///
  Widget _marcasAldo() {

    return ValueListenableBuilder(
      valueListenable: _lstMrkAldo,
      builder: (_, lst, child) {
        return (lst.isNotEmpty) ? _lista('aldo') : child!;
      },
      child: _sinData(),
    );
  }

  ///
  Widget _sinData() {

    return SizedBox.expand(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.car_crash),
            SizedBox(height: 15),
            Text('Sin datos')
          ],
        ),
      ),
    );
  }

  ///
  Widget _panel() {

    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _auto,
            builder: (_, val, child) {

              if(val.isEmpty) {
                return _sinData();
              }

              return Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _lstMrkRadec.value = _lstMrkRadecBup; 
                        _lstMrkAldo.value = _lstMrkAldoBup;
                        _auto.value = {};
                      },
                      icon: const Icon(Icons.refresh, size: 18,),
                      label: const Texto(txt: 'Resetear Panel')
                    ),
                    const SizedBox(height: 20),
                    _tileCar('${val['id']}', 'ID'),
                    _tileCar(val['marca'], 'Marca'),
                    _tileCar(val['logo'], 'Logo'),
                    _tileCar(val['grupo'], 'Grupo'),
                    _tileCar(val['simyls']['radec'], 'Similitud en Radec ID:'),
                    _tileCar(val['simyls']['aldo'], 'Similitud en Aldo ID:'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.green)
                          ),
                          onPressed: () async => await _saveMarcaFromPanel(),
                          child: const Texto(txt: 'Guardar Cambios', txtC: Colors.black)
                        )
                      ],
                    )
                  ],
                )
              );
            }
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _refreshLstConsole,
          builder: (_, refresh, __) {
            return ConsoleProccs(proccs: _lstConsola);
          }
        )
      ],
    );

  }

  ///
  Widget _tileCar(String value, String key) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                constraints: const BoxConstraints(
                  maxWidth: 20
                ),
                onPressed: (){},
                icon: const Icon(Icons.edit, color: Colors.green)
              ),
              const SizedBox(width: 10),
              Texto(txt: value),
            ],
          ),
          const Divider(height: 1),
          Align(
            alignment: Alignment.topRight,
            child: Texto(txt: key, sz: 12, txtC: Colors.green),
          )
        ],
      ),
    );
  }

  ///
  Widget _load() {

    return const Center(
      child: SizedBox(
        width: 70, height: 70,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  ///
  Widget _lista(String ofBy) {

    String label = 'MARCAS AutoparNet';
    
    if(ofBy == 'radec') {
      label = 'Radec';
    }
    if(ofBy == 'aldo') {
      label = 'Aldo';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          height: 30,
          child: Row(
            children: [
              Text(
                label,
                textScaleFactor: 1,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.1
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  '${_getLst(ofBy).length}'
                ),
              ),
              if(ofBy == 'anet')
               ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async => await _saveAll(),
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar TODO',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(0),
                  iconSize: 18,
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: _hasChanges,
                  builder: (_, val, __) {

                    return MyToolTip(
                      msg: 'Hay Cambios sin Guardar',
                      child: Icon(
                        Icons.warning_amber,
                        color: (val) ? Colors.amber : const Color.fromARGB(255, 82, 82, 82)
                      ),
                    );
                  }
                )
              ]
            ],
          )
        ),
        Expanded(
          child: Scrollbar(
            controller: _getCtr(ofBy),
            thumbVisibility: true,
            radius: const Radius.circular(3),
            trackVisibility: true,
            child: ListView.builder(
              controller: _getCtr(ofBy),
              itemCount: _getLst(ofBy).length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemBuilder: (_, index) {
                
                final l = _getLst(ofBy);
                if(ofBy == 'anet') {
                  return TileMarcasAnet(
                    auto: _lstMrkAnet.value[index],
                    onTap: (marca) {
                      _fncAnet(marca.toJson());
                    },
                    onDelete: (borrar) async {
                      if(borrar) {
                        // print(_lstMrkAnet.value[index]);
                      }
                    }
                  );
                }

                return _tileAuto(Map<String, dynamic>.from(l[index]), ofBy);
              }
            )
          ),
        )
      ],
    );
  }

  ///
  Widget _tileAuto(Map<String, dynamic> auto, String ofBy) {

    return TextButton(
      onPressed: () {

        if(auto['value'] == 'DESCONOCIDO') {
          return;
        }

        switch (ofBy) {
          case 'radec':
            _fncRadec(auto);
            break;
          case 'aldo':
            _fncAldo(auto);
            break;
        }
      },
      child: Row(
        children: [
          if(auto.containsKey('existe'))
            ...[
              const Icon(Icons.close, size: 12, color: Colors.white),
              const SizedBox(width: 5)
            ],
          Text(
            auto['value'],
            textScaleFactor: 1,
            style: TextStyle(
              color: (auto.containsKey('existe'))
                ? (auto['value'] == 'DESCONOCIDO')
                  ?  const Color.fromARGB(255, 73, 73, 73) : Colors.orange
               : Colors.blue
            ),
          ),
          if(auto.containsKey('existe'))
            ...[
              const Spacer(),
              if(auto['value'] != 'DESCONOCIDO')
                IconButton(
                  padding: const EdgeInsets.all(0),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    maxWidth: 15
                  ),
                  onPressed: () {
                    final e = MarcasEntity();
                    e.fromAddNew(auto, ofBy);
                    _lstMrkAnet.value.insert(0, e);
                    setState(() {});
                  },
                  icon: const Icon(Icons.add, size: 12, color: Colors.white)
                ),
            ],
        ],
      )
    );
  }

  ///
  ScrollController _getCtr(String ofBy) {

    switch (ofBy) {
      case 'anet':
        return _scrollAnetCtr;
      case 'radec':
        return _scrollRadecCtr;
      case 'aldo':
        return _scrollAldoCtr;
      default:
        return _scrollAnetCtr;
    }
  }

  ///
  List<dynamic> _getLst(String ofBy) {

    switch (ofBy) {
      case 'radec':
        return _lstMrkRadec.value;
      case 'aldo':
        return _lstMrkAldo.value;
      default:
        return _lstMrkAnet.value;
    }
  }

  ///
  MarcasEntity _fncAnet(Map<String, dynamic> auto, {bool isGet = false}) {

    String radec = '0';
    String aldo  = '0';
    const ratio = 0.2;
    List<Map<String, dynamic>> aTmp = [];

    String marca = '';
    if(auto.containsKey('mrk_nombre')) {
      marca = auto['mrk_nombre'];
    }
    if(auto.containsKey('marca')) {
      marca = auto['marca'];
    }

    var matchRadec = StringSimilarity.findBestMatch(
      marca, _lstMrkRadecBup.map<String>((e) => e['value']).toList()
    );

    if(matchRadec.bestMatch.rating == 1.0) {
      if(!isGet) {
        _lstMrkRadec.value = [_lstMrkRadecBup[matchRadec.bestMatchIndex]];
      }
      radec = _lstMrkRadecBup[matchRadec.bestMatchIndex]['id'];
    }else{
      
      if(!isGet) {

        _lstMrkRadec.value = [];
        for (var i = 0; i < matchRadec.ratings.length; i++) {
          if(matchRadec.ratings[i].rating! > ratio) {
            final finded = _lstMrkRadecBup.where(
              (element) => element['value'] == matchRadec.ratings[i].target
            );

            if(finded.isNotEmpty) {
              aTmp.add(finded.first);
            }
          }
        }

        _lstMrkRadec.value = List<Map<String, dynamic>>.from(aTmp);
      }
    }

    aTmp = [];
    var matchAldo = StringSimilarity.findBestMatch(
      marca, _lstMrkAldoBup.map<String>((e) => e['value']).toList()
    );

    if(matchAldo.bestMatch.rating == 1.0) {
      if(!isGet) {
        _lstMrkAldo.value = [_lstMrkAldoBup[matchAldo.bestMatchIndex]];
      }
      aldo = _lstMrkAldoBup[matchAldo.bestMatchIndex]['id'];
    }else{

      if(!isGet) {
        _lstMrkAldo.value = [];
        for (var i = 0; i < matchAldo.ratings.length; i++) {
          if(matchAldo.ratings[i].rating! > ratio) {
            final finded = _lstMrkAldoBup.where(
              (element) => element['value'] == matchAldo.ratings[i].target
            );
            if(finded.isNotEmpty) {
              aTmp.add(finded.first);
            }
          }
        }
        _lstMrkAldo.value = aTmp;
      }
    }

    aTmp = [];
    final e = MarcasEntity();
    if(!isGet) {
      auto['simyls'] = {'radec': radec,'aldo' : aldo};
      e.fromJson( auto );
      _auto.value = e.toJson();
      if(mounted) {
        setState(() {});
      }
    }else{

      if(auto['mrk_simyls'] == null) {
        auto['hasChanges'] = 3;
        _hasChanges.value = true;
        auto['mrk_simyls'] = {'radec': radec,'aldo' : aldo};
      }
      e.fromFile( auto );
    }
    return e;
  }

  ///
  void _fncRadec(Map<String, dynamic> auto) {

    if(_auto.value.containsKey('simyls')) {
      setState(() {
        _auto.value['simyls']['radec'] = auto['id'];
      });
    }
  }

  ///
  void _fncAldo(Map<String, dynamic> auto) {

    if(_auto.value.containsKey('simyls')) {
      setState(() {
        _auto.value['simyls']['aldo'] = auto['id'];
      });
    }
  }

  ///
  Future<void> _getMrksAutoparnet() async {

    _autos = await _autoEm.getMarcasAutoparnet();
    _autoEm.cleanResult();
    _lstMrkRadecBup = await SystemFileScrap.getAllMarcasBy('radec');
    _lstMrkAldoBup = await SystemFileScrap.getAllMarcasBy('aldo');

    // Revisamos que todas las marcas de Radec las tengamos nosotros
    List<String> marcasTmp = _autos.map<String>((e) => e['mrk_nombre']).toList(); 
    for (var i = 0; i < _lstMrkRadecBup.length; i++) {
      bool existe = _existeEn(marcasTmp, _lstMrkRadecBup[i]['value']);
      if(!existe) {
        _lstMrkRadecBup[i]['existe'] = false;
      }
    }
    _lstMrkRadec.value = List<Map<String, dynamic>>.from(_lstMrkRadecBup);

    // Revisamos que todas las marcas de Aldo las tengamos nosotros
    for (var i = 0; i < _lstMrkAldoBup.length; i++) {
      bool existe = _existeEn(marcasTmp, _lstMrkAldoBup[i]['value']);
      if(!existe) {
        _lstMrkAldoBup[i]['existe'] = false;
      }
    }
    _lstMrkAldo.value = List<Map<String, dynamic>>.from(_lstMrkAldoBup);

    marcasTmp = [];
    List<MarcasEntity> mTmp = [];

    for (var i = 0; i < _autos.length; i++) {
      mTmp.add(_fncAnet(_autos[i], isGet: true));
    }

    _lstMrkAnet.value = List<MarcasEntity>.from(mTmp);
    mTmp = [];
    _autos = [];
  }

  ///
  bool _existeEn(List<String> craw, String marca) {

    final has = craw.contains(marca);
    return has;
  }

  ///
  Future<void> _saveMarcaFromPanel() async {

    final nav = Navigator.of(context);
    _dialogSafe(1);
    _autoEm.cleanResult();
    _setConsole(_auto.value['hasChanges'], _auto.value['marca']);
    await _autoEm.editMarca(_auto.value, isLocal: false);

    if(!_autoEm.result['abort']) {
      await _autoEm.editMarca(_auto.value, isLocal: true);
      await _refreshScreen();
      _autoEm.cleanResult();
    }
    nav.pop();
  } 

  ///
  Future<void> _saveAll() async {

    for (var i = 0; i < _lstMrkAnet.value.length; i++) {
      
      _autoEm.cleanResult();
      switch (_lstMrkAnet.value[i].hasChanges) {
        case 1:
          _lstConsola.insert(0, 'Guardando ${_lstMrkAnet.value[i].marca}');
          break;
        case 2:
          _lstConsola.insert(0, 'Agregando ${_lstMrkAnet.value[i].marca}');
          break;
        case 3:
          _lstConsola.insert(0, 'Crawler para ${_lstMrkAnet.value[i].marca}');
          break;
        case 4:
          // print('Marca Eliminada');
      }

      if(_lstMrkAnet.value[i].hasChanges == 4) {
        ///
      }else{

        _refreshLstConsole.value = !_refreshLstConsole.value;
        if(_lstMrkAnet.value[i].hasChanges != 0) {
          await _autoEm.editMarca(_lstMrkAnet.value[i].toJson(), isLocal: false);
          if(!_autoEm.result['abort']) {
            await _autoEm.editMarca(_lstMrkAnet.value[i].toJson(), isLocal: true);
          }else{
            _lstConsola.add('ERROR ${_autoEm.result['body']}');
          }
        }
      }
    }

    await _refreshScreen();
  } 

  ///
  Future<void> _refreshScreen() async {

    _lstMrkAnet.value = [];
    _lstMrkRadec.value = [];
    _lstMrkAldo.value = [];
    _hasChanges.value = false;
    _lstMrkRadecBup = [];
    _lstMrkAldoBup = [];
    _autos = [];
    Future.delayed(const Duration(milliseconds: 250), () async {
      await _getMrksAutoparnet();
      if(mounted) {
        setState(() {});
      }
    });
  }

  ///
  void _setConsole(int change, String auto, {String? err}) async {

    switch (change) {
      case 1:
        _lstConsola.insert(0, 'Guardando $auto');
        break;
      case 2:
        _lstConsola.insert(0, 'Agregando $auto');
        break;
      case 3:
        _lstConsola.insert(0, 'Crawler para $auto');
        break;
      case 4:
        // print('Marca Eliminada');
      case 100:
        _lstConsola.insert(0, err!);
        break;
    }

    _refreshLstConsole.value = !_refreshLstConsole.value;
    await Future.delayed(const Duration(milliseconds: 250));
  }

  ///
  Future<bool?> _dialogSafe(int cantSave) async {

    return await WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'Guardando [ $cantSave ] Marcas',
      body: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Texto(
            txt: 'Espera un momento por favor... '
            'Estamos modificando los datos mientras procesamos '
            'tu solicitud.\n\n'
            '¡Ten paciencia por favor!',
            isCenter: true, txtC: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
      dismissible: false,
    );
  }
}