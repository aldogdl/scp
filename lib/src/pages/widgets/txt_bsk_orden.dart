import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/items_selects_glob.dart';
import '../../repository/ordenes_repository.dart';
import '../../vars/shortcut_activators.dart';
import 'my_tool_tip.dart';
import 'texto.dart';

class TxtBskOrden extends StatefulWidget {

  final ValueChanged<String> onSearch;
  final ValueChanged<String> onRefresh;
  const TxtBskOrden({
    Key? key,
    required this.onSearch,
    required this.onRefresh
  }) : super(key: key);

  @override
  State<TxtBskOrden> createState() => _TxtBskOrdenState();
}

class _TxtBskOrdenState extends State<TxtBskOrden> {

  final OrdenesRepository _ordenEm = OrdenesRepository();
  final TextEditingController _txtCtr = TextEditingController();
  final FocusNode _fcsTxt = FocusNode();
  final ValueNotifier<String> _msg = ValueNotifier<String>('Buscar Orden');

  String _accTxt = 'bsk';
  bool _isInit = false;
  
  late ItemSelectGlobProvider provi;

  @override
  void dispose() {
    _msg.dispose();
    _txtCtr.dispose();
    _fcsTxt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      provi = context.read<ItemSelectGlobProvider>();
    }
    
    return Column(
      children: [
        SizedBox(
          height: 35,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: FocusableActionDetector(
                    focusNode: _fcsTxt,
                    shortcuts: <ShortcutActivator, Intent>{
                      downElement: DownElement(),
                      searchElement: SearchElement(),
                    },
                    actions: <Type, Action<Intent>>{
                      DownElement: CallbackAction<Intent>(
                        onInvoke: (intent) async => await _searchOrDown('down')
                      ),
                      SearchElement: CallbackAction<Intent>(
                        onInvoke: (intent) async => await _searchOrDown('bsk')
                      )
                    },
                    child: TextField(
                      controller: _txtCtr,
                      onSubmitted: (v) async => await _searchOrDown(_accTxt),
                      onChanged: (v) {
                        if(v.isEmpty) {
                          _msg.value = (_accTxt == 'bsk') ? 'Buscar Orden' : 'Recuperar Orden por ID';
                        }
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.green,
                            width: 1
                          )
                        )
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                MyToolTip(
                  msg: 'Buscar [ctrl-alt-b]',
                  child: IconButton(
                    onPressed: () async => await _searchOrDown('bsk'),
                    icon: Icon(
                      Icons.search,
                      color: (_accTxt == 'bsk') ? Colors.blue : Colors.grey,
                    )
                  ),
                ),
                MyToolTip(
                  msg: 'Refrescar [ctrl-alt-d]',
                  child: IconButton(
                    onPressed: () => widget.onRefresh('Refrescando...'),
                    icon: Icon(
                      Icons.refresh,
                      color: (_accTxt == 'down') ? Colors.blue : Colors.grey,
                    )
                  )
                )
              ],
            )
          )
        ),
        const SizedBox(height: 5),
        ValueListenableBuilder<String>(
          valueListenable: _msg,
          builder: (_, val, __) {

            Color txtC = Colors.grey.withOpacity(0.9);
            if(val.startsWith('alert')) {
              txtC = Colors.amber;
              val = val.replaceAll('alert', '').trim();
            }
            return Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Texto(txt: val, sz: 12, txtC: txtC)
            );
          },
        ),
        const SizedBox(height: 10),
        const Divider(color: Color.fromARGB(255, 0, 0, 0), height: 1),
        const Divider(color: Color.fromARGB(255, 83, 83, 83), height: 1),
        const SizedBox(height: 10),
      ],
    );
  }

  ///
  Future<void> _searchOrDown(String acc) async {

    _accTxt = acc;
    if(acc == 'bsk') {
      widget.onSearch('Ordenes');
      _msg.value = 'Buscar Orden';
    }

    if(_accTxt == 'down') {

      _msg.value = 'Recuperar Orden por ID';
      int? idOrden = int.tryParse(_txtCtr.text);
      if(idOrden == null) {
        _msg.value = 'El Id no es valido';
      }else{
        
        _msg.value = 'Descargando, espera por favor';
        await _ordenEm.getOrdenById('_searchOrDown', idOrden);

        if(_ordenEm.result['body'].isNotEmpty) {
          _msg.value = 'Listo...';
          // final ordenFinded = Map<String, dynamic>.from(_ordenEm.result['body']);
          
          Future.delayed(const Duration(seconds: 1), (){
            _msg.value = 'Recuperar Orden por ID';
          });
        }else{
          _msg.value = 'alert No existe la Orden $idOrden';
          Future.delayed(const Duration(seconds: 3), (){
            _msg.value = 'Recuperar Orden por ID';
          });
        }
        setState(() {});
      }
    }
  }

}