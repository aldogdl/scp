import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../invirt/difusor_lsts.dart';
import 'tile_pzas_result.dart';
import '../my_tool_tip.dart';
import '../texto.dart';
import '../widgets_utils.dart';
import '../../../config/sng_manager.dart';
import '../../../services/scranet/build_data_scrap.dart';
import '../../../services/scranet/system_file_scrap.dart';
import '../../../repository/scranet_anet_repository.dart';
import '../../../vars/globals.dart';

class PiezasCp extends StatefulWidget {

  const PiezasCp({Key? key}) : super(key: key);

  @override
  State<PiezasCp> createState() => _PiezasCpState();
}

class _PiezasCpState extends State<PiezasCp> {

  final _ctrT = TextEditingController();
  final _fco = FocusNode();
  final _ctrF = TextEditingController();
  final _fcoF = FocusNode();

  final _scrollAnetCtr = ScrollController();
  final _scrollRadecCtr = ScrollController();
  final _scrollAldoCtr = ScrollController();

  final _hasChanges = ValueNotifier<bool>(false);

  final _lstPzaAnetFil = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _lstPzaRadecFil= ValueNotifier<List<Map<String, dynamic>>>([]);
  final _lstPzaAldoFil = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _results = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _resultsA = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _resultsR = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _tipoFiltro = ValueNotifier<String>('Filtros:');
  final _pzaSelAldo = ValueNotifier<Map<String, dynamic>>({});
  final _pzaSelRadec = ValueNotifier<Map<String, dynamic>>({});

  final _globals = getSngOf<Globals>();
  final _pzaEm = ScranetAnetRepository();

  List<Map<String, dynamic>> _lstPzaRadec = [];
  List<Map<String, dynamic>> _lstPzaAldo = [];
  List<Map<String, dynamic>> _lstPzaAnet = [];

  Map<String, dynamic> _dataRadec = {};
  Map<String, dynamic> _dataAldo = {};

  String _crawCurrentView = '';
  String _idEdit = '0';
  String _errorTheSave = '0';
  bool _isExtract = false;
  bool _isForSearch = true;


  @override
  void initState() {
    _getPiezasFromFileOf('');
    super.initState();
  }

