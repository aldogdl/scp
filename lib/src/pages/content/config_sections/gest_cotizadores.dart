import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/contacts_entity.dart';
import '../../../providers/items_selects_glob.dart';
import '../../../repository/contacts_repository.dart';
import '../../widgets/texto.dart';

class GestCotizadores extends StatefulWidget {

  const GestCotizadores({Key? key}) : super(key: key);

  @override
  State<GestCotizadores> createState() => _GestCotizadoresState();
}

class _GestCotizadoresState extends State<GestCotizadores> {

  final ContactsRepository _contacEm = ContactsRepository();
  final ScrollController _scrollCtr = ScrollController();
  final ValueNotifier<int> _cantTo = ValueNotifier<int>(0);
  final ValueNotifier<int> _cantSe = ValueNotifier<int>(0);

  late final ItemSelectGlobProvider _items;
  Map<String, dynamic> filtro = {
    'fLocal': true,
    'fForan': false,
    'fPieza': true,
    'fMarca': true,
    'fEspec': false,
    'fFavor': true,
    'fPatro': true
  };
  late final Future _recuperarAllContacts;
  bool _isInit = false;
  final List<int> _idsSelected = [];
  bool _isSelecAll = false;
  bool _isReloding = false;
  int indice = 0;

  @override
  void initState() {
    _recuperarAllContacts = _getAllContacts();
    super.initState();
  }

