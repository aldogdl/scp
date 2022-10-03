import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/invirt/difusor_lsts.dart';
import 'package:scp/src/pages/widgets/texto.dart';
import 'package:scp/src/providers/filtros_provider.dart';
import 'package:scp/src/repository/scranet_anet_repository.dart';
import 'package:scp/src/services/get_content_files.dart';

class LstItemsFiltros extends StatefulWidget {

  final String ofBy;
  final double width;
  final int index;
  final ValueChanged<Map<String, dynamic>> onSelected;
  const LstItemsFiltros({
    Key? key,
    required this.ofBy,
    required this.width,
    required this.index,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<LstItemsFiltros> createState() => _LstItemsFiltrosState();
}

class _LstItemsFiltrosState extends State<LstItemsFiltros> {

  final _scraneEm = ScranetAnetRepository();
  final _ctrScroll = ScrollController();
  final _ctrBk = TextEditingController();
  final _fcuBk = FocusNode();
  final _itemsFil = ValueNotifier<dynamic>([]);

  late FiltrosProvider _prov;

  List<dynamic> _items = [];
  bool _isInit = false;

  @override
  void initState() {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(widget.ofBy == 'marcas') {
        _fcuBk.requestFocus();
      }
    });
    _recoveryItems();
    super.initState();
  }

  @override
  void dispose() {
    _ctrScroll.dispose();
    _itemsFil.dispose();
    _ctrBk.dispose();
    _fcuBk.dispose();
    _prov.myDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      color: (widget.index.isOdd) ? null : Colors.black.withOpacity(0.1),
      child: SizedBox.expand(
        child: Column(
          children: [
            _head(),
            Expanded(
              child: (widget.ofBy == 'modelos')
                ? Selector<FiltrosProvider, bool>(
                    selector: (_, prov) => prov.refresMdls,
                    builder: (_, rf, __) {

                      if(_prov.autos.isNotEmpty) {
                        var lst = List<Map<String, dynamic>>.from(_prov.autos);
                        if(_prov.marca['nombre'] != '0') {
                          lst = lst.where((element) => element['id'] == _prov.marca['id']).toList();
                          lst = List<Map<String, dynamic>>.from(lst.first['modelos']);
                          _items = List<Map<String, dynamic>>.from(lst);
                        }else{
                          if(_ctrBk.text.isEmpty) {
                            for (var i = 0; i < lst.length; i++) {
                              _items.addAll(List<Map<String, dynamic>>.from(lst[i]['modelos']));
                            }
                          }
                        }

                        if(_ctrBk.text.isEmpty) {
                          _itemsFil.value = List<Map<String, dynamic>>.from(_items);
                          return _lst();
                        }
                      }

                      return _buildList();
                    },
                  )
                : _buildList()
            )
          ],
        ),
      ),
    );
  }

  ///
  Widget _buildList() {
    
    return ValueListenableBuilder(
      valueListenable: _itemsFil,
      builder: (_, val, __) => _lst(),
    );
  }

  ///
  Widget _lst() {

    return Scrollbar(
      controller: _ctrScroll,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: DifusorLsts(
        child: ListView.builder(
          controller: _ctrScroll,
          itemCount: _itemsFil.value.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          itemBuilder: (_, index) {

            if(widget.ofBy.startsWith('anios')) {
              return _tileItemAnios(_itemsFil.value[index]);
            }
            String craw = '';
            if(widget.ofBy == 'piezas') {
              craw = 'anet';
            }
            return _tileItem(Map<String, dynamic>.from(_itemsFil.value[index]), craw);
          }
        ),
      )
    );
  }

  ///
  Widget _head() {

    String txt = '';
    switch (widget.ofBy) {
      case 'marcas':
        txt = 'Marcas';
        break;
      case 'modelos':
        txt = 'Modelos';
        break;
      case 'anios_desde':
        txt = 'Desde';
        break;
      case 'anios_hasta':
        txt = 'Hasta';
        break;
      default:
        txt = 'Autopartes';
    }

    return Container(
      width: widget.width * 0.98,
      color: const Color.fromARGB(255, 108, 173, 110),
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _ctrBk.text = '';
                _fcuBk.requestFocus();
              });
            },
            constraints: const BoxConstraints(maxWidth: 25, maxHeight: 28),
            padding: const EdgeInsets.all(0),
            icon: const Icon(Icons.close, size: 18, color: Color.fromARGB(255, 53, 53, 53))
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 25, height: 25,
            child: _fieldBuscador(),
          ),
          const SizedBox(width: 10),
          Texto(txt: txt, txtC: Colors.black, isBold: true),
        ],
      ),
    );
  }

  ///
  Widget _fieldBuscador() {

    return TextField(
      controller: _ctrBk,
      focusNode: _fcuBk,
      onChanged: (val) => _filtrar(val.toUpperCase().trim()),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide.none
        )
      ),
    );
  }

  ///
  Widget _tileItem(Map<String, dynamic> item, String ofBy) {

    String key = 'nombre';
    if(ofBy == 'anet') {
      key = 'value';
    }
    return TextButton(
      style: const ButtonStyle(
        alignment: Alignment.centerLeft
      ),
      onPressed: () => widget.onSelected(item),
      child: Texto(txt: item[key])
    );
  }

  ///
  Widget _tileItemAnios(String anio) {

    return TextButton(
      style: const ButtonStyle(
        alignment: Alignment.centerLeft
      ),
      onPressed: () => widget.onSelected({'anio':anio}),
      child: Texto(txt: anio)
    );
  }

  ///
  Future<void> _recoveryItems() async {

    if(!_isInit) {
      _isInit = true;
      _prov = context.read<FiltrosProvider>();
    }

    if(widget.ofBy == 'marcas') {

      if(_prov.autos.isEmpty) {
        _prov.autos= await GetContentFile.getAllAuto();
      }

      final lst = List<Map<String, dynamic>>.from(_prov.autos);
      if(lst.isNotEmpty) {

        if(widget.ofBy == 'marcas') {
          for (var i = 0; i < lst.length; i++) {
            _items.add(Map<String, dynamic>.from(lst[i]));
            _items[i].remove('modelos');
          }
          _itemsFil.value = List<Map<String, dynamic>>.from(_items);
          Future.microtask(() => _prov.refresMdls = !_prov.refresMdls);
        }
      }
    }

    if(widget.ofBy.startsWith('anios')) {
      final curr = (DateTime.now().year) +1;
      for (var i = 1930; i < curr; i++) {
        _items.add('$i');
      }
      _items = _items.reversed.toList();
      _itemsFil.value = List<String>.from(_items);
    }

    if(widget.ofBy == 'piezas') {
      
      _items = _scraneEm.getAllPiezasNamesFromFile();
      _itemsFil.value = List<Map<String, dynamic>>.from(_items);
    }
  }

  ///
  Future<void> _filtrar(dynamic val) async {

    List<dynamic> lst = [];
    if(widget.ofBy.startsWith('anios')) {
      lst = List<String>.from(_items);
      _itemsFil.value = lst.where((element) => element.contains(val)).toList();
    }else{

      final key = (widget.ofBy == 'piezas') ? 'value' : 'nombre';
      lst = List<Map<String, dynamic>>.from(_items);
      _itemsFil.value = lst.where((element) => element[key].contains(val)).toList();
      if(widget.ofBy == 'modelos') {
        _prov.refresMdls = !_prov.refresMdls;
      }
    }
  }

}