  @override
  void dispose() {

    _hasChanges.dispose();
    _lstPzaRadecFil.dispose();
    _lstPzaAldoFil.dispose();
    _lstPzaAnetFil.dispose();
    _ctrT.dispose();
    _fco.dispose();
    _ctrF.dispose();
    _fcoF.dispose();
    _scrollAnetCtr.dispose();
    _scrollRadecCtr.dispose();
    _scrollAldoCtr.dispose();
    _results.dispose();
    _resultsR.dispose();
    _resultsA.dispose();
    _tipoFiltro.dispose();
    _pzaSelAldo.dispose();
    _pzaSelRadec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 7,
                  child: _panel(),
                ),
                Expanded(
                  flex: 5,
                  child: _lstAldo(),
                ),
                Expanded(
                  flex: 5,
                  child: _lstRadec(),
                )
              ],
            ),
          ),
          const Divider(color: Color.fromARGB(255, 63, 63, 63), height: 30),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 8,
                  child: _lstResults(),
                ),
                Expanded(
                  flex: 5,
                  child: _lstAnet(),
                )
              ],
            ),
          )
        ],
      )
    );
  }

  ///
  Widget _panel() {

    int num = 0;
    return Column(
      children: [
        const Texto(
          txt: 'Sigue las indicaciones para hacer Match correctamente',
          txtC: Colors.green, sz: 12,
        ),
        const Divider(color: Colors.green),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: DifusorLsts(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 15),
                      children: _getCriterios().map((e) {
                        num = num+1;
                        return Texto(txt: '$num. $e');
                      }).toList(),
                    )
                  ),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: _searchItemField('top'),
                    )
                  ),
                  IconButton(
                    onPressed: () async => await _savePzaAnet(),
                    icon: const Icon(Icons.save, color: Colors.blue),
                    tooltip: 'Guardar TODO',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(0),
                    iconSize: 30,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _dropTarget('aldo'),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<Map<String, dynamic>>(
                              valueListenable: _pzaSelAldo,
                              builder: (_, val, __) => _panelPzaSelect('aldo', val)
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _dropTarget('radec'),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            ValueListenableBuilder<Map<String, dynamic>>(
                              valueListenable: _pzaSelRadec,
                              builder: (_, val, __) => _panelPzaSelect('radec', val)
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                )
              )
            ],
          )
        ),
      ],
    );
  }

  ///
  Widget _lstAldo() {

    return LayoutBuilder(
      builder: (_, constraint) {
        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _lstPzaAldoFil,
          builder: (_, lst, child) {

            if(lst.isEmpty){ return child!; }
            return _lista('aldo', width: constraint.maxWidth);
          },
          child: _sinData(),
        );
      },
    );
  }

  ///
  Widget _lstRadec() {

    return ValueListenableBuilder(
      valueListenable: _lstPzaRadecFil,
      builder: (_, lst, child) {
        if(lst.isNotEmpty) {
          return _lista('radec');
        }
        return _sinData();
      },
    );
  }

  ///
  Widget _lstResults() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          height: 35,
          child: _filterPzasField(),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, cst) {

              return Container(
                width: cst.maxWidth,
                height: cst.maxHeight,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _results,
                  builder: (_, lst, child) {

                    if(lst.isEmpty) {
                      return child!;
                    }else{
                      if(lst.first.containsKey('load')) {
                        return _load();
                      }
                    }
                    
                    return ListView.builder(
                      itemCount: lst.length,
                      itemBuilder: (_, index) {
                        return TilePzasResult(
                          pza: lst[index], craw: _crawCurrentView,
                          maxWidth: cst.maxWidth * 0.8,
                        );
                      }
                    );

                  },
                  child: const SizedBox(),
                )
              );
            },
          )
        )
      ],
    );
  }

  ///
  Widget _lstAnet() {

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _lstPzaAnetFil,
      builder: (_, lst, child) {

        if(lst.isEmpty){ return child!; }
        return _lista('anet');
      },
      child: _sinData(),
    );
  }

  ///
  Widget _panelPzaSelect(String craw, Map<String, dynamic> val) {

    if(val.isEmpty){ 
      val['id'] = '000';
      val['value'] = 'Nombre de la Piezas';
    }
    val['sap'] = '000';
    val['cat'] = '000';
    val['cst'] = '\$000';

    if(craw == 'aldo') {
      if(_dataAldo.isNotEmpty) {
        val['sap'] = _dataAldo['sap'];
        val['cat'] = _dataAldo['idP'];
        val['cst'] = _dataAldo['cost'];
      }
    }
    if(craw == 'radec') {
      if(_dataRadec.isNotEmpty) {
        val['sap'] = _dataRadec['sap'];
        val['cat'] = _dataRadec['idP'];
        val['cst'] = _dataRadec['cost'];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SelectableText(
          val['value'], 
          textScaleFactor: 1,
          style: const TextStyle(
            color: Colors.grey, fontSize: 12
          ),
        ),
        Row(
          children: [
            Texto(txt: 'IdPza.: ${val['id']}', sz: 13, txtC: Colors.yellow),
            const SizedBox(width: 8),
            Texto(txt: 'SAP: ${val['sap']}', sz: 11, txtC: Colors.green,),
            const SizedBox(width: 8),
            Texto(txt: 'CAT: ${val['cat']}', sz: 11, txtC: Colors.green,),
          ],
        ),
        Row(
          children: [
            Texto(txt: 'CST: ${val['cst']}', sz: 12),
            const SizedBox(width: 8),
            if(craw == 'aldo')
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _resultsA,
                builder: (_, val, __) {
                  return TextButton(
                    onPressed: () async {
                      if(_pzaSelAldo.value.containsKey('id')) {
                        await _getPzasFromPageOf('aldo');
                      }
                    },
                    child: Texto(txt: 'ALD: [${val.length}]', txtC: Colors.blue)
                  );
                }
              ),
            if(craw == 'radec')
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _resultsR,
                builder: (_, val, __) {
                  return TextButton(
                    onPressed: () async {
                      if(_pzaSelRadec.value.containsKey('id')) {
                        await _getPzasFromPageOf('radec');
                      }
                    },
                    child: Texto(txt: 'RDC: [${val.length}]', txtC: Colors.blue)
                  );
                }
              ),
          ],
        )
      ],
    );
  }
  
  ///
  Widget _dropTarget(String craw) {

    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) {
        if(data != null) {
          if(data.containsKey('craw')){
            return data['craw'] == craw ? true : false;
          }
        }
        return false;
      },
      onAccept: (data) {
        if(craw == 'radec') {
          _dataRadec = data;
        }
        if(craw == 'aldo') {
          if(data.containsKey('ref')) {
            _isExtract = false;
            _isForSearch = true;
            _resultsR.value = [];
            if(mounted) {
              _ctrF.text = data['ref'].toString().toUpperCase().trim();
            }
          }
          _dataAldo = data;
        }
        if(mounted) {
          setState(() {});
        }
      },
      builder: (_, candidateData, rejectedData) {
        
        return Container(
          width: 70, height: 55,
          decoration: BoxDecoration(
            color: (rejectedData.isEmpty)
              ? (candidateData.isEmpty)
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.5)
              : Colors.red.withOpacity(0.2),
            border: Border.all(color: const Color.fromARGB(255, 65, 65, 65)),
            borderRadius: BorderRadius.circular(5)
          ),
          child: _getDropWidgetByCrawler(craw, candidateData)
        );
      },

    );
  }

  ///
  Widget _getDropWidgetByCrawler(String craw, List<Map<String, dynamic>?> data) {

    String url = '';
    if(data.isNotEmpty) {

      url = data.first!['img'];

    }else{

      if(craw == 'radec') {
        url = (_dataRadec.isNotEmpty)
          ? _dataRadec['img']
          : data.isNotEmpty ? _dataRadec['img'] : url;
      }

      if(craw == 'aldo') {
        url = (_dataAldo.isNotEmpty)
          ? _dataAldo['img']
          : data.isNotEmpty ? _dataAldo['img'] : url;
      }
    }

    if(url.isNotEmpty) {

      return InkWell(
        onTap: () => _showFotosBig(),
        child: SizedBox(
          width: 70, height: 55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
              child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
            ),
          )
        ),
      );
    }

    return Center(
      child: Texto(txt: craw, isBold: true, txtC: Colors.green),
    );
  }

  ///
  List<String> _getCriterios() {

    return [
      'Teclea la pieza requerida en el buscador.',
      'Selecciona primero del crawler Aldo la pieza requerida.',
      'De los resultados arrastra la foto a su contenedor.',
      'En la caja de filtro verás la marca de referencia.',
      'Ahora puedes seleccionar la piezas del otro crawler.',
      'De los resultados arrastra la foto a su contenedor.',
      'Al presionar cualquier contenedor verás comparativo.',
      'Teclea en la caja de búsqueda el NOMBRE OFICIAL.',
      'Presional al terminar el icono de GUARDAR.'
    ];
  }

  ///
  Widget _lista(String ofBy, {double width = 0}) {

    String label = '';
    List<Map<String, dynamic>> l = [];

    if(ofBy == 'radec') {
      label = 'Radec';
      l = _getLst(ofBy);
    }

    if(ofBy == 'aldo') {
      label = 'Aldo';
      l = _getLst(ofBy);
    }

    if(ofBy == 'anet') {
      label = 'PIEZAS AutoparNet';
      l = _getLst(ofBy);
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
                  '${_getLstCant(ofBy)}'
                ),
              ),
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
              itemCount: _getLstCant(ofBy),
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemBuilder: (_, index) {

                if(ofBy == 'anet') {
                  return _tilePzaAnet(l[index], index.isEven);
                }
                return _tilePza(
                  Map<String, dynamic>.from(l[index]), ofBy, width: width
                );
              }
            )
          ),
        )
      ],
    );
  }
  
  ///
  Widget _searchItemField(String ofBy) {

    return TextField(
      controller: _ctrT,
      focusNode: _fco,
      autofocus: true,
      onChanged: (String val) => _buscarPza(val),
      onSubmitted: (v) {},
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        enabledBorder: _border(),
        focusedBorder: _border(),
        hintText: 'Busca la Pieza Requerida ...',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3)
        )
      ),
    );
  }

  ///
  Widget _filterPzasField() {

    return Row(
      children: [
        ValueListenableBuilder<String>(
          valueListenable: _tipoFiltro,
          builder: (_, val, __) {
            return Texto(txt: val);
          }
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _ctrF,
            focusNode: _fcoF,
            autofocus: true,
            onSubmitted: (v) {

            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
              enabledBorder: _border(),
              focusedBorder: _border(),
              hintText: 'Filtra por criterios...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3)
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Limpiar Caja de busqueda',
                    constraints: const BoxConstraints(maxWidth: 35),
                    icon: const Icon(
                      Icons.close, size: 18, color: Color.fromARGB(255, 240, 89, 89)
                    ),
                    onPressed: () {
                      if(mounted) {
                        setState(() {
                          _ctrF.text = '';
                        });
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Realizar Filtrado',
                    constraints: const BoxConstraints(maxWidth: 35),
                    icon: const Icon(
                      Icons.filter_alt_outlined, size: 18, color: Color.fromARGB(255, 60, 63, 243)
                    ),
                    onPressed: () async => await _getPzasFromPageOf(_crawCurrentView),
                  ),
                  IconButton(
                    tooltip: 'Limpiar Cache de busqueda',
                    constraints: const BoxConstraints(maxWidth: 35),
                    icon: Icon(
                      Icons.cleaning_services_sharp, size: 16,
                      color: (_resultsR.value.isNotEmpty)
                        ? const Color.fromARGB(255, 219, 161, 36)
                        : const Color.fromARGB(255, 73, 73, 73)
                    ),
                    onPressed: () {
                      setState(() {
                        _resultsR.value = [];
                      });
                    },
                  )
                ],
              ),
              prefixIcon: const Icon(
                Icons.search, size: 18, color: Color.fromARGB(255, 78, 78, 78)
              )
            ),
          ),
        ),
        const SizedBox(width: 15),
        Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _isForSearch,
                visualDensity: VisualDensity.compact,
                checkColor: Colors.black,
                onChanged: (val) {
                  _isExtract = !_isExtract;
                  setState(() {
                    _isForSearch = !_isForSearch;
                  });
                }
              ),
            ),
            const SizedBox(width: 2),
            const Texto(txt: 'Buscador')
          ],
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                value: _isExtract,
                visualDensity: VisualDensity.compact,
                checkColor: Colors.black,
                onChanged: (val) {
                  _isForSearch = !_isForSearch;
                  setState(() {
                    _isExtract = !_isExtract;
                  });
                }
              ),
            ),
            const SizedBox(width: 2),
            const Texto(txt: 'Extraer'),
            const SizedBox(width: 10),
          ],
        )
      ],
    );
  }

  ///
  Widget _tilePza(Map<String, dynamic> pza, String craw, {double width = 0}) {

    final child = InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {

        _crawCurrentView = craw;
        if(craw == 'aldo') {
          if(_pzaSelAldo.value.isNotEmpty){
            if(_pzaSelAldo.value['id'] != pza['id']) {
              _resultsA.value = [];
            }
          }
          _pzaSelAldo.value = pza;
        }

        if(craw == 'radec') {
          if(_pzaSelRadec.value.isNotEmpty){
            if(_pzaSelRadec.value['id'] != pza['id']) {
              _resultsR.value = [];
            }
          }
          _pzaSelRadec.value = pza;
        }
        await _getPzasFromPageOf(craw);
      },
      child: MyToolTip(
        msg: 'ID: ${pza['id']}',
        child: Text(
          pza['value'],
          textScaleFactor: 1,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 11.5,
            color: Colors.grey
          ),
        )
      ),
    );

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: (width > 0)
            ? SizedBox(
                width: width - 50,
                child: child,
              )
            : child
        )
      ],
    );
  }

  ///
  Widget _tilePzaAnet(Map<String, dynamic> pza, bool isEven) {

    const cst = BoxConstraints(maxWidth: 25, maxHeight: 28);
    String label = pza['value'];
    if(label.length > 30) {
      label = '${label.substring(0, 30)}...';
    }

    return Container(
      color: (isEven) ? Colors.black.withOpacity(0.3) : Colors.transparent,
      child: Row(
        children: [
          const SizedBox(width: 5),
          MyToolTip(
            msg: pza['value'],
            child: SelectableText(
              label,
              textScaleFactor: 1,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.grey
              ),
            ),
          ),
          const Spacer(),
          _tileSymil(pza, 'ALD'),
          const SizedBox(width: 10),
          _tileSymil(pza, 'RDC'),
          if(pza.containsKey('stt'))
            Padding(
              padding: const EdgeInsets.all(5),
              child: (pza['stt'] == 1)
              ? IconButton(
                tooltip: 'Click para ver los errores',
                onPressed: () => _showErrors(),
                padding: const EdgeInsets.all(0),
                constraints: cst,
                icon: const Icon(Icons.error, size: 18, color: Colors.yellow)
              )
              : const SizedBox(
                  width: 15, height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            )
          else 
            ...[
              IconButton(
                onPressed: () async => await _editPiezaOficial(pza['id']),
                padding: const EdgeInsets.all(0),
                constraints: cst,
                icon: const Icon(Icons.edit, size: 18, color: Colors.blue)
              ),
              IconButton(
                onPressed: () async => await _deletePiezaOficial(pza['id']),
                constraints: cst,
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.close, size: 18, color: Color.fromARGB(255, 236, 68, 68))
              ),
            ]
        ],
      ),
    );

  }

  ///
  Widget _tileSymil(Map<String, dynamic> pza, String craw) {

    String tip = '';
    if(craw == 'RDC') {
      if(pza['simyls'].containsKey('radec')) {
        tip = pza['simyls']['radec'];
      }
      craw = 'radec';
    }
    if(craw == 'ALD') {
      if(pza['simyls'].containsKey('aldo')) {
        tip = pza['simyls']['aldo'];
      }
      craw = 'aldo';
    }

    return MyToolTip(
      msg: tip,
      child: Text(
        craw,
        textScaleFactor: 1,
        maxLines: 3,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: (pza['simyls']['radec'] != '0')
            ? Colors.orange
            : Colors.grey,
          decoration: (pza['simyls']['aldo'] != '0')
            ? TextDecoration.none
            : TextDecoration.lineThrough,
          decorationColor: Colors.red,
          decorationStyle: TextDecorationStyle.solid,
          decorationThickness: 2.9
        ),
      )
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
  OutlineInputBorder _border() {

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey)
    );
  }

  ///
  List<Map<String, dynamic>> _getLst(String craw) {

    switch (craw) {
      case 'radec':
        return _lstPzaRadecFil.value;
      case 'aldo':
        return _lstPzaAldoFil.value;
      default:
        return _lstPzaAnetFil.value;
    }
  }

  ///
  int _getLstCant(String craw) {

    switch (craw) {
      case 'radec':
        return _lstPzaRadecFil.value.length;
      case 'aldo':
        return _lstPzaAldoFil.value.length;
      default:
        return _lstPzaAnetFil.value.length;
    }

  }

  ///
  ScrollController _getCtr(String craw) {

    switch (craw) {
      case 'radec':
        return _scrollRadecCtr;
      case 'aldo':
        return _scrollAldoCtr;
      default:
        return _scrollAnetCtr;
    }
  }

  ///
  void _showFotosBig() {

    final tam = MediaQuery.of(context).size;

    Widget child = Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.filter, size: 150, color: Color.fromARGB(255, 94, 94, 94)),
        const SizedBox(height: 10),
        SizedBox(
          width: tam.width * 0.4,
          child: const Texto(
            txt: 'Para visualizar un comparativo fotográfico es '
            'necesario que, las dos imágenes estén en sus respectivos '
            'contenedores.', isCenter: true, sz: 20,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Texto(txt: 'ENTENDIDO', txtC: Colors.white)
        )
      ],
    );
    
    if(_dataAldo.isNotEmpty && _dataRadec.isNotEmpty) {
      child = Row(
        children: [
          Expanded(
            flex: 6,
            child: _cacheImg(_dataAldo['imgB']),
          ),
          Expanded(
            flex: 6,
            child: _cacheImg(_dataRadec['imgB'])
          )
        ],
      );
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        content: Container(
          padding: const EdgeInsets.all(10),
          width: tam.width,
          height: tam.height * 0.55,
          child: child,
        ),
      )
    );
  }

  ///
  Widget _cacheImg(String url) {

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorWidget: (_, err, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Image(
              image: AssetImage('assets/logo_dark.png'),
              fit: BoxFit.none,
            ),
            const SizedBox(height: 8),
            Texto(txt: err, sz: 15)
          ],
        );
      },
    );
  }

  ///
  void _buscarPza(String val) {

    _lstPzaRadecFil.value = [];
    var l = _lstPzaRadec.where(
      (e) => e['value'].toString().toUpperCase().contains(val.toUpperCase().trim())
    );
    if(l.isNotEmpty) {
      _lstPzaRadecFil.value = List<Map<String, dynamic>>.from(l);
    }

    _lstPzaAldoFil.value = [];
    l = _lstPzaAldo.where(
      (e) => e['value'].toString().toUpperCase().contains(val.toUpperCase().trim())
    );
    if(l.isNotEmpty) {
      _lstPzaAldoFil.value = List<Map<String, dynamic>>.from(l);
    }
  }

  ///
  void _showErrors() {

  }

  ///
  Future<void> _getPiezasFromFileOf(String de) async {

    if(de.isEmpty) {
      _lstPzaAnet = SystemFileScrap.getPiezasToList('anet');
      _lstPzaAnetFil.value = List<Map<String, dynamic>>.from(_lstPzaAnet);
      _lstPzaRadec = SystemFileScrap.getPiezasToList('radec');
      _lstPzaRadecFil.value = List<Map<String, dynamic>>.from(_lstPzaRadec);
      if(_lstPzaRadec.isNotEmpty) {
        _lstPzaAldo = SystemFileScrap.getPiezasToList('aldo');
        _lstPzaAldoFil.value = List<Map<String, dynamic>>.from(_lstPzaAldo);
      }
    }else{
      switch (de) {
        case 'radec':
          _lstPzaRadecFil.value = [];
          _lstPzaRadec = SystemFileScrap.getPiezasToList(de);
          _lstPzaRadecFil.value = List<Map<String, dynamic>>.from(_lstPzaRadec);
          break;
        case 'aldo':
          _lstPzaAldoFil.value = [];
          _lstPzaAldo = SystemFileScrap.getPiezasToList(de);
          _lstPzaAldoFil.value = List<Map<String, dynamic>>.from(_lstPzaAldo);
          break;
        case 'anet':
          _lstPzaAnetFil.value = [];
          _lstPzaAnet = SystemFileScrap.getPiezasToList('anet');
          _lstPzaAnetFil.value = List<Map<String, dynamic>>.from(_lstPzaAnet);
          break;
        default:
      }
    }
  }

  ///
  Future<void> _getPzasFromPageOf(String craw) async {

    _results.value = [{'load':''}];

    Future.delayed(const Duration(milliseconds: 250), () async {

      if(craw == 'radec') {
        if(_resultsR.value.isEmpty) {
          _results.value = await BuildDataScrap.fetchPiezasOf(craw, _pzaSelRadec.value['id']!, _ctrF.text);
          _resultsR.value = List<Map<String, dynamic>>.from(_results.value);
        }else{
          _results.value = List<Map<String, dynamic>>.from(_resultsR.value);
        }
      }

      if(craw == 'aldo') {
        if(_resultsA.value.isEmpty || _ctrF.text.isNotEmpty) {
          _results.value = await BuildDataScrap.fetchPiezasOf(craw, _pzaSelAldo.value['id']!, _ctrF.text);
          _resultsA.value = List<Map<String, dynamic>>.from(_results.value);
        }else{
          _results.value = List<Map<String, dynamic>>.from(_resultsA.value);
        }
        _resultsA.value = List<Map<String, dynamic>>.from(_results.value);
      }

      Future.delayed(const Duration(milliseconds: 250), () async {
        if(craw == 'radec') {
          setState(() {});
        }        
      });
    });
  }

  ///
  Future<void> _savePzaAnet() async {

    String nom = _ctrT.text.toUpperCase().trim();
    final msg = _checkNombre(nom);

    if(msg != 'ok') {

      bool? continuar = true;
      if(msg.startsWith('[!]')) {

        continuar = await WidgetsAndUtils.showAlert(
          context, titulo: 'ALERTA AL GUARDAR', onlyAlert: false,
          msg: msg, onlyYES: false, msgOnlyYes: 'SÍ, CONTINUAR',withYesOrNot: true
        );
        continuar = (continuar == null) ? false : continuar;

      }else{

        WidgetsAndUtils.showAlert(
          context, titulo: 'ALERTA AL GUARDAR', onlyAlert: false,
          msg: msg, onlyYES: true, msgOnlyYes: 'ENTENDIDO'
        );
        continuar = false;
      }

      if(!continuar) {
        return;
      }
    }

    _lstPzaAnetFil.value = [];
    Map<String, String> simyls = {};

    if(_pzaSelAldo.value.isNotEmpty) {
      simyls['aldo'] = '0';
      if(_pzaSelAldo.value['id'] != '000') {
        simyls['aldo'] = _pzaSelAldo.value['id'];
      }
    }
    
    if(_pzaSelRadec.value.isNotEmpty) {
      simyls['radec'] = '0';
      if(_pzaSelRadec.value['id'] != '000') {
        simyls['radec'] = _pzaSelRadec.value['id'];
      }
    }
    
    var pzas = List<Map<String, dynamic>>.from(_lstPzaAnet);
    Map<String, dynamic> np = {};
    if(nom.contains('.SET')) {
      final partes = nom.split('.');
      nom = partes.first.trim();
    }

    if(_idEdit != '0') {
      int ind = pzas.indexWhere((element) => '${element['id']}' == _idEdit);
      if(ind != -1) {
        np = pzas[ind];
        np['value'] = nom;
        np['simyls'] = simyls;
        pzas[ind] = np;
      }
    }else{
      np = {
        'id': '${DateTime.now().millisecondsSinceEpoch}',
        'stt': 0,
        'value': nom,
        'simyls': simyls,
      };
      pzas.insert(0, np);
    }
    _lstPzaAnet = pzas;
    _resetScreen();
    _saveServers(np);
  }

  /// Guardamos las piezas en los servidores.
  Future<void> _saveServers(Map<String, dynamic> np) async {

    _pzaEm.setPiezaName(np).then((value) async {

      if(value == 'ok') {
        await _getPiezasFromFileOf('anet');
      }else{
        np['stt'] = 1;
        var pzas = List<Map<String, dynamic>>.from(_lstPzaAnet);
        int ind = pzas.indexWhere((element) => element['id'] == np['id']);
        if(ind != -1) { pzas[ind] = np; }
        _lstPzaAnet = pzas;

        pzas = List<Map<String, dynamic>>.from(_lstPzaAnetFil.value);
        _lstPzaAnetFil.value = [];
        ind = pzas.indexWhere((element) => element['id'] == np['id']);
        if(ind != -1) { pzas[ind] = np; }
        _lstPzaAnetFil.value = List<Map<String, dynamic>>.from(_lstPzaAnet);
        _errorTheSave = value;
      }
    });
  }

  ///
  String _checkNombre(String nom) {

    String msg = 'ok';

    if(!nom.contains('.SET')) {

      if(_pzaSelAldo.value['id'] == '000' && _pzaSelRadec.value['id'] == '000') {
        msg = 'Es necesario que insertes las fotografías de los Crawlers en sus '
        'respectivos contenedores. No olvides que deben estar las dos fotos de los '
        'distintos crawlers.';
        return msg;
      }
    }else{
      final partes = nom.split('.');
      nom = partes.first.toUpperCase().trim();
    }

    if(nom.isEmpty) {
      msg = 'Es necesario que coloques el nombre oficial de la Autoparte '
      'que quedará permanentemente.';
      return msg;
    }

    if(nom.length < 3) {
      msg = 'Sé más específico en el nombre oficial por favor.';
      return msg;
    }

    final partes = nom.split(' ');
    for (var i = 0; i < partes.length; i++) {
      nom = partes[i].trim();
      final hasConjuncion = _globals.conjunciones.contains(nom);
      if(nom.endsWith('S') || hasConjuncion) {
        msg = '[!] En lo posible, trata de colocar las palabras en SINGULAR '
        'y evitar el uso de CONJUNCIONES si la palabra lo permite.\n ¿Deseas '
        'continuar guardando el nombre $nom sin editar?';
        return msg;
      }
    }

    if(_pzaSelAldo.value['id'] == '000' || _pzaSelRadec.value['id'] == '000') {
      msg = '[!] Se Guardará una palabra oficial en AutoparNet sin los datos '
      'de completos de los Crawler, ¿Estás segur@ de continuar?';
      return msg;
    }

    return msg;
  }

  ///
  void _resetScreen() {

    _dataAldo = {};
    _dataRadec= {};
    _pzaSelAldo.value = {};
    _pzaSelRadec.value = {};
    _resultsA.value = [];
    _resultsR.value = [];
    _results.value = [];
    _lstPzaAldoFil.value = List<Map<String, dynamic>>.from(_lstPzaAldo);
    _lstPzaRadecFil.value = List<Map<String, dynamic>>.from(_lstPzaRadec);
    _lstPzaAnetFil.value = List<Map<String, dynamic>>.from(_lstPzaAnet);
    _ctrF.text = '';
    _ctrT.text = '';
    _fco.requestFocus();
    _isExtract = false;
    _isForSearch = true;
    _idEdit = '0';
    setState(() {});
  }

  ///
  Future<void> _editPiezaOficial(int idPza) async {

    var idInd = _lstPzaAnet.indexWhere((element) => element['id'] == idPza);
    if(idInd != -1) {
      var tmp = List<Map<String, dynamic>>.from(_lstPzaAnet);
      _resetScreen();
      _idEdit = '$idPza';
      _ctrT.text = tmp[idInd]['value'].toString().substring(0, 4);
      _buscarPza(_ctrT.text);

      await Future.delayed(const Duration(milliseconds: 500));

      if(_lstPzaAldoFil.value.isNotEmpty) {
        if(tmp[idInd]['simyls'].containsKey('aldo')) {
          final ind = _lstPzaAldoFil.value.indexWhere(
            (element) => element['id'] == tmp[idInd]['simyls']['aldo']
          );
          if(ind != -1) {
            _pzaSelAldo.value = Map<String, dynamic>.from(_lstPzaAldoFil.value[ind]);
          }
        }
      }

      if(_lstPzaRadecFil.value.isNotEmpty) {
        if(tmp[idInd]['simyls'].containsKey('radec')) {
          final ind = _lstPzaRadecFil.value.indexWhere(
            (element) => element['id'] == tmp[idInd]['simyls']['radec']
          );
          if(ind != -1) {
            _pzaSelRadec.value = Map<String, dynamic>.from(_lstPzaRadecFil.value[ind]);
          }
        }
      }

      tmp = [];
    }
  }

  ///
  Future<void> _deletePiezaOficial(int idPza) async {

    bool delete = false;
    final idInd = _lstPzaAnet.indexWhere((element) => element['id'] == idPza);
    if(idInd != -1) {
      var tmp = List<Map<String, dynamic>>.from(_lstPzaAnet);
      if(tmp[idInd].containsKey('stt') && tmp[idInd]['stt'] == 0) {
        delete = true;
      }else{
        final msg = 'Se eliminará el nombre de la autoparte ${tmp[idInd]['value']} '
        'permanentemente de las Bases de Datos y Registros.\n¿Estás segur@ de continuar?.';

        bool? res = await WidgetsAndUtils.showAlert(
          context,
          titulo: 'BORRANDO AUTOPARTE OFICIAL', msg: msg,
          msgOnlyYes: 'Sí, Borrar', onlyAlert: false, withYesOrNot: true
        );
        delete = (res == null) ? false : res;
      }

      if(delete) {
        tmp.removeAt(idInd);
      }
      _lstPzaAnet = List<Map<String, dynamic>>.from(tmp);
      tmp = [];
      _resetScreen();
    }
  }

}