  @override
  void dispose() {
    _scrollCtr.dispose();
    _cantTo.dispose();
    _cantSe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height 
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            color: Colors.black.withOpacity(0.3),
            child: _filtros(),
          ),
          _barra(),
          Expanded(child: _lstContactos())
        ],
      ),
    );
  }


  ///
  Widget _barra() {

    return Container(
      padding: const EdgeInsets.only(top: 5, right: 10, bottom: 5, left: 23),
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height * 0.05,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5
          )
        )
      ),
      child: Row(
        children: [
          Checkbox(
            checkColor: Colors.white,
            activeColor: const Color.fromARGB(255, 33, 33, 33),
            value: _isSelecAll,
            onChanged: (bool? val){
              if(val != null) {
                if(val) {
                  _items.contacts.map((e) {
                    if(!_idsSelected.contains(e.id)) {
                      _idsSelected.add(e.id);
                    }
                  }).toList();
                }else{
                  _idsSelected.clear();
                }
                setState(() {
                  _isSelecAll = val;
                });
              }
            }
          ),
          const Spacer(),
          const Texto(txt: 'Totales:'),
          const SizedBox(width: 5),
          const Texto(txt: 'Contactos: ', sz: 14),
          ValueListenableBuilder(
            valueListenable: _cantTo,
            builder: (_, val, __) {
              return Texto(txt: '$val', sz: 15, txtC: Colors.white, isBold: false);
            }
          ),
          const SizedBox(width: 20),
          const Texto(txt: 'Seleccionados: ', sz: 14),
          ValueListenableBuilder(
            valueListenable: _cantSe,
            builder: (_, val, __) {
              return Texto(txt: '$val', sz: 15, txtC: Colors.white, isBold: false);
            }
          ),
          const SizedBox(width: 30),
          TextButton.icon(
            style: ButtonStyle(
              padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
              visualDensity: VisualDensity.compact
            ),
            onPressed: (){
              setState(() {
                _isReloding = true;
                _items.contactsOfNotified = [];
              });
              _getAllContacts(force: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Texto(txt: 'Recargar Lista', sz: 12,)
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  ///
  Widget _filtros() {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Texto(txt: 'FILTROS PREESTABLECIDOS', txtC: Colors.white, isBold: false, isCenter: true, sz: 19),
        const Divider(color: Colors.green),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Texto(txt: '-- LUGAR --', txtC: Colors.grey, isBold: true, isCenter: true, sz: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ..._checkFiltro(filtro['fLocal'], 'fLocal', 'Locales'),
                      const SizedBox(width: 10),
                      ..._checkFiltro(filtro['fForan'], 'fForan', 'Foraneos'),
                    ],
                  )
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Texto(txt: '-- ESPECIALIDADES --', txtC: Colors.grey, isBold: true, isCenter: true, sz: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ..._checkFiltro(filtro['fPieza'], 'fPieza', 'Piezas'),
                      const SizedBox(width: 10),
                      ..._checkFiltro(filtro['fMarca'], 'fMarca', 'Marcas'),
                      const SizedBox(width: 10),
                      ..._checkFiltro(filtro['fFavor'], 'fFavor', 'Favoritos'),
                      const SizedBox(width: 10),
                      ..._checkFiltro(filtro['fPatro'], 'fPatro', 'Patrocinio'),
                    ],
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  ///
  List<Widget> _checkFiltro(bool value, String key, String label) {

    return [
      Checkbox(
        checkColor: Colors.white,
        activeColor: const Color.fromARGB(255, 33, 33, 33),
        value: value,
        onChanged: (val){
          setState(() {
            filtro[key] = val!;
          });
        }
      ),
      Texto(txt: label, txtC: Colors.green, isBold: false, isCenter: true, sz: 14),
    ];
  }

  ///
  Widget _lstContactos() {

    return FutureBuilder(
      future: _recuperarAllContacts,
      builder: (_, AsyncSnapshot snap) {
        if(snap.connectionState == ConnectionState.done) {
          
          return Selector<ItemSelectGlobProvider, List<ContacsEntity>>(
            selector: (_, prov) => prov.contacts,
            builder: (_, lst, __) => (_isReloding) ? _loading() : _lst(), 
          );
        }
        return _loading();
      }
    );
  }

  ///
  Widget _lst() {

    indice = 0;
    final colsSize = <double>[1,10,170,150,64,80,25];
    Map<int, FixedColumnWidth> cols = {};
    for (var i = 0; i < colsSize.length; i++) {
      cols.putIfAbsent(i, () => FixedColumnWidth(colsSize[i]));
    }

    return Scrollbar(
      controller: _scrollCtr,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: SizedBox.expand(
        child: SingleChildScrollView(
          controller: _scrollCtr,
          padding: const EdgeInsets.only(right: 10),
          physics: const BouncingScrollPhysics(),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: cols,
            children: _items.contacts.map((e) => _tileContact(e) ).toList()
          ),
        ),
      )
    );
    
  }

  ///
  TableRow _tileContact(ContacsEntity contact) {

    indice++;
    return TableRow(
      decoration: BoxDecoration(
        color: (indice.isEven) ? Colors.black.withOpacity(0.2) : Colors.transparent
      ),
      children: <Widget>[
        Checkbox(
          key: Key('$indice'),
          checkColor: Colors.white,
          activeColor: const Color.fromARGB(255, 33, 33, 33),
          value: _idsSelected.contains(contact.id),
          onChanged: (bool? val){
            if(val != null) {
              if(val) {
                if(!_idsSelected.contains(contact.id)) {
                  _idsSelected.add(contact.id);
                }
              }else{
                _idsSelected.remove(contact.id);
              }
            }
            setState(() {
              _cantSe.value = _idsSelected.length;
            });
          }
        ),
        Texto(txt: '$indice'),
        Texto(txt: contact.nombre, width: 20),
        Texto(txt: contact.nomEmp, width: 20, txtC: Colors.white.withOpacity(0.75)),
        Texto(txt: contact.celular),
        Texto(txt: contact.curc, txtC: Colors.white.withOpacity(0.75)),
        IconButton(
          onPressed: (){},
          icon: const Icon(Icons.filter_list)
        )
      ],
    );
  }

  ///
  Future<void> _getAllContacts({bool force = false}) async {

    if(!_isInit) {
      _isInit = true;
      _items = context.read<ItemSelectGlobProvider>();
    }

    if(!force) {
      if(_items.contacts.isNotEmpty){
        for (var i = 0; i < _items.contacts.length; i++) {
          _idsSelected.add(_items.contacts[i].id);
        }
        if(_idsSelected.isNotEmpty) {
          setState(() {
            _isSelecAll = true;
            _cantTo.value = _items.contacts.length;
            _cantSe.value = _idsSelected.length;
          });
        }
        return;
      }
    }

    _items.contactsOfNotified = [];
    await _contacEm.getAllCotizadores();
    List<ContacsEntity> lsR = [];

    if(!_contacEm.result['abort']) {
      if(_contacEm.result['body'].isNotEmpty) {
        final lista = List<Map<String, dynamic>>.from(_contacEm.result['body']);
        _contacEm.clear();

        for (var i = 0; i < lista.length; i++) {
          var ct = ContacsEntity();
          ct.fromServer(lista[i]);
          if(!_idsSelected.contains(ct.id)) {
            _idsSelected.add(ct.id);
          }
          final has = lsR.where((element) => element.id == ct.id);
          if(has.isEmpty) {
            lsR.add(ct);
          }
        }
      }
    }

    Future.microtask((){
      _items.contacts = List<ContacsEntity>.from(lsR);
      _cantTo.value = _idsSelected.length;
      lsR = [];
      if(_idsSelected.isNotEmpty) {
        _isSelecAll = true;
      }
      setState(() {
        _isReloding = false;
      });
    });
  }

  ///
  Widget _loading() {

    return const Center(
      child: SizedBox(
        height: 40, width: 40,
        child: CircularProgressIndicator(),
      ),
    );
  }

}