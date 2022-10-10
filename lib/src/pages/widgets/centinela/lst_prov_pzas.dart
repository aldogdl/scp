import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/providers/invirt_provider.dart';

import '../../../services/inventario_service.dart';
import '../my_tool_tip.dart';
import '../texto.dart';
import '../../../providers/centinela_provider.dart';
import '../../../repository/centinela_metrix_repository.dart';
import '../../../repository/inventario_repository.dart';
import '../../../vars/scroll_config.dart';

class LstProvPzas extends StatefulWidget {

  const LstProvPzas({ Key? key}) : super(key: key);

  @override
  State<LstProvPzas> createState() => _LstProvPzasState();
}

class _LstProvPzasState extends State<LstProvPzas> {

  final _cenEm = CentinelaMetrixRepository();
  final _invEm = InventarioRepository();
  
  final _scrollPr = ScrollController();
  final _scrollDt = ScrollController();
  final _scrollPz = ScrollController();
  final _scrollPzH = ScrollController();
  late CentinelaProvider _prov;

  final _isLoading = ValueNotifier<bool>(false);
  bool _isInit = false;
  bool _getData = false;

  @override
  void initState() {
    _scrollPr.addListener(() {
      _scrollPz.position.jumpTo(_scrollPr.position.pixels);
      _scrollDt.position.jumpTo(_scrollPr.position.pixels);
    });
    _scrollPz.addListener(() {
      _scrollPr.position.jumpTo(_scrollPz.position.pixels);
      _scrollDt.position.jumpTo(_scrollPz.position.pixels);
    });
    _scrollDt.addListener(() {
      _scrollPr.position.jumpTo(_scrollDt.position.pixels);
      _scrollPz.position.jumpTo(_scrollDt.position.pixels);
    });
    super.initState();
  }

  @override
  void dispose() {

    _scrollPr.removeListener(() { });
    _scrollPz.removeListener(() { });
    _scrollDt.removeListener(() { });
    _scrollDt.dispose();
    _scrollPr.dispose();
    _scrollPz.dispose();
    _prov.tConsole.clear();
    _prov.cleanDataChartProv();
    _isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _prov = context.read<CentinelaProvider>();
    }

