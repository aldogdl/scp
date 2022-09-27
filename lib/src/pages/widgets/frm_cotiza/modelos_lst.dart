import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scranet/tile_modelos_anet.dart';
import '../../../entity/modelos_entity.dart';
import '../../../entity/marcas_entity.dart';
import '../../../providers/cotiza_provider.dart';
import '../../../repository/autos_repository.dart';

class ModelosLst extends StatefulWidget {

  final MarcasEntity mrkSel;
  final ValueChanged<String> onTap;
  const ModelosLst({
    Key? key,
    required this.mrkSel,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ModelosLst> createState() => _ModelosLstState();
}

class _ModelosLstState extends State<ModelosLst> {

  final _sctr = ScrollController();
  final _autoEm = AutosRepository();
  late CotizaProvider _ctzP;

  bool _isInit = false;
  int _currentMrk = -1;
  List<ModelosEntity> _lstItems = [];

  @override
  Widget build(BuildContext context) {

    if(_currentMrk == widget.mrkSel.id) {
      if(_ctzP.lModelos.isNotEmpty) { return _lst(); }
    }
    
    return FutureBuilder<void>(
      future: _getModelosByFile(),
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
              _lstItems = _ctzP.lModelos.where((element) => element.modelo.contains(searching)).toList();
            }

            return ListView.builder(
              controller: _sctr,
              itemCount: _lstItems.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              itemBuilder: (_, index) {
                
                return TileModelosAnet(
                  md: _lstItems[index],
                  hasDelete: false,
                  withNumbers: index+1,
                  onTap: (modelo) => widget.onTap('${_lstItems[index].modelo}.${index+1}'),
                  onDelete: (modelo) {}
                );
              }
            );
          },
        )
      ),
    );
  }

  ///
  Future<void> _getModelosByFile() async {

    if(!_isInit) {
      _isInit = true;
      _ctzP = context.read<CotizaProvider>();
    }
    _currentMrk = widget.mrkSel.id;
    _ctzP.lModelos = await _autoEm.getModelosFromFile(widget.mrkSel);
    _lstItems = _ctzP.lModelos;
    
  }
}