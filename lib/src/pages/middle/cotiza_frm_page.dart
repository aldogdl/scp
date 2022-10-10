import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/frm_cotiza/badgets_coiza.dart';
import '../widgets/frm_cotiza/marcas_lst.dart';
import '../widgets/frm_cotiza/modelos_lst.dart';
import '../widgets/frm_cotiza/tile_item_list.dart';
import '../widgets/my_tool_tip.dart';
import '../widgets/orden_tile.dart';
import '../widgets/texto.dart';
import '../../config/sng_manager.dart';
import '../../entity/modelos_entity.dart';
import '../../entity/marcas_entity.dart';
import '../../entity/orden_entity.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/cotiza_provider.dart';
import '../../repository/ordenes_repository.dart';
import '../../services/status/est_stt.dart';
import '../../vars/globals.dart';


class CotizaFrmPage extends StatefulWidget {

  final String from;
  const CotizaFrmPage({
    Key? key,
    this.from = 'cotiza'
  }) : super(key: key);

  @override
  State<CotizaFrmPage> createState() => _CotizaFrmPageState();
}

class _CotizaFrmPageState extends State<CotizaFrmPage> {

  final _sctr = ScrollController();
  final _ctrT = TextEditingController();
  final _fco = FocusNode();
  final _globals = getSngOf<Globals>();
  final _msgFiel = ValueNotifier<String>('Busca el elemento deseado.');

  PiezasEntity _pieza = PiezasEntity();
  late CotizaProvider _ctzP;
  int _cantPzas = 0;
  bool _isInit = false;
  List<String> _itemsFilter = [];

  @override
  void initState() {
    _makeToken();
    super.initState();
  }

