import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';

import '../widgets_utils.dart';
import 'console_proccs.dart';
import 'tile_marcas_anet.dart';
import 'tile_modelos_anet.dart';
import '../my_tool_tip.dart';
import '../texto.dart';
import '../../../entity/modelos_entity.dart';
import '../../../entity/marcas_entity.dart';
import '../../../repository/autos_repository.dart';
import '../../../services/scranet/system_file_scrap.dart';

class ModelosCp extends StatefulWidget {

  const ModelosCp({Key? key}) : super(key: key);

  @override
  State<ModelosCp> createState() => _ModelosCpState();
}

class _ModelosCpState extends State<ModelosCp> {

  final _auto = ValueNotifier<Map<String, dynamic>>({});
  final _lstMrkAnet = ValueNotifier<List<MarcasEntity>>([]);
  final _lstMdlAnet = ValueNotifier<List<ModelosEntity>>([]);
  final _mrkSelected = ValueNotifier<String>('');

  final _lstMdlRadec = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _lstMdlAldo = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _refreshLstConsole = ValueNotifier<bool>(false);
  final _hasChanges = ValueNotifier<bool>(false);
  List<Map<String, dynamic>> _lstMdlRadecBup = [];

  final _scrollAnetCtr = ScrollController();
  final _scrollAnetMdsCtr = ScrollController();
  final _scrollRadecCtr = ScrollController();
  final _scrollAldoCtr = ScrollController();
  final _autoEm = AutosRepository();

  List<Map<String, dynamic>> _lstMdlAldoBup = [];

  List<Map<String, dynamic>> _autos = [];
  final List<String> _lstConsola = [];

  late Future<void> _getMarcasAutopanet;
  int _idMarkSelect = 0;
  // Usado la primera ves para guardar todas las marcas y sus modelos sin hacer
  // click en cada uno y guardar.
  bool _isAutomatic = false;
  int _automaticIndMrk = -1;


  @override
  void initState() {
    _getMarcasAutopanet = _getMrksAutoparnet();
    super.initState();
  }

