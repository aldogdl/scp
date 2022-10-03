import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/widgets_utils.dart';
import 'package:scp/src/providers/filtros_provider.dart';

import '../../../repository/contacts_repository.dart';
import '../invirt/difusor_lsts.dart';
import '../texto.dart';

class FiltrosContact extends StatefulWidget {

  final int idEmp;
  const FiltrosContact({
    Key? key,
    required this.idEmp
  }) : super(key: key);

  @override
  State<FiltrosContact> createState() => _FiltrosContactState();
}

class _FiltrosContactState extends State<FiltrosContact> {

  final _em = ContactsRepository();
  List<Map<String, dynamic>> _filtros = [];

  late Future _getFil;
  late FiltrosProvider _prov;
  bool _isInit = false;
  bool _isLoading = false;

  @override
  void initState() {
    _getFil = _getFiltroBy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Texto(txt: 'FILTROS ACTUALES', txtC: Colors.green, isBold: true, sz: 14),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _getFiltroBy(withRefresh: true);
                },
                constraints: const BoxConstraints(maxWidth: 25, maxHeight: 28),
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.refresh, size: 18, color: Color.fromARGB(255, 236, 225, 68))
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(maxWidth: 25, maxHeight: 28),
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.cancel_presentation_sharp, size: 18, color: Color.fromARGB(255, 97, 97, 97))
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: (_isLoading)
          ? _load()
          : (_isInit)
            ? _lstFiltros()
            : FutureBuilder(
              future: _getFil,
              builder: (_, AsyncSnapshot snap) {

                if(snap.connectionState == ConnectionState.done) {
                  return (_filtros.isNotEmpty) ? _lstFiltros() : const SizedBox();
                }
                return _load();
              },
            ),
        )
      ],
    );
  }

  ///
  Widget _load() {

    return const SizedBox(
      width: 50, height: 50,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2)
      ),
    );
  }

  ///
  Widget _lstFiltros() {

    return DifusorLsts(
      child: ListView.builder(
        itemCount: _filtros.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (_, int index) => _tileFilCurrent(_filtros[index]),
      ),
    );
  }

  ///
  Widget _tileFilCurrent(Map<String, dynamic> fil) {

    return Column(
      children: [
        Row(
          children: [
            Texto(txt: _prov.getTileGroup(fil), sz: 14,),
            const Spacer(),
            IconButton(
              onPressed: () async => await _deleteFiltroById(fil['f_id']),
              constraints: const BoxConstraints(maxWidth: 25, maxHeight: 28),
              padding: const EdgeInsets.all(0),
              icon: const Icon(Icons.close, size: 18, color: Color.fromARGB(255, 236, 68, 68))
            ),
          ],
        ),
        Row(
          children: [
            const Texto(txt: 'Mrk: ', sz: 11),
            Texto(txt: _prov.getMarcaById(fil), txtC: Colors.white, sz: 12),
            const SizedBox(width: 8),
            const Texto(txt: 'Desde: ', sz: 11),
            Texto(txt: fil['f_anioD'], txtC: Colors.white, sz: 12),
            const SizedBox(width: 8),
            const Texto(txt: 'Hasta: ', sz: 11),
            Texto(txt: fil['f_anioH'], txtC: Colors.white, sz: 12),
          ],
        ),
        Row(
          children: [
            const Texto(txt: 'Mdl: ', sz: 11),
            Texto(txt: _prov.getModeloById(fil), txtC: Colors.white, sz: 12),
          ],
        ),
        Row(
          children: [
            const Texto(txt: 'Pza: ', sz: 11),
            Texto(txt: fil['f_pieza'], txtC: Colors.white, sz: 12),
          ],
        ),
        const Divider(),
      ],
    );
  }

  ///
  Future<void> _getFiltroBy({bool withRefresh = false}) async {

    if(!_isInit) {
      _prov = context.read<FiltrosProvider>();
    }
    if(_isLoading) {
      _filtros = [];
    }

    if(_filtros.isEmpty) {
      await _em.getFiltroByEmp(widget.idEmp);
      if(!_em.result['abort']) {
        _filtros = List<Map<String, dynamic>>.from(_em.result['body']);
      }else{
        _filtros = [];
      }    
    }

    _isInit = true;
    if(withRefresh) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ///
  Future<void> _deleteFiltroById(int id) async {

    bool? acc = await WidgetsAndUtils.showAlert(
      context, titulo: 'Borrando Filtros',
      msg: 'Se eliminará permanentemente de las Bases de Datos '
      'este registro de Filtrado.\n¿Estás segur@ de continuar?',
      msgOnlyYes: 'Sí, Borrar',
      onlyAlert: false, onlyYES: false, withYesOrNot: true,
      focusOnConfirm: false,
    );

    acc = (acc == null) ? false : acc;

    if(acc) {
      
      setState(() { _isLoading = true; });
      await _em.delFiltroById(id, isLocal: false);

      if(!_em.result['abort']) {
        await _em.delFiltroById(id, isLocal: true);
        if(!_em.result['abort']) {
          await _getFiltroBy(withRefresh: true);
        }
      }
    }
  }

}