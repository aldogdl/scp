import 'package:flutter/material.dart';

import '../../repository/contacts_repository.dart';

class CotizadoresPage extends StatefulWidget {

  const CotizadoresPage({Key? key}) : super(key: key);

  @override
  State<CotizadoresPage> createState() => _CotizadoresPageState();
}

class _CotizadoresPageState extends State<CotizadoresPage> {

  final ContactsRepository _contacEm = ContactsRepository();
  late Future _getAllCotizadores;
  //final List<ContacsEntity> _items = [];

  @override
  void initState() {
    _getAllCotizadores = _getAllCots();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _getAllCotizadores,
      builder: (_,AsyncSnapshot snap) {

        return _load();
      }
    );
  }

  ///
  Widget _load() {

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: const [
          CircularProgressIndicator(),
          SizedBox(),
          Text(
            'Cargando',
            textScaleFactor: 1,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  ///
  Future<void> _getAllCots() async {

    await _contacEm.getAllContacts();
    // List<ContacsEntity> _items = _contacEm.result['body'];
  }
}