  @override
  void dispose() {
    _auto.dispose();
    _lstMrkAnet.dispose();
    _lstMdlAnet.dispose();
    _mrkSelected.dispose();

    _lstMdlRadec.dispose();
    _lstMdlAldo.dispose();
    _scrollAnetCtr.dispose();
    _scrollAnetMdsCtr.dispose();
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
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: _marcasAutoparnet(),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.green,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _mrkSelected,
                        builder: (_, val, __) {

                          String label = 'MODELOS DE: ... ';
                          if(val.isNotEmpty) {
                            label = val;
                          }

                          return Texto(
                            txt: label,
                            txtC: Colors.black,
                            isBold: true, isCenter: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _lstMdlAnet,
                        builder: (_, lst, child) {

                          if(lst.isEmpty) { return _load(); }
                          return _lstModelosAnet();
                        },
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ),
        Expanded(
          flex: 2,
          child: _modelosRadec()
        ),
        Expanded(
          flex: 2,
          child: _modelosAldo()
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
  Widget _modelosRadec() {

    return ValueListenableBuilder(
      valueListenable: _lstMdlRadec,
      builder: (_, lst, child) {
        return (lst.isNotEmpty) ? _lista('radec') : child!;
      },
      child: _sinData(),
    );
  }

  ///
  Widget _modelosAldo() {

    return ValueListenableBuilder(
      valueListenable: _lstMdlAldo,
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
                        _lstMdlRadec.value = _lstMdlRadecBup; 
                        _lstMdlAldo.value = _lstMdlAldoBup;
                        _auto.value = {};
                      },
                      icon: const Icon(Icons.refresh, size: 18,),
                      label: const Texto(txt: 'Resetear Panel')
                    ),
                    const SizedBox(height: 20),
                    _tileCar('${val['id']}', 'ID'),
                    _tileCar(val['modelo'], 'Modelo'),
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
                          onPressed: () async => await _saveModeloFromPanel(),
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

    String label = 'MODELOS AutoparNet';
    
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
                    onTap: (marca) async {

                      // _isAutomatic = true;
                      // _automaticIndMrk = index;
                      _mrkSelected.value = _lstMrkAnet.value[index].marca;
                      _lstMdlAnet.value = [];
                      _lstConsola.clear();
                      await _fncAnet(_lstMrkAnet.value[index]);
                    },
                    onDelete: (borrar) {
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
  Widget _lstModelosAnet() {

    return Scrollbar(
      controller: _getCtr('anetMds'),
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: ListView.builder(
        controller: _getCtr('anetMds'),
        itemCount: _lstMdlAnet.value.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemBuilder: (_, index) => TileModelosAnet(
          md: _lstMdlAnet.value[index],
          onTap: (mod) {
            _fetchSimyls(mod);
            _auto.value = mod.toJson();
          },
          onDelete: (borrar) {
            if(borrar) {
              // print(_lstMdlAnet.value[index]);
            }
          }
        )
      )
    );
  }

  ///
  Widget _tileAuto(Map<String, dynamic> auto, String ofBy) {

    String autoName = auto['value'];
    
    if(autoName.contains('MBENZ')) {
      autoName = autoName.replaceAll('MBENZ', '').trim();
    }

    if(autoName.length > 9) {
      autoName = auto['value'].toString().substring(0, 9);
    }
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
          MyToolTip(
            msg: '${auto['value']} -> ${auto['id']}',
            child: Text(
              autoName,
              textScaleFactor: 1,
              style: TextStyle(
                color: (auto.containsKey('existe'))
                  ? (auto['value'] == 'DESCONOCIDO')
                    ?  const Color.fromARGB(255, 73, 73, 73) : Colors.orange
                : Colors.blue
              ),
            )
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
                    final e = ModelosEntity();
                    e.fromAddNew(auto, _idMarkSelect, ofBy);
                    _lstMdlAnet.value.insert(0, e);
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
      case 'anetMds':
        return _scrollAnetMdsCtr;
      default:
        return _scrollAnetCtr;
    }
  }

  ///
  List<dynamic> _getLst(String ofBy) {

    switch (ofBy) {
      case 'radec':
        return _lstMdlRadec.value;
      case 'aldo':
        return _lstMdlAldo.value;
      default:
        return _lstMrkAnet.value;
    }
  }

  ///
  Future<void> _fncAnet(MarcasEntity marca) async {

    List<Map<String, dynamic>> aTmp = await _autoEm.getModelosByIdMarca(marca.id);
    List<ModelosEntity> mTmp = [];
    if(aTmp.isNotEmpty) {
      for (var i = 0; i < aTmp.length; i++) {
        final e = ModelosEntity();
        e.fromServer(aTmp[i]);
        mTmp.add(e);
      }
    }

    _lstMdlRadecBup = await SystemFileScrap.getAllModelosByIdMarca('radec', marca.simyls['radec']!);
    _lstMdlAldoBup = await SystemFileScrap.getAllModelosByIdMarca('aldo', marca.simyls['aldo']!);

    // Revisamos similitudes
    if(mTmp.isNotEmpty) {
      for (var i = 0; i < mTmp.length; i++) {
        mTmp[i] = _fetchSimyls(mTmp[i]);
      }
    }

    // Revisar que todos los modelos que tiene autoparNet esten en RADEC
    List<String> names = mTmp.map<String>((e) => e.modelo).toList();
    for (var i = 0; i < _lstMdlRadecBup.length; i++) {
      bool existe = _existeEn(names, _lstMdlRadecBup[i]['value']);
      if(!existe) {
        _lstMdlRadecBup[i]['existe'] = false;
      }
    }

    _lstMdlRadec.value = List<Map<String, dynamic>>.from(_lstMdlRadecBup);
    
    // Revisar que todos los modelos que tiene autoparNet esten en ALDO
    for (var i = 0; i < _lstMdlAldoBup.length; i++) {
      bool existe = _existeEn(names, _lstMdlAldoBup[i]['value']);
      if(!existe) {
        _lstMdlAldoBup[i]['existe'] = false;
      }
    }
    _lstMdlAldo.value = List<Map<String, dynamic>>.from(_lstMdlAldoBup);

    _lstMdlAnet.value  = List<ModelosEntity>.from(mTmp);
    _mrkSelected.value = '[ ${_lstMdlAnet.value.length} ] MODELOS DE: ${_mrkSelected.value}';
    _idMarkSelect = marca.id;
    mTmp = []; aTmp = [];

    if(_isAutomatic) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _saveAll();
    }
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

    _lstMdlAnet.value = [];
    _lstConsola.clear();

    _autos = await _autoEm.getMarcasAutoparnet();
    List<MarcasEntity> mTmp = [];
    for (var i = 0; i < _autos.length; i++) {
      final e = MarcasEntity();
      e.fromFile(_autos[i]);
      mTmp.add(e);
    }
    _lstMrkAnet.value = List<MarcasEntity>.from(mTmp);

    if(_isAutomatic && _automaticIndMrk != -1) {

      String mrkCurrent = '';
      _automaticIndMrk = _automaticIndMrk+1;
      try {
        mrkCurrent = _lstMrkAnet.value[_automaticIndMrk].marca;
      } catch (e) {
        _setConsole(100, '', err: 'Fin de la Lista');
        _isAutomatic = false;
        _mrkSelected.value = _lstMrkAnet.value.first.marca;
        await _fncAnet(_lstMrkAnet.value.first);
        return;
      }
      _mrkSelected.value = mrkCurrent;
      await _fncAnet(_lstMrkAnet.value[_automaticIndMrk]);

    }else{
      _mrkSelected.value = _lstMrkAnet.value.first.marca;
      await _fncAnet(_lstMrkAnet.value.first);
    }

    _autoEm.cleanResult();
    mTmp = [];
    _autos = [];
  }
  
  ///
  ModelosEntity _fetchSimyls(ModelosEntity auto) {

    List<Map<String, dynamic>> aTmp = [];
    const ratio = 0.2;

    if(_lstMdlRadecBup.isNotEmpty) {

      var matches = StringSimilarity.findBestMatch(
        auto.modelo, _lstMdlRadecBup.map<String>((e) => e['value']).toList()
      );

      if(matches.bestMatch.rating == 1.0) {
        _lstMdlRadec.value = [_lstMdlRadecBup[matches.bestMatchIndex]];
        if(auto.simyls['radec'] != _lstMdlRadecBup[matches.bestMatchIndex]['id']) {
          _hasChanges.value = true;
          auto.hasChanges = 3;
        }
        auto.simyls['radec'] = _lstMdlRadecBup[matches.bestMatchIndex]['id'];
      }else{
        
        _lstMdlRadec.value = [];
        for (var i = 0; i < matches.ratings.length; i++) {
          if(matches.ratings[i].rating! > ratio) {
            final finded = _lstMdlRadecBup.where(
              (element) => element['value'] == matches.ratings[i].target
            );

            if(finded.isNotEmpty) {
              aTmp.add(finded.first);
            }
          }
        }

        _lstMdlRadec.value = List<Map<String, dynamic>>.from(aTmp);
      }
    }

    if(_lstMdlAldoBup.isEmpty) { return auto; }

    var matches = StringSimilarity.findBestMatch(
      auto.modelo, _lstMdlAldoBup.map<String>((e) => e['value']).toList()
    );
    
    if(matches.bestMatch.rating == 1.0) {

      _lstMdlAldo.value = [_lstMdlAldoBup[matches.bestMatchIndex]];
      if(auto.simyls['aldo'] != _lstMdlAldoBup[matches.bestMatchIndex]['id']) {
        _hasChanges.value = true;
        auto.hasChanges = 3;
      }
      auto.simyls['aldo'] = _lstMdlAldoBup[matches.bestMatchIndex]['id'];

    }else{

      _lstMdlAldo.value = [];
      for (var i = 0; i < matches.ratings.length; i++) {
        if(matches.ratings[i].rating! > ratio) {
          final finded = _lstMdlAldoBup.where(
            (element) => element['value'] == matches.ratings[i].target
          );

          if(finded.isNotEmpty) {
            aTmp.add(finded.first);
          }
        }
      }

      _lstMdlAldo.value = List<Map<String, dynamic>>.from(aTmp);
    }

    return auto;
  }

  ///
  bool _existeEn(List<String> craw, String marca) {

    final has = craw.contains(marca);
    return has;
  }

  ///
  Future<void> _saveModeloFromPanel() async {

    final nav = Navigator.of(context);
    _dialogSafe(1);
    _autoEm.cleanResult();
    _setConsole(_auto.value['hasChanges'], _auto.value['modelo']);
    await _autoEm.editModelo(_auto.value, isLocal: false);
    if(!_autoEm.result['abort']) {
      await _autoEm.editModelo(_auto.value, isLocal: true);
      await _refreshScreen();
    }else{
      _setConsole(_auto.value['hasChanges'], _auto.value['modelo']);
    }
    _autoEm.cleanResult();
    nav.pop();
  } 

  ///
  Future<void> _saveAll() async {

    final nav = Navigator.of(context);
    _dialogSafe(_lstMdlAnet.value.length);
    for (var i = 0; i < _lstMdlAnet.value.length; i++) {
      
      _autoEm.cleanResult();
      _setConsole(_lstMdlAnet.value[i].hasChanges, _lstMdlAnet.value[i].modelo);

      if(_lstMdlAnet.value[i].hasChanges == 4) {
        /// Eliminamos
      }else{

        if(_lstMdlAnet.value[i].hasChanges != 0) {
          await _autoEm.editModelo(_lstMdlAnet.value[i].toJson(), isLocal: false);
          if(!_autoEm.result['abort']) {
            await _autoEm.editModelo(_lstMdlAnet.value[i].toJson(), isLocal: true);
          }else{
            _setConsole(100, '', err: 'ERROR ${_autoEm.result['body']}');
          }
        }
      }
    }

    await _refreshScreen();
    nav.pop();
  } 

  ///
  Future<void> _refreshScreen() async {

    _lstMrkAnet.value = [];
    _lstMdlRadec.value = [];
    _lstMdlAldo.value = [];
    _hasChanges.value = false;
    _lstMdlRadecBup = [];
    _lstMdlAldoBup = [];
    _autos = [];
    _idMarkSelect = 0;
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
      titulo: 'Guardando ${ _mrkSelected.value }',
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