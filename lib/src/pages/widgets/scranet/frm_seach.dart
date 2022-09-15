import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../services/scranet/system_file_scrap.dart';
import '../texto.dart';

class FrmSearch extends StatefulWidget {

  final Map<String, dynamic> cacheSearch;
  final ValueChanged<Map<String, dynamic>> onSearch;
  const FrmSearch({
    Key? key,
    required this.onSearch,
    this.cacheSearch = const {},
  }) : super(key: key);

  @override
  State<FrmSearch> createState() => _FrmSearchState();
}

class _FrmSearchState extends State<FrmSearch> {

  final _refreshMods = ValueNotifier<bool>(false);
  final _keyFrm = GlobalKey<FormState>();

  final _ctrPiezas = TextEditingController();
  final _fcoPiezas = FocusNode();
  final _ctrMarcas = TextEditingController();
  final _fcoMarcas = FocusNode();
  final _ctrModels = TextEditingController();
  final _fcoModels = FocusNode();
  final _ctrAnios  = TextEditingController();
  final _fcoAnios  = FocusNode();

  List<Map<String, dynamic>> piezas = [];
  List<Map<String, dynamic>> marcas = [];
  Map<String, dynamic> modelos = {};
  List<Map<String, dynamic>> modelosOfMrks = [];
  List<Map<String, dynamic>> anios = [];
  Map<String, dynamic> _search = {};