  @override
  void dispose() {
    _ctrT.dispose();
    _sctr.dispose();
    _fco.dispose();
    _msgFiel.dispose();
    _ctzP.myDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        if(widget.from == 'cotiza')
          ...[
            OrdenTile(orden: _ctzP.orden, cantPzas: _cantPzas),
            Row(
              children: [
                BadgetsCotiza(
                  tipo: 'taps',
                  onTap: (_) => setState(() {}),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Selector<CotizaProvider, String>(
                    selector: (_, prov) => prov.tokenServer,
                    builder: (_, t, child) {

                      return MyToolTip(
                        msg:  (t.isNotEmpty) ? 'Token Activo al Servidor' : 'Token Desactualizado',
                        child: (t.isNotEmpty)
                          ? child!
                          : InkWell(
                            onTap: () => _makeToken(),
                            child: const Icon(Icons.lock_reset, color: Colors.red, size: 18),
                          )
                      );
                    },
                    child: const Icon(Icons.lock, color: Colors.blue, size: 18),
                  ),
                )
              ],
            ),
          ],
        Selector<CotizaProvider, String>(
          selector: (_, prov) => prov.isOrdFinish,
          builder: (_, val, __) {
            if(val == 'fin') {
              Future.delayed(const Duration(milliseconds: 250), (){
                _resetScreen();
              });
            }
            return const SizedBox(height: 8);
          },
        ),
        Container(
          padding: const EdgeInsets.only(right: 15, left: 8),
          height: 40,
          child: _searchItemField(),
        ),
        const SizedBox(height: 3),
        ValueListenableBuilder<String>(
          valueListenable: _msgFiel,
          builder: (_, val, __) {

            return Texto(
              txt: val,
              txtC: (!val.startsWith('[X]')) ? Colors.grey : Colors.amber,
              sz: 13
            );
          }
        ),
        const SizedBox(height: 10),
        const Divider(),
        Selector<CotizaProvider, String>(
          selector: (_, prov) => prov.taps,
          builder: (_, tap, __) {

            if(tap.startsWith('switch')) {
              Future.microtask((){
                _makeSwitch();
              });
            }

            if(tap == 'auto') {
              return BadgetsCotiza(
                tipo: 'auto',
                onTap: (_) {
                  _ctrT.text = '';
                  if(_ctzP.seccion == 'origenCar') {
                    _ctrT.text = '${_globals.origenCar.first}.1';
                  }
                  _fco.requestFocus();
                }
              );
            }

            return BadgetsCotiza(
              tipo: 'piezas',
              onTap: (_) {
                _ctrT.text = '';
                _itemsFilter = [];
                _fco.requestFocus();
                setState(() {});
              }
            );
          },
        ),
        const Divider(),
        Selector<CotizaProvider, String>(
          selector: (_, prov) => prov.seccion,
          builder: (_, secc, __) => _getSeccion(secc)
        )
      ],
    );
  }

  ///
  Widget _searchItemField() {

    return TextField(
      controller: _ctrT,
      focusNode: _fco,
      autofocus: true,
      onChanged: (String val) {
        context.read<CotizaProvider>().search = val.toUpperCase().trim();
      },
      onSubmitted: (v) => _tapInItem(v, 'field'),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
        enabledBorder: _border(),
        focusedBorder: _border(),
        hintText: _getHint(),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3)
        ),
        suffixIcon: InkWell(
          onTap: () => _tapInItem(_ctrT.text, 'field'),
          child: Icon(
            Icons.check,
            color: (_ctzP.idPzaEdit != 0) ? Colors.orange : const Color.fromARGB(255, 197, 197, 197),
          ),
        )
      ),
    );
  }

  ///
  Widget _getSeccion(String secc) {

    switch (secc) {
      case 'modelos':

        return ModelosLst(
          mrkSel: _ctzP.lMarcas.firstWhere(
            (m) => m.id == _ctzP.orden.mkId, orElse: () => MarcasEntity()
          ),
          onTap: (String item) {
            _ctrT.text = item;
            _tapInItem(item, 'onTap');
          }
        );
      case 'anios':
        return _lstAnios();
      case 'origenCar':
        return _lstOrigenAuto();
      case 'pieza':
        return _lstPiezas();
      case 'lado':
        return _lstLados();
      case 'posicion':
        return _lstPosiciones();
      case 'origin':
        return _lstOrigenPza();
      case 'detalles':
        return const SizedBox();
      default:
        return MarcasLst(
          onTap: (String item) {
            _ctrT.text = item;
            _tapInItem(item, 'onTap');
          }
        );
    }
  }

  ///
  Widget _baseLista(Widget child) {

    return Expanded(
      child: Scrollbar(
        controller: _sctr,
        thumbVisibility: true,
        radius: const Radius.circular(3),
        trackVisibility: true,
        child: child
      ),
    );
  }

  ///
  Widget _baseLstView(Function fnc) {

    return ListView.builder(
      controller: _sctr,
      itemCount: _itemsFilter.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      itemBuilder: (_, index) => fnc(_, index),
    );
  }

  ///
  Widget _lstAnios() {

    final anios = buildAnios();

    return _baseLista(
      Selector<CotizaProvider, String>(
        selector: (_, prov) => prov.search,
        builder: (_, busk, __) {

          _itemsFilter = anios.where((element) => element.contains(busk)).toList();
          return _baseLstView( (_, index) => TileItemList(
              ico: Icons.calendar_month,
              item: _itemsFilter[index],
              onTap: (item) => _tapInItem(item, 'onTap'),
            )
          );
        },
      )
    );
  }

  ///
  Widget _lstOrigenAuto() {

    return _baseLista(
      Selector<CotizaProvider, String>(
        selector: (_, prov) => prov.search,
        builder: (_, busk, __) {

          if(_globals.origenCar.length > 10) {
            if(!busk.contains('.')) {
              _itemsFilter = _globals.origenCar.where((element) => element.contains(busk)).toList();
            }
          }else{
            if(_itemsFilter.isEmpty) {
              _itemsFilter = _globals.origenCar.where((element) => element.contains(busk)).toList();
            }
          }

          return _baseLstView( (_, index) => TileItemList(
              ico: Icons.directions_car_filled_outlined,
              item: '.${index + 1} ${_itemsFilter[index]}',
              onTap: (item) => _tapInItem(item, 'onTap'),
            )
          );
        },
      )
    );
  }

  ///
  Widget _lstPiezas() {

    return _baseLista(
      Selector<CotizaProvider, String>(
        selector: (_, prov) => prov.search,
        builder: (_, busk, __) {

          _itemsFilter = [];
          return _baseLstView( (_, index) => TileItemList(
              ico: Icons.extension,
              item: '.${index + 1} ${_itemsFilter[index]}',
              onTap: (item) => _tapInItem(item, 'onTap'),
            )
          );
        },
      )
    );
  }
  
  ///
  Widget _lstLados() {

    return _baseLista(
      Selector<CotizaProvider, String>(
        selector: (_, prov) => prov.search,
        builder: (_, busk, __) {

          if(_globals.lugar.length > 10) {
            if(!busk.contains('.')) {
              _itemsFilter = _globals.lugar.where((element) => element.contains(busk)).toList();
            }
          }else{
            if(_itemsFilter.isEmpty) {
              _itemsFilter = _globals.lugar.where((element) => element.contains(busk)).toList();
            }
          }

          return _baseLstView( (_, index) => TileItemList(
              ico: Icons.signpost_rounded,
              item: '.${index + 1} ${_itemsFilter[index]}',
              onTap: (item) => _tapInItem(item, 'onTap'),
            )
          );
        },
      )
    );
  }
  
  ///
  Widget _lstPosiciones() {

    return _baseLista(
      Selector<CotizaProvider, String>(
        selector: (_, prov) => prov.search,
        builder: (_, busk, __) {

          if(_globals.posic.length > 10) {
            if(!busk.contains('.')) {
              _itemsFilter = _globals.posic.where((element) => element.contains(busk)).toList();
            }
          }else{
            if(_itemsFilter.isEmpty) {
              _itemsFilter = _globals.posic.where((element) => element.contains(busk)).toList();
            }
          }
          return _baseLstView( (_, index) => TileItemList(
              ico: Icons.signpost_rounded,
              item: '.${index + 1} ${_itemsFilter[index]}',
              onTap: (item) => _tapInItem(item, 'onTap'),
            )
          );
        },
      )
    );
  }
  
  ///
  Widget _lstOrigenPza() {

    return _baseLista(
      Selector<CotizaProvider, String>(
        selector: (_, prov) => prov.search,
        builder: (_, busk, __) {

          if(_globals.origenes.length > 10) {
            if(!busk.contains('.')) {
              _itemsFilter = _globals.origenes.where((element) => element.contains(busk)).toList();
            }
          }else{
            if(_itemsFilter.isEmpty) {
              _itemsFilter = _globals.origenes.where((element) => element.contains(busk)).toList();
            }
          }
          return _baseLstView( (_, index) => TileItemList(
              ico: Icons.extension,
              item: '.${index + 1} ${_itemsFilter[index]}',
              onTap: (item) => _tapInItem(item, 'onTap'),
            )
          );
        },
      )
    );
  }

  ///
  String _getHint() {

    switch (_ctzP.seccion) {
      case 'modelos':
        return '¿Qué Modelos es? ...';
      case 'anios':
        return 'Escribe el Año...';
      case 'pieza':
        return 'Escribe la Pieza';
      case 'lado':
        return '¿Qué Lado es? ...';
      case 'posicion':
        return 'Selecciona la Posición';
      case 'origin':
        return 'Orígen de la Pieza';
      case 'detalles':
        return '¿Algunos Requerimientos extras?';
      default:
        return 'Busca la Marca';
    }
  }

  ///
  OutlineInputBorder _border() {

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey)
    );
  }

  ///
  List<String> buildAnios() {

    List<String> lst = [];
    int init = DateTime.now().year;
    for (var i = 1930; i < init; i++) {
      lst.add('$i');
    }
    lst = lst.reversed.toList();
    return lst;
  }

  ///
  void _makeToken() async {

    if(!_isInit) {
      _isInit = true;
      _ctzP = context.read<CotizaProvider>();
    }
    
    final em = OrdenesRepository();
    if(_ctzP.tokenServer.isEmpty) {
      final token = await em.getTokenServer({
        'username': _globals.user.curc, 'password': _globals.user.password 
      });
      if(token.isNotEmpty) {
        _ctzP.tokenServer = token;
      }
    }
  }

  /// Esta accion solo se procesa desde la caja de texto de la búsqueda, es
  /// decir, aqui no llegamos si los items de la lista se hacen click.
  void _tapInItem(String item, String from) {

    _msgFiel.value = 'Busca el elemento deseado.';
    item = item.toUpperCase().trim();

    if(item.isEmpty && _itemsFilter.isNotEmpty) {
      item = _itemsFilter.first;
    }

    switch (_ctzP.seccion) {

      case 'marcas':

        if(item.isEmpty) {
          if(_ctzP.lMarcas.isEmpty) { return; }
          _ctrT.text = '${_ctzP.lMarcas.first.marca}.1';
        }else{
          if(from == 'onTap') {
            final partes = item.split('.');
            final index = _ctzP.lMarcas.indexWhere((m) => m.marca == partes.first);
            if(index != -1) {
              _ctrT.text = '${partes.first}.${index+1}';
            }
          }else{
            _buildCriterio(item);
          }
        }
        break;

      case 'modelos':

        if(item.isEmpty) {
          _ctrT.text = '${_ctzP.lModelos.first.modelo}.1';
        }else{
          if(from == 'onTap') {
            final partes = item.split('.');
            final index = _ctzP.lModelos.indexWhere((m) => m.modelo == partes.first);
            if(index != -1) {
              _ctrT.text = '${partes.first}.${index+1}';
            }
          }else{
            _buildCriterio(item);
          }
        }
        break;

      case 'origenCar':

        final partes = item.split(' ');
        if(from == 'onTap') {
          final index = _globals.origenCar.indexWhere((or) => or == partes.last.trim());
          if(index != -1) {
            item = '${partes.last.trim()}.${index+1}';
          }
        }else{
          item = '${partes.last.trim()}.${partes.first.trim()}';
        }
        _ctrT.text = item;
        break;

      case 'anios':

        if(item.length < 4) {
          if(_itemsFilter.length > 1) {
            _msgFiel.value = '[X] El Año no es valido';
            _ctrT.selection = TextSelection(baseOffset: 0, extentOffset: _ctrT.text.length);
            _fco.requestFocus();
            return;
          }else{
            item = _itemsFilter.first;
          }
        }
        _ctrT.text = '.$item';
        _itemsFilter = [item];
        break;

      case 'pieza':

        if(item.isEmpty) {
          _msgFiel.value = '[X] Debes colocar una pieza';
          _fco.requestFocus();
          return;
        }
        _ctrT.text = '.$item';
        break;

      case 'lado':
        
        if(item.isEmpty) {
          item = _globals.lugar.first;
        }
        
        if(item.startsWith('.')) {
          if(from == 'onTap') {
            final partes = item.split(' ');
            item = partes.last.trim();
          }else{
            final partes = item.split('.');
            int? index = int.tryParse(partes.last);
            if(index != null) {
              item = _globals.lugar[index-1];
            }
          }
        }
        _ctrT.text = '.$item'.toUpperCase().trim();
        break;

      case 'posicion':

        if(item.isEmpty) {
          item = _globals.posic.first;
        }
        
        if(item.startsWith('.')) {
          if(from == 'onTap') {
            final partes = item.split(' ');
            item = partes.last.trim();
          }else{
            final partes = item.split('.');
            int? index = int.tryParse(partes.last);
            if(index != null) {
              item = _globals.posic[index-1];
            }
          }
        }
        _ctrT.text = '.$item'.toUpperCase().trim();
        break;

      case 'origin':

        if(item.isEmpty) {
          item = _globals.origenes.first;
        }
        
        if(item.startsWith('.')) {
          if(from == 'onTap') {
            final partes = item.split(RegExp(r'\d'));
            item = partes.last.trim();
          }else{
            final partes = item.split('.');
            int? index = int.tryParse(partes.last);
            if(index != null) {
              item = _globals.origenes[index-1];
            }
          }
        }
        _ctrT.text = '.$item'.toUpperCase().trim();
        break;

      case 'detalles':

        if(item.isEmpty) {
          item = 'Sin detalles';
        }
        _ctrT.text = '.$item'.toUpperCase().trim();
        break;
      default:
    }    

    _selectItem();
  }

  ///
  void _buildCriterio(String item) {

    List<dynamic> lst = [];
    String ofBy = '';
    const String seccMain = 'marcas';

    if(_ctzP.seccion == seccMain) {
      ofBy= 'La Marca ';
      lst = _ctzP.lMarcas;
    } else {
      ofBy= 'El Modelos ';
      lst = _ctzP.lModelos;
    }
  
    // Si no comienza con un punto, significa que busco la marca requerida
    if(!item.startsWith('.')) {

      // Si contiene un punto, es que me estan pidiendo algo especifico
      if(item.contains('.')) {

        final partes = item.split('.');
        int? indTmp = int.tryParse(partes.last);
        if(indTmp != null) {

          indTmp = indTmp -1;
          final op = lst.where(
            (m) {
              return (_ctzP.seccion == seccMain)
                ? m.marca.contains(partes.first)
                : m.modelo.contains(partes.first);
            }
          ).toList();

          if(op.isEmpty) {
            _ctrT.selection = TextSelection(baseOffset: 0, extentOffset: item.length);
            _fco.requestFocus();
            _msgFiel.value = '[X] $ofBy no se encontró';
            return;
          }

          int idM = 0;
          try {
            idM = op[indTmp].id;
          } catch (_) {
            _ctrT.selection = TextSelection(baseOffset: 0, extentOffset: item.length);
            _fco.requestFocus();
            _msgFiel.value = '[X] $ofBy no se encontró';
            return;
          }

          final index = lst.indexWhere((m) => m.id == idM);
          if(index != -1) {
            final prefix = (_ctzP.seccion == seccMain) ? op[indTmp].marca : op[indTmp].modelo;
            _ctrT.text = '$prefix.${index+1}';
          }

        } else {
          _ctrT.selection = TextSelection(baseOffset: 0, extentOffset: item.length);
          _fco.requestFocus();
          _msgFiel.value = '[X] $ofBy es invalida';
          return;
        }

      }else{

        // Hay algo en el item de busqueda pero ...
        //-- Saber si escribio la marca completa
        int index = lst.indexWhere((m) {
          return (_ctzP.seccion == seccMain) ? m.marca == item : m.modelo == item;
        });
        if(index != -1) {
          _ctrT.text = '$item.${index+1}';
        }else{
          //-- Saber si escribio solo unas letras y entre los resultados
          //   es la primer opcion
          final op = lst.where((m) {

            return (_ctzP.seccion == seccMain)
              ? m.marca.contains(item)
              : m.modelo.contains(item);
          }).toList();

          if(op.isEmpty) {
            return;
          }

          index = lst.indexWhere((m) => m.id == op.first.id);
          final prefix = (_ctzP.seccion == seccMain) ? op.first.marca : op.first.modelo;
          _ctrT.text = '$prefix.${index+1}';
        }
      }
    }
  }

  /// Cada ves que se lecciona una marca, modelos, año etc. llegamos aqui.
  void _selectItem() async {
    
    _msgFiel.value = '';
    final partes = _ctrT.text.trim().split('.');
    int? indexItem = int.tryParse(partes.last);
    if(indexItem == null && _ctzP.taps == 'piezas') {
      indexItem = -1;
    }

    if(indexItem != null) {
      
      switch (_ctzP.seccion) {
        case 'marcas':
          MarcasEntity? itemSelec;
          _ctzP.orden.uId = _globals.user.id;
          try {
            itemSelec = _ctzP.lMarcas[indexItem-1];
            setState(() {
              _ctzP.orden.marca = itemSelec!.marca;
              _ctzP.orden.mkId = itemSelec.id;
            });
            _ctzP.seccion = 'modelos';
          } catch(_) {
            return;
          }

          break;
        case 'modelos':
          
          ModelosEntity? itemSelec;
          try {
            itemSelec = _ctzP.lModelos[indexItem-1];
            setState(() {
              _ctzP.orden.modelo = itemSelec!.modelo;
              _ctzP.orden.mdId = itemSelec.id;
            });
            _ctzP.seccion = 'anios';
          }catch(_) {
            return;
          }
          break;
        case 'anios':

          final itemSelec = int.tryParse(_itemsFilter.first);
          if(itemSelec != null) {
            setState(() {
              _ctzP.orden.anio = itemSelec;
            });
            _ctzP.seccion = 'origenCar';
          }else{
            return;
          }
          break;
        case 'origenCar':

          String? itemSelec;
          try {
            itemSelec = _globals.origenCar[indexItem-1];
            EstStt.init();
            _ctzP.orden.est = '1';
            _ctzP.orden.stt = '1';
            setState(() {
              _ctzP.orden.isNac = (itemSelec == 'NACIONAL') ? true : false;
            });
            _ctzP.taps = 'piezas';
            _ctzP.seccion = 'pieza';
          }catch(_) {
            return;
          }
          break;
        case 'pieza':
          
          if(_ctzP.idPzaEdit != 0) {
            _editPiezaCurrent('pieza', partes.last);
            return;
          }

          if(_pieza.id == 0) {
            _pieza.id = DateTime.now().millisecondsSinceEpoch;
          }
          _pieza.piezaName = partes.last;
          _pieza.est = _ctzP.orden.est;
          _pieza.stt = _ctzP.orden.stt;
          _ctzP.seccion = 'lado';
          setState(() {});
          break;
        case 'lado':
          if(_ctzP.idPzaEdit != 0) {
            _editPiezaCurrent('lado', partes.last);
            return;
          }
          _pieza.lado = partes.last;
          _ctzP.seccion = 'posicion';
          setState(() {});
          break;
        case 'posicion':
          if(_ctzP.idPzaEdit != 0) {
            _editPiezaCurrent('posicion', partes.last);
            return;
          }
          _pieza.posicion = partes.last;
          _ctzP.seccion = 'origin';
          setState(() {});
          break;
        case 'origin':
          if(_ctzP.idPzaEdit != 0) {
            _editPiezaCurrent('origin', partes.last);
            return;
          }
          _pieza.origen = partes.last;
          _ctzP.seccion = 'detalles';
          setState(() {});
          break;
        case 'detalles':
          if(_ctzP.idPzaEdit != 0) {
            _editPiezaCurrent('detalles', partes.last);
            return;
          }
          _pieza.obs = partes.last;
          _ctzP.piezas.add(_pieza);
          _buildNewPza();
          _fco.requestFocus();
          return;
        default:
      }

      if(_ctzP.seccion == 'origenCar') {
        // Como solo son dos opciones y aparte lo mas usual es que sea de origen
        // nacional, es por eso que colocamos dicha opcion ya en la caja de texto
        _ctrT.text = '${_globals.origenCar.first}.1';
        _ctrT.selection = TextSelection(baseOffset: 0, extentOffset: _ctrT.text.length);
      }else{
        _ctrT.text = '';
      }

      _itemsFilter.clear();
      _ctzP.search = '';
      _fco.requestFocus();

    }
  }

  ///
  void _editPiezaCurrent(String campo, String value) {

    PiezasEntity? tmp;
    if(_ctzP.indexPzaCurren != -1) {
      tmp = _ctzP.piezas[_ctzP.indexPzaCurren];
      if(tmp.id == _ctzP.idPzaEdit) {
        tmp = _changeValuePza(campo, value, tmp);
        _ctzP.piezas[_ctzP.indexPzaCurren] = tmp;
      }else{
        tmp = null;
      }
    }

    if(tmp == null || tmp.id == 0) {
      final indx = _ctzP.piezas.indexWhere((pi) => pi.id == _ctzP.idPzaEdit);

      if(indx != -1) {
        tmp = _ctzP.piezas[indx];
        if(tmp.id == _ctzP.idPzaEdit) {
          tmp = _changeValuePza(campo, value, tmp);
          _ctzP.piezas[indx] = tmp;
        }
      }
    }

    tmp = null;
    _buildNewPza(forceRefres: true);
  }

  ///
  PiezasEntity _changeValuePza(String campo, String value, PiezasEntity pza) {

    switch (campo) {
      case 'pieza':
        pza.piezaName = value;
        break;
      case 'lado':
        pza.lado = value;
        break;
      case 'posicion':
        pza.posicion = value;
        break;
      case 'origin':
        pza.origen = value;
        break;
      case 'detalles':
        pza.obs = value;
        break;
      default:
    }
    return pza;
  }

  ///
  void _buildNewPza({bool refresh = true, bool forceRefres = false}) {

    _pieza = PiezasEntity();
    _pieza.id = DateTime.now().millisecondsSinceEpoch;
    _cantPzas = _ctzP.piezas.length;
    _ctzP.indexPzaCurren = (_ctzP.piezas.isEmpty) ? 0 : _ctzP.piezas.length -1;
    _ctzP.txtEdit = '';
    _ctzP.idPzaEdit = 0;
    _ctzP.fotoThubm = '';
    _ctrT.text = '';
    _itemsFilter = [];
    _ctzP.search = '';

    if(refresh) {
      _ctzP.seccion = 'pieza';
      if(forceRefres) {
        _ctzP.refreshLstPzasOrden = _ctzP.refreshLstPzasOrden + 1;
      }else{
        _ctzP.refreshLstPzasOrden = _cantPzas;
      }
      setState(() {});
    }
  }

  ///
  void _resetScreen() {

    _buildNewPza(refresh: false);
    _ctzP.taps = 'auto';
    _ctzP.seccion = 'marcas';
    _ctzP.orden = OrdenEntity();
    _ctzP.orden.uId = _globals.user.id; 
    _cantPzas = 0;
    _ctzP.piezas = [];
    _ctzP.isOrdFinish = 'clean';
    _ctzP.refreshLstPzasOrden = _cantPzas;
    setState(() {});
  }

  ///
  void _makeSwitch() {

    final partes = _ctzP.taps.split(':');
    final accSec = partes.last;

    Future.delayed(const Duration(microseconds: 250), () {

      if(_ctzP.seccion == 'pieza') {
        _ctzP.seccion = 'marcas';
        _ctzP.taps = 'auto';
      }else{
        _ctzP.seccion = 'pieza';
        _ctzP.taps = 'piezas';
      }
      _ctrT.text = _ctzP.txtEdit.toLowerCase().trim();
      _ctzP.txtEdit = '';
      setState(() {});
      
      Future.delayed(const Duration(microseconds: 250), () {
        _ctzP.seccion = accSec;
        _ctzP.taps = 'piezas';
        _ctrT.selection = TextSelection(baseOffset: 0, extentOffset: _ctrT.text.length);
        _fco.requestFocus();
      });
    });
  }
}