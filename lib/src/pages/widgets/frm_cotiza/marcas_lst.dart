import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scranet/tile_marcas_anet.dart';
import '../../../entity/marcas_entity.dart';
import '../../../providers/cotiza_provider.dart';
import '../../../repository/autos_repository.dart';

class MarcasLst extends StatefulWidget {

  final ValueChanged<String> onTap;
  const MarcasLst({
    Key? key,
    required this.onTap
  }) : super(key: key);

  @override
  State<MarcasLst> createState() => _MarcasLstState();
}

class _MarcasLstState extends State<MarcasLst> {

  final _sctr = ScrollController();
  final _autoEm = AutosRepository();
  late CotizaProvider _ctzP;
  late Future _getMarcas;

  bool _isInit = false;
  List<MarcasEntity> _lstItems = [];

  @override
  void initState() {
    _getMarcas = _getMarcasByFile();
    super.initState();
  }

  @override
  void dispose() {
    _sctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(_ctzP.lMarcas.isNotEmpty) { return _lst(); }
    
    return FutureBuilder<void>(
      future: _getMarcas,
      builder: (_, AsyncSnapshot snap) {

        if(snap.connectionState == ConnectionState.done) {
          if(_ctzP.lMarcas.isNotEmpty) {
            return _lst();
          }
        }

        return const SizedBox();
      }
    );
  }

  ///
  Widget _lst() {

    return Expanded(
      child: Scrollbar(
        controller: _sctr,
        thumbVisibility: true,
        radius: const Radius.circular(3),
        trackVisibility: true,
        child: Selector<CotizaProvider, String>(
          selector: (_, prov) => prov.search,
          builder: (_, searching, __) {

            if(!searching.contains('.')) {
              _lstItems = _ctzP.lMarcas.where((element) => element.marca.contains(searching)).toList();
            }

            return ListView.builder(
              controller: _sctr,
              itemCount: _lstItems.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemBuilder: (_, index) {
                
                return TileMarcasAnet(
                  auto: _lstItems[index],
                  withNumbers: index +1,
                  hasDelete: false,
                  onTap: (marca) {
                    widget.onTap('${_lstItems[index].marca}.${index +1}');
                  },
                  onDelete: (marca) {}
                );
              }
            );
          },
        )
      ),
    );
  }

  ///
  Future<void> _getMarcasByFile() async {

    if(!_isInit) {
      _isInit = true;
      _ctzP = context.read<CotizaProvider>();
    }
    _ctzP.lMarcas = await _autoEm.getMarcasFromFile();
    _lstItems = _ctzP.lMarcas;
  }
}