  @override
  void dispose() {
    _ctrPiezas.dispose();
    _fcoPiezas.dispose();
    _ctrMarcas.dispose();
    _fcoMarcas.dispose();
    _ctrModels.dispose();
    _fcoModels.dispose();
    _ctrAnios.dispose();
    _fcoAnios.dispose();
    _refreshMods.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<String>(
      stream: _hidratarFrm(),
      initialData: 'Checando Sistema',
      builder: (_, AsyncSnapshot<String> snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(snap.hasData) {
            if(snap.data == 'ok') {
              return _frm();
            }
          }
        }

        return Center(
          child: Texto(
            txt: snap.data ?? 'Error intentalo nuevamente.',
            sz: 25,
            isBold: false,
          ),
        );
      },
    );
  }

  ///
  Widget _frm() {

    return Form(
      key: _keyFrm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _dropMarcas(),
            const SizedBox(height: 20),
            _dropModelos(),
            const SizedBox(height: 20),
            _dropAnios(),
            const SizedBox(height: 20),
            _dropPiezas(),
            const SizedBox(height: 20),
            _btnSearch()
          ],
        )
      ),
    );
  }

  ///
  Widget _btnSearch() {

    return ElevatedButton.icon(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.green)
      ),
      onPressed: () => _goSearch(),
      icon: const Icon(Icons.search),
      label: const Texto(
        txt: 'Buscar Genéricas',
        txtC: Colors.black,
      )
    );
  }

  ///
  Widget _dropPiezas() {

    return DropdownSearch<Map<String, dynamic>>(
      popupProps: _popMenu('piezas'),
      items: piezas,
      itemAsString: (Map<String, dynamic> p) => p['value'],
      dropdownDecoratorProps: _dropDeco('piezas'),
      onBeforePopupOpening: (_) {
        _fcoPiezas.requestFocus();
        return Future.value(true);
      },
      onChanged: (value) {
        const campo = 'pieza';
        if(_search.containsKey(campo)) {
          _search[campo] = value;
        }else{
          _search.putIfAbsent(campo, () => value);
        }
      },
      selectedItem: (widget.cacheSearch.isNotEmpty)
        ? widget.cacheSearch['pieza'] : piezas.first,
    );
  }

  ///
  Widget _dropMarcas() {

    return DropdownSearch<Map<String, dynamic>>(
      popupProps: _popMenu('marcas'),
      items: marcas,
      itemAsString: (Map<String, dynamic> p) => p['value'],
      dropdownDecoratorProps: _dropDeco('marcas'),
      onBeforePopupOpening: (_) {
        _fcoMarcas.requestFocus();
        return Future.value(true);
      },
      onChanged: (value) {
        modelosOfMrks = List<Map<String, dynamic>>.from(modelos[value!['value']]);
        const campo = 'marca';
        if(_search.containsKey(campo)) {
          _search[campo] = value;
        }else{
          _search.putIfAbsent(campo, () => value);
        }
        _refreshMods.value = !_refreshMods.value;
      },
      selectedItem: (widget.cacheSearch.isNotEmpty)
        ? widget.cacheSearch['marca'] : marcas.first,
    );
  }

  ///
  Widget _dropModelos() {

    return ValueListenableBuilder(
      valueListenable: _refreshMods,
      builder: (_, val, __) {
        
        return DropdownSearch<Map<String, dynamic>>(
          popupProps: _popMenu('modelos'),
          items: (modelosOfMrks.isEmpty)
          ? [{'id': '', 'value': 'SELECCIONA UNA MARCA'}]
          : modelosOfMrks,
          itemAsString: (Map<String, dynamic> p) => p['value'],
          dropdownDecoratorProps: _dropDeco('modelos'),
          onBeforePopupOpening: (_) {
            _fcoModels.requestFocus();
            return Future.value(true);
          },
          onChanged: (value) {
            const campo = 'modelo';
            if(_search.containsKey(campo)) {
              _search[campo] = value;
            }else{
              _search.putIfAbsent(campo, () => value);
            }
          },
          selectedItem: (modelosOfMrks.isEmpty)
          ? {'id': '', 'value': 'SELECCIONA UNA MARCA'}
          : modelosOfMrks.first,
        );
      }
    );
  }

  ///
  Widget _dropAnios() {

    return DropdownSearch<Map<String, dynamic>>(
      popupProps: _popMenu('anios'),
      items: anios,
      itemAsString: (Map<String, dynamic> p) => p['value'],
      dropdownDecoratorProps: _dropDeco('anios'),
      onBeforePopupOpening: (_) {
        _fcoAnios.requestFocus();
        return Future.value(true);
      },
      onChanged: (value) {
        const campo = 'anio';
        if(_search.containsKey(campo)) {
          _search[campo] = value;
        }else{
          _search.putIfAbsent(campo, () => value);
        }
      },
      selectedItem: (widget.cacheSearch.isNotEmpty)
        ? widget.cacheSearch['anio'] : anios.first,
    );
  }

  ///
  PopupProps<Map<String, dynamic>> _popMenu(String tipo) {

    return PopupProps.menu(
      searchFieldProps: _textFieldSear(tipo),
      showSearchBox: true,
      itemBuilder: (context, item, isSelected) => _itemResult(item['value']),
    );
  }

  ///
  TextFieldProps _textFieldSear(String tipo) {

    int index = -1;
    switch (tipo) {
      case 'marcas':
        index = 1;
        break;
      case 'modelos':
        index = 2;
        break;
      case 'anios':
        index = 3;
        break;
      default:
        index = 0;
    }

    return TextFieldProps(
      controller: [_ctrPiezas, _ctrMarcas, _ctrModels, _ctrAnios][index],
      focusNode:  [_fcoPiezas, _fcoMarcas, _fcoModels, _fcoAnios][index],
      autofocus: true
    );
  }

  ///
  DropDownDecoratorProps _dropDeco(String tipo) {

    String label = '';
    switch (tipo) {
      case 'marcas':
        label = 'Lista de Marcas Oficiales';
        break;
      case 'modelos':
        label = 'Lista de Modelos Oficiales';
        break;
      case 'anios':
        label = 'Selecciona un Año por favor';
        break;
      default:
        label = 'Lista de Piezas Oficiales';
    }

    return DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.green)
          ),
          filled: false
      ),
    );
  }

  ///
  Widget _itemResult(String label) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(label),
    );
  }

  ///
  Stream<String> _hidratarFrm() async* {

    yield 'Recuperando Piezas';
    await Future.delayed(const Duration(milliseconds: 250));
    piezas = SystemFileScrap.getAllPiezasFromFile();
    piezas.insert(0, {'id':'', 'value': 'TODAS'});
    _search['pieza'] = piezas.first;

    yield 'Recuperando Marcas';
    await Future.delayed(const Duration(milliseconds: 250));
    marcas = await SystemFileScrap.getAllMarcasBy('radec');
    _search['marca'] = marcas.first;

    yield 'Recuperando Modelos';
    await Future.delayed(const Duration(milliseconds: 250));
    modelos = await SystemFileScrap.getAllModelosBy('radec');
    modelosOfMrks = List<Map<String, dynamic>>.from(modelos[marcas.first['value']]);
    _search['modelo'] = modelosOfMrks.first;

    yield 'Preparando los Años';
    await Future.delayed(const Duration(milliseconds: 250));
    final anioCurrent = (DateTime.now().year) + 1;

    const anioFinal = 1970;
    List<int> aniosT = [];
    for (var i = anioFinal; i <= anioCurrent; i++) {
      aniosT.add(i);
    }
    aniosT = aniosT.reversed.toList();
    anios.add({'id':'', 'value':'TODOS'});
    for (var i = 0; i < aniosT.length; i++) {
      anios.add({'id':'${aniosT[i]}', 'value':'${aniosT[i]}'});
    }
    _search['anio'] = anios.first;
    
    if(widget.cacheSearch.isNotEmpty) {
      _search = widget.cacheSearch;
      modelosOfMrks = List<Map<String, dynamic>>.from(modelos[widget.cacheSearch['marca']['value']]);
    }

    yield 'ok';
  }

  ///
  void _goSearch() {

    if(_keyFrm.currentState!.validate()) {

      widget.onSearch(_search);
    }
  }
}