import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../my_tool_tip.dart';
import '../texto.dart';
import '../../../entity/orden_entity.dart';
import '../../../providers/centinela_provider.dart';
import '../../../repository/contacts_repository.dart';
import '../../../services/get_paths.dart';
import '../../../services/inventario_service.dart';
import '../../../vars/scroll_config.dart';

class LstProvPzas extends StatefulWidget {

  final int idOrden;
  const LstProvPzas({
    Key? key,
    required this.idOrden
  }) : super(key: key);

  @override
  State<LstProvPzas> createState() => _LstProvPzasState();
}

class _LstProvPzasState extends State<LstProvPzas> {

  final _scrollPr = ScrollController();
  final _scrollDt = ScrollController();
  final _scrollPz = ScrollController();
  final _scrollPzH = ScrollController();
  late CentinelaProvider _prov;

  bool _isInit = false;
  final _isLoading = ValueNotifier<bool>(false);
  final _showDataTime = ValueNotifier<bool>(false);
  final Map<String, Map<String, dynamic>> _tiempos = {};

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
    _showDataTime.dispose();
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
                _getDataCotz();
                return child!;
              }

              if(_prov.isUpdateCots) {
                _getDataCotz();
                return _body(cnst);
              }

              if(ctz.isNotEmpty && ctz.first.containsKey('noData')) {
                return SizedBox(
                  width: cnst.maxWidth, height: cnst.maxHeight,
                  child: const Center(
                    child: Texto(txt: 'No se recuperaron datos para esta Orden'),
                  ),
                );
              }

              if(ctz.isNotEmpty && ctz.first.containsKey('recovery')) {
                return _enEspera(msg: 'Recuperando datos de Cotizadores');
              }

              return (_prov.cotz.isEmpty)
                ? const SizedBox()
                : _body(cnst);
            },
            child: _enEspera(),
          ),
        );
      },
    );
  }

  ///
  Widget _body(BoxConstraints cnst) {

    return Column(
      children: [
        Expanded(
          child: _cotizAndPzas(cnst),
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
  }
  
  ///
  Widget _enEspera({String msg = ''}) {

    if(msg.isEmpty) {
      msg = 'En espera de Resultados';
    }
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
              Texto(txt: msg),
            ],
          ),
        ),
        const Spacer(),
        const Divider(height: 3, color: Colors.black)
      ],
    );
  }

  ///
  Widget _cotizAndPzas(BoxConstraints cnst) {

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
              primary: false,
              itemCount: _prov.cotz.length,
              itemBuilder: (_, ind) => _tileProv(ind)
            ),
          )
        ),
        Expanded(
          child: SizedBox.expand( child: _buildOfCubesPzas(cnst) )
        ),
      ],
    );
  }

  ///
  Widget _buildOfCubesPzas(BoxConstraints cnst) {

    final pzas = List<Map<String, dynamic>>.from(_prov.data['piezas']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
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
                        pzas.length, (index) {
                          return _columnaPzas(cnst, pzas[index]);
                        }
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
          child: _dataTimes(cnst)
        )
      ],
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
  Widget _tileProv(int indexCotz) {

    if(_prov.cotz[indexCotz].containsKey('refresh')) {
      return const SizedBox();
    }

    final iris = (_prov.data.containsKey(OrdCamp.iris.name))
      ? Map<String, dynamic>.from(_prov.data[OrdCamp.iris.name]) : <String, dynamic>{};

    final isSeeOrd = _prov.isSee(indexCotz, '${_prov.data['orden']['o_id']}', iris);

    bool isSee = (isSeeOrd.isNotEmpty) ? true : false;
    String empresa = _prov.cotz[indexCotz]['e_nombre'];
    if(empresa.contains('AUTOPARTES')) {
      empresa = empresa.replaceAll('AUTOPARTES', '').trim();
    }
    String nombre = _prov.cotz[indexCotz]['c_nombre'];
    if(nombre.contains('AUTOPARTES')) {
      nombre = nombre.replaceAll('AUTOPARTES', '').trim();
    }

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
          Row(
            children: [
              Texto(txt: empresa),
              const Spacer(),
              Icon(
                Icons.done_all, size: 18,
                color: (isSee) ? Colors.blue : Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(width: 10)
            ],
          ),
          Row(
            children: [
              Texto(txt: nombre, sz: 11, txtC: Colors.white),
              const Spacer(),
              Texto(txt: 'ID: ${_prov.cotz[indexCotz]['c_id']}', sz: 12,
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

    return FutureBuilder<Map<String, dynamic>>(
      future: _hidratarTiempos(pza, indexCotz),
      builder: (_, AsyncSnapshot<Map<String, dynamic>> snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(snap.hasData) {
            return _tiemposWidget(pza, snap.data!);
          }
        }
        return const CircularProgressIndicator();
      },
    );
    
  }

  ///
  Widget _tiemposWidget(Map<String, dynamic> pza, Map<String, dynamic> times) {

    if(times.isEmpty) {
      times = {
        'upTxt':'----------', 'bg': Colors.grey.withOpacity(0.2), 'aten': <String, dynamic>{}
      };
    }
    
    return SizedBox(
      width: 75, height: 50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Texto(txt: times['upTxt'], sz: 12),
          const SizedBox(height: 3),
          Container(
            width: 74, height: 19,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: times['bg'],
            ),
            child: MyToolTip(
              msg: pza['piezaName'],
              child: Center(
                child: Row(
                  children: [
                    if(times['aten'].isNotEmpty && times['aten'].containsKey('clv'))
                      Icon(_getIconWhere(times['aten']['clv']), size: 15, color: Colors.black)
                    else
                      Icon(_getIconWhere('x'), size: 15, color: Colors.black),
                    Texto(
                      txt: ' ${pza['id']}',
                      isCenter: true, isBold: true, sz: 13,
                      txtC: Colors.black
                    )
                  ],
                ),
              )
            )
          )
        ],
      ),
    );
  }

  ///
  Widget _dataTimes(BoxConstraints cnst) {

    return Container(
      width: cnst.maxWidth * 0.25,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: ValueListenableBuilder(
        valueListenable: _showDataTime,
        builder: (_, val, __) {

          if(!val) {
            return const SizedBox.expand(
              child: Center(
                child: SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return _scrollConfig(
            controller: _scrollDt,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              controller: _scrollDt,
              primary: false,
              itemCount: _prov.cotz.length,
              itemBuilder: (_, ind) => _tileData(ind)
            )
          );
        }
      ),
    );
  }

  ///
  Widget _tileData(int indexCotz) {

    Widget? child;
    if(_tiempos.containsKey('${_prov.cotz[indexCotz]['c_id']}')) {
      if(_tiempos['${_prov.cotz[indexCotz]['c_id']}']!.isEmpty) {
        child = const SizedBox();
      }
    }else{
      child = const SizedBox();
    }

    if(child == null) {

      final where = _tiempos['${_prov.cotz[indexCotz]['c_id']}']!['clv'];
      final fecha = _tiempos['${_prov.cotz[indexCotz]['c_id']}']!['createdAt'];
      final aten = DateTime.parse(fecha);
      final tCreated = DateTime.parse(_prov.data['orden']['o_createdAt']);
      final diff = aten.difference(tCreated);

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

      final tmpC = _fechaFormat(fecha);
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Texto(txt: '[ATN]: $tmpC', sz: 13, txtC: const Color.fromARGB(255, 196, 196, 196)),
          const Spacer(),
          Texto(txt: '[HACE]: $tAtenAnet > $where', sz: 13, txtC: const Color.fromARGB(255, 160, 160, 160))
        ],
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: Colors.grey),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        )
      ),
      child: child,
    );
  }

  ///
  Widget _singleScroll(ScrollController ctr, Axis axis, Widget child) {

    return SingleChildScrollView(
      controller: ctr,
      physics: const BouncingScrollPhysics(),
      scrollDirection: axis,
      primary: false,
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

    return 
    '${_filCero('$h')}'
    ':${_filCero('${fech.minute}')} $suf  '
    '${_filCero('${fech.day}')}'
    '-${_filCero('${fech.month}')}'
    '-${fech.year}';
    
  }

  ///
  String _filCero(String txt) => txt.padLeft(2, '0');

  ///
  Future<Map<String, dynamic>> _hidratarTiempos(Map<String, dynamic> pza, int indexCotz) async {

    Map<String, dynamic> res = {
      'upTxt':'', 'bg': Colors.grey.withOpacity(0.2), 'aten': <String, dynamic>{}
    };

    final iris = (_prov.data.containsKey(OrdCamp.iris.name))
      ? Map<String, dynamic>.from(_prov.data[OrdCamp.iris.name]) : <String, dynamic>{};
    
    final idCot = _prov.cotz[indexCotz]['c_id'];
    var aten = <String, dynamic>{};

    // Buscamos primeramente si la pieza cuenta con RESPUESTA 
    if(res['upTxt'].isEmpty) {
      aten = await _prov.hasRsp(
        '$idCot', '${pza['id']}', '${_prov.data['orden']['o_id']}',
        Map<String, dynamic>.from(iris)
      );
      if(aten.isNotEmpty) {
        // Si no es vacio es por que se encontró en NO TENGO.
        res['bg'] = Colors.white;
        res['upTxt'] = InventarioService.toFormat('${aten['costo']}');
      }
    }

    if(res['upTxt'].isEmpty) {
      aten = await _prov.isNtg(
        '$idCot', '${pza['id']}', '${_prov.data['orden']['o_id']}',
        Map<String, dynamic>.from(iris)
      );
      if(aten.isNotEmpty) {
        // Si no es vacio es por que se encontró en NO TENGO.
        res['bg'] = Colors.grey.withOpacity(0.5);
        res['upTxt'] = 'NO TENGO';
      }
    }

    // Si no se encontro la pieza entre los NO TENGO, buscamos en los Apartados
    if(res['upTxt'].isEmpty) {

      aten = await _prov.isApr(
        '${_prov.cotz[indexCotz]['c_id']}', '${pza['id']}', '${_prov.data['orden']['o_id']}',
        Map<String, dynamic>.from(iris)
      );
      if(aten.isNotEmpty) {
        // Si no es vacio es por que se encontró en APARTADA.
        res['bg'] = Colors.grey;
        res['upTxt'] = 'APARTADA';
      } 
    }

    if(aten.isNotEmpty) {
      if(_tiempos.containsKey('${_prov.cotz[indexCotz]['c_id']}')) {
        _tiempos['${_prov.cotz[indexCotz]['c_id']}'] = aten;
      }else{
        _tiempos.putIfAbsent(
          '${_prov.cotz[indexCotz]['c_id']}', () => aten
        );
      }
    }else{
      res['upTxt'] = '----------';
    }
    
    if(aten.isNotEmpty) {
      res['aten'] = aten;
    }
    _showDataTime.value = true;
    return res;
  }

  ///
  Future<void> _getDataCotz() async {

    if(_isLoading.value){ return; }

    if(_prov.data.isNotEmpty) {

      _prov.isUpdateCots = false;
      _isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 250));
      
      final cotz = GetPaths.getCotzFromFileByIds(
        List<int>.from(_prov.data[OrdCamp.metrik.name]['sended'])
      );
      List<int> cotzRec = [];
      if(cotz.isNotEmpty) {
        for (var i = 0; i < cotz.length; i++) {
          if(cotz[i]['e_nombre'] == 'recovery') {
            cotzRec.add(cotz[i]['c_id']);
          }
        }
      }

      if(cotzRec.isEmpty) {
        _prov.cotz = List<Map<String, dynamic>>.from(cotz);
        cotz.clear();
      }else{

        Future.microtask(() => _prov.cotz = [{'recovery':''}]);
        await Future.delayed(const Duration(milliseconds: 250));
        final ctcEm = ContactsRepository();
        final resultado = await ctcEm.recoveryCotzSaveInLocal(cotzRec);
        
        if(resultado['isOk']) {
          cotz.addAll(resultado['cotz']);
          _prov.cotz = List<Map<String, dynamic>>.from(cotz);
          cotz.clear();
        }
      }

      Future.microtask(() { _isLoading.value = false; });

    }else{
      Future.microtask(() => _prov.cotz = [{'noData':''}]);
    }
  }

  ///
  IconData _getIconWhere(String clv) {

    switch (clv) {
      case 'APARTADA': return Icons.push_pin_outlined;
      case 'HOME': return Icons.home;
      case 'LINK': return Icons.link_rounded;
      case 'CARNADA': return Icons.first_page_rounded;
      default:
        return Icons.close;
    }
  }

}