    return LayoutBuilder(
      builder: (_, cnst) {

        return Container(
          width: cnst.maxWidth, height: cnst.maxHeight,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 1))
          ),
          child: Selector<CentinelaProvider, List<Map<String, dynamic>>>(
            selector: (_, prov) => prov.cotz,
            builder: (_, ctz, child) {

              if(ctz.isNotEmpty && ctz.first.isEmpty) {
                if(!_getData) { _getDataCotz(); }
                return child!;
              }
              if(ctz.isNotEmpty && ctz.first.containsKey('noData')) {
                return SizedBox(
                  width: cnst.maxWidth, height: cnst.maxHeight,
                  child: const Center(
                    child: Texto(txt: 'No se recuperaron datos para esta Orden'),
                  ),
                );
              }

              return (_prov.cotz.isEmpty)
                ? const SizedBox()
                : Column(
                  children: [
                    Expanded(
                      child: _cotizadores(cnst),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _isLoading,
                      builder: (_, val, __) {
                        if(val) {
                          return SizedBox(
                            width: cnst.maxWidth, height: 2,
                            child: const LinearProgressIndicator(),
                          );
                        }
                        return const SizedBox();
                      }
                    )
                  ],
                );
            },
            child: _enEspera(),
          ),
        );
      },
    );
  }

  ///
  Widget _enEspera() {

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Spacer(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_sharp, size: 100, color: Colors.black.withOpacity(0.3)),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                height: 2,
                child: const LinearProgressIndicator(),
              ),
              const Texto(txt: 'En espera de Resultados'),
            ],
          ),
        ),
        const Spacer(),
        const Divider(height: 3, color: Colors.black)
      ],
    );
  }

  ///
  Widget _cotizadores(BoxConstraints cnst) {

    return Row(
      children: [
        Container(
          width: cnst.maxWidth * 0.25,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
          ),
          child: _scrollConfig(
            controller: _scrollPr,
            // La lista de Proveedores
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              controller: _scrollPr,
              itemCount: _prov.cotz.length,
              itemBuilder: (_, ind) => _tileProv(ind)
            ),
          )
        ),
        Expanded(
          child: SizedBox.expand( child: _buildList(cnst) )
        ),
      ],
    );
  }

  ///
  Widget _buildList(BoxConstraints cnst) {

    final pzas = List<Map<String, dynamic>>.from(_prov.data['piezas']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _scrollConfig(
            controller: _scrollPzH,
            child: _singleScroll(
              _scrollPzH, Axis.horizontal,
              _scrollConfig(
                controller: _scrollPz,
                child: _singleScroll(
                  _scrollPz, Axis.vertical,
                  SizedBox(
                    width: cnst.maxWidth - ((cnst.maxWidth * 0.275)*2),
                    child: Row(
                      children: List.generate(
                        pzas.length, (index) => _columnaPzas(cnst, pzas[index])
                      )
                    ),
                  )
                )
              )
            )
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            width: cnst.maxWidth * 0.25,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
            ),
            child: _scrollConfig(
              controller: _scrollDt,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                controller: _scrollDt,
                itemCount: _prov.cotz.length,
                itemBuilder: (_, ind) => _tileData(ind)
              ),
            ),
          )
        )
      ],
    );
  }

  ///
  Widget _singleScroll(ScrollController ctr, Axis axis, Widget child) {

    return SingleChildScrollView(
      controller: ctr,
      physics: const BouncingScrollPhysics(),
      scrollDirection: axis,
      child: child
    );
  }

  /// 
  Widget _scrollConfig({required ScrollController controller, required Widget child}) {

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: ScrollConfiguration(
        behavior: MyCustomScrollBehavior(),
        child: child
      )
    );
  }

  ///
  Widget _columnaPzas(BoxConstraints cnst, Map<String, dynamic> pza) {

    return Column(
      children: List.generate(_prov.cotz.length, (index) {
        
        return Container(
          height: 50,
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
            )
          ),
          child: _tilePiza(pza, index),
        );
      })
    );
  }

  ///
  Widget _tileProv(int idx) {

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          right: const BorderSide(color: Colors.grey),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Texto(txt: _prov.cotz[idx]['empresa']),
          Row(
            children: [
              Texto(txt: _prov.cotz[idx]['contact'], sz: 11, txtC: Colors.white),
              const Spacer(),
              Texto(txt: 'ID: ${_prov.cotz[idx]['id']}', sz: 12,
                txtC: const Color.fromARGB(255, 87, 87, 87)
              ),
              const SizedBox(width: 8)
            ],
          ),
        ],
      ),
    );
  }
  
  ///
  Widget _tilePiza(Map<String, dynamic> pza, int indexCotz) {

    String upTxt = '----------';
    Color bg = Colors.grey.withOpacity(0.5);
    final idCot = _prov.cotz[indexCotz]['id'];

    if(_prov.noTengo.isNotEmpty) {
      if(_prov.noTengo.containsKey('$idCot')) {
        final pzas = List<String>.from(_prov.noTengo['$idCot']!);
        if(pzas.contains('${pza['id']}')) {
          bg = Colors.grey;
          upTxt = 'No Tengo';
        }
      }
    }

    if(_prov.resps.isNotEmpty) {
      final hasResp = _prov.resps.firstWhere(
        (r) => (r['c_id'] == idCot && r['p_id'] == pza['id']), orElse: () => {}
      );
      if(hasResp.isNotEmpty) {
        bg = Colors.white;
        upTxt = InventarioService.toFormat('${hasResp['r_costo']}');
      }
    }

    return SizedBox(
      width: 75, height: 50,
      child: Column(
        children: [
          Texto(txt: upTxt, sz: 12),
          const SizedBox(height: 3),
          Container(
            width: 74, height: 19,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: bg,
            ),
            child: MyToolTip(
              msg: pza['piezaName'],
              child: Center(
                child: Texto(
                  txt: 'ID: ${pza['id']}',
                  isCenter: true, isBold: true, sz: 13,
                  txtC: Colors.black
                ),
              )
            )
          )
        ],
      ),
    );
  }

  ///
  Widget _tileData(int idx) {

    final tSol = DateTime.parse(_prov.data['orden']['o_createdAt']);
    final tCreated = DateTime.parse(_prov.cotz[idx]['created']);
    final diff = tCreated.difference(tSol);

    var tAtenAnet = '0';
    if(diff.inDays == 0) {
      if(diff.inMinutes > 60) {
        tAtenAnet = '${diff.inHours.remainder(60)}:${diff.inMinutes.remainder(60)} Min.';
      }else{
        tAtenAnet = '${diff.inMinutes.remainder(60)} Minutos';
      }
    }else{
      tAtenAnet = '${diff.inDays} Días';
    }

    final tmpC = _fechaFormat(tSol.toIso8601String());

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: Colors.grey),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _getWidgetSegunStt(_prov.cotz[idx]),
          MyToolTip(
            msg: 'Solicitado: $tmpC',
            child: Texto(txt: 'Atención [Anet]: $tAtenAnet', sz: 11, txtC: Colors.white)
          )
        ],
      ),
    );
  }

  ///
  Widget _getWidgetSegunStt(Map<String, dynamic> met) {

    String val1 = '';
    String val2 = '';
    String tip = '';
    switch (met['stt_clv']) {
      case 'i':
        val1 = 'Msg: ${met['stt_txt']}';

        final created = DateTime.parse(met['created']);
        final hoy = DateTime.now();
        tip = 'Sol: ${_fechaFormat(created.toIso8601String())} - Hoy: ${ _fechaFormat(hoy.toIso8601String()) }';
        val2 = 'Hace: ${_getTime(hoy.difference(created))}';
        break;
      case 'a':

        val1 = 'Msg: ${met['stt_txt']}';
        final tSended = DateTime.parse(met['envi']);
        final tAten = DateTime.parse(met['aten']);
        tip = 'Env: ${_fechaFormat(tSended.toIso8601String())} - Aten: ${ _fechaFormat(tAten.toIso8601String()) }';
        val2 = 'Trans: ${ _getTime(tAten.difference(tSended)) }';
        break;
      case 'r':
        val1 = 'Msg: ${met['stt_txt']}';
        val2 = 'Trans: 8 mins.';
        break;
      default:
    }

    return Row(
      children: [
        Texto(txt: val1, txtC: _getColor(met['stt_clv'])),
        const Spacer(),
        MyToolTip(
          msg: tip,
          child: Texto(txt: val2, txtC: Colors.grey, sz: 12),
        )
      ],
    );
  }

  ///
  String _fechaFormat(String fecha, {bool onlyTime = false}) {

    final fech = DateTime.parse(fecha);
    String suf = 'am';
    int h = fech.hour;
    if(h > 12) {
      suf = 'pm';
      if(h > 19) {
        if(h > 20) {
          switch (h) {
            case 21: h = 9; break;
            case 22: h = 10; break;
            case 23: h = 11; break;
          }
        }else{
          h = 8;
        }
      }else{
        h = (h-10) -2;
      }
    }

    if(onlyTime) {
      return '${_filCero('$h')}'
      ':${_filCero('${fech.minute}')} $suf';
    }

    return '${_filCero('${fech.day}')}'
    '-${_filCero('${fech.month}')}'
    '-${fech.year} '
    '${_filCero('$h')}'
    ':${_filCero('${fech.minute}')} $suf';
    
  }

  ///
  String _getTime(Duration trans) {

    if(trans.inDays > 0) {
      return '${trans.inDays} días.';
    }
    final h = trans.inHours.remainder(60);
    final m = trans.inMinutes.remainder(60);
    if(h > 0) {
      return '$h:$m Mins.';
    }
    return '$m Mins.';
  }

  ///
  String _filCero(String txt) => txt.padLeft(2, '0');

  ///
  Future<void> _getDataCotz() async {

    String msgsTask = '';

    if(_prov.data.isNotEmpty) {

      Future.microtask(() {
        _prov.addConsole('[>] Recuperando Cotizadores');
        _isLoading.value = true;
      });

      String query = '${_prov.idOrdenCurrent}-orden';

      if(_prov.data.containsKey('campaings')) {
        final camp = List<Map<String, dynamic>>.from(_prov.data['campaings']);
        if(camp.first.containsKey('fileCamp')) {
          if('${camp.first['orden']}' == '${_prov.idOrdenCurrent}') {
            query = camp.first['fileCamp'];
          }
        }
      }

      if(_prov.data.containsKey('centinela')) {
        Future.microtask(() {
          _prov.addConsole('[>] Desde Sistema de Archivos');
        });
        _prov.noTengo = Map<String, dynamic>.from(_prov.data['centinela']['notengo']);
        _prov.resps = List<Map<String, dynamic>>.from(_prov.data['centinela']['resps']);
        Future.microtask(() {
          _prov.cotz = List<Map<String, dynamic>>.from(_prov.data['centinela']['metrix']);
          _prov.buildChartProv();
        });
        msgsTask = '[>] Actualizando DATOS';
      }else{
        msgsTask = '[>] Buscando: $query';
      }

      Future.microtask(() => _prov.addConsole(msgsTask));

      await _cenEm.getCotizadores(query);
      msgsTask = '[√] Cotizadores Recuperados';

      if(_cenEm.result['abort']) {
        Future.microtask(() {
          _prov.addConsole('[X] Sin Datos, inténtalo nuevamente');
        });
        return;
      }

      Future.microtask(() => _prov.addConsole(msgsTask));
      
      _prov.noTengo = Map<String, dynamic>.from(_cenEm.result['body']['notengo']);
      _prov.resps = [];
      if(_cenEm.result['body'].containsKey('resps')) {
        _prov.resps = List<Map<String, dynamic>>.from(_cenEm.result['body']['resps']);
      }
      _prov.cotz = List<Map<String, dynamic>>.from(_cenEm.result['body']['metrix']);
      
      final res = await _invEm.updateDataCentinela(_cenEm.result['body'], _prov.data['filename']);
      
      if(res['newData'].isNotEmpty) {
        _prov.data = res['newData'];
      }

      _getData = true;
      _cenEm.clear();
      _prov.buildChartProv();
      if(_isLoading.value) {
        _isLoading.value = false;
      }
      
      if(res['metrix']) {
        Future.microtask(() {
          _prov.refreshSeccMetrix = !_prov.refreshSeccMetrix;
          context.read<InvirtProvider>().cmd = {'cmd': 'cc'};
        });
      }

    }else{
      Future.microtask(() => _prov.cotz = [{'noData':''}]);
    }
  }

  ///
  Color _getColor(String clv) {

    switch (clv) {
      case 'i': return Colors.grey.withOpacity(0.5);
      case 'a': return Colors.green;
      case 'p': return Colors.red;
      case 'r': return Colors.blue;
      default:
        return Colors.white;
    }
  }
}