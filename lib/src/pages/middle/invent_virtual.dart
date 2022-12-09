import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/invirt/tile_pza.dart';
import '../widgets/invirt/titulo_seccion.dart';
import '../widgets/texto.dart';
import '../widgets/invirt/difusor_lsts.dart';
import '../widgets/invirt/tile_bandeja_entrada.dart';
import '../../repository/inventario_repository.dart';
import '../../providers/invirt_provider.dart';
import '../../services/inventario_inject_service.dart';

class InventVirtual extends StatefulWidget {

  const InventVirtual({Key? key}) : super(key: key);

  @override
  State<InventVirtual> createState() => _InventVirtualState();
}

/// Aqui simplemente tomamos todos los archivos de las ordenes que se
/// encuentran almacenados localmente
class _InventVirtualState extends State<InventVirtual> {

  final _ctrPzas = ScrollController();
  final _invEm = InventarioRepository();
  final _ctrScroll = ScrollController();
  late final InvirtProvider _invirt;
  late Future _getOrds;
  bool _isInit = false;

  @override
  void initState() {
    _getOrds = _getAllOrds('files');
    super.initState();
  }

  @override
  void dispose() async {
    _ctrPzas.dispose();
    _ctrScroll.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {

    return DifusorLsts(
      altura: 25,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _getOrds,
              builder: (_, AsyncSnapshot fileNames) {
                
                if(fileNames.connectionState == ConnectionState.done) {
                  if(fileNames.hasData) {
                    return _cmdIn(lst: fileNames.data);
                  }else{
                    return const Texto(txt: 'Sin Resultados', txtC: Colors.white);
                  }
                }
                return _load();
              },
            )
          )
        ],
      )
    );
  }

  ///
  Widget _cmdIn({List<String>? lst}) {

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Selector<InvirtProvider, Map<String, dynamic>>(
        selector: (_, prov) => prov.cmd,
        builder: (_, cmd, child) {
          
          if(cmd.isNotEmpty && cmd.containsKey('id')) {
            if(cmd['id'] > 999) {  _procesarSubCommand(cmd);  return child!; }
          }
          
          return FutureBuilder<List<String>>(
            future: InventarioInjectService(em: _invEm, prov: _invirt).make(),
            builder: (_, AsyncSnapshot<List<String>> lstsFiles) {

              if(lstsFiles.connectionState == ConnectionState.done) {

                if(cmd.isEmpty && !lstsFiles.hasData) {
                  return (child == null) ? _lstOrds(lst: _invirt.ordInvBEFiles) : child; 
                }

                if(lstsFiles.hasData) {
                  return (cmd['tipo'] == 'proceso' && lstsFiles.data!.length == 1)
                  ? _lstOrdPzas(lst: lstsFiles.data) : _lstOrds(lst: lstsFiles.data);
                  
                }else{
                  return const Texto(txt: 'Sin Resultados', txtC: Colors.white);
                }
              }
              return _load();
            }
          );
        },
        child: _lstOrds(lst: lst)
      )
    );
  }

  ///
  Widget _load() {

    return const Center(
      child: SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(),
      ),
    );
  }

  ///
  Widget _lstOrdPzas({List<String>? lst}) {

    if(lst != null) {
      if(lst.length > 1) {
        return _lstOrds(lst: lst);
      }
    }

    return Column(
      children: [
        TileBandejaEntrada(
          nomFile: lst!.first,
          isSelected: true,
          onTap: (int idOrden) => _invirt.cmd = {'cmd': 'o.$idOrden'}
        ),
        Expanded(
          child: _lstPiezas(),
        )
      ]
    );
  }

  ///
  Widget _lstOrds({List<String>? lst}) {

    lst ??= List<String>.from(_invirt.ordInvBEFiles);
    
    return ListView.builder(
      controller: _ctrScroll,
      padding: const EdgeInsets.only(
        left: 0, top: 0, right: 8, bottom: 30
      ),
      itemCount: lst.length,
      itemBuilder: (_, int index) => TileBandejaEntrada(
        nomFile: lst![index],
        isSelected: false,
        onTap: (int idOrden) => _invirt.cmd = {'cmd': 'o.$idOrden'}
      ),
    );
  }

  ///
  Widget _lstPiezas() {

    final w = MediaQuery.of(context).size.width;
    
    return Column(
      children: [
        SizedBox(
          height: 2, width: w,
          child: Center(
            child: Container(
              height: 2, width: w * 0.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 37, 37, 38),
                    Colors.blue,
                    Color.fromARGB(255, 37, 37, 38),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight
                )
              ),
            ),
          )
        ),
        Expanded(
          child: Selector<InvirtProvider, List<Map<String, dynamic>>>(
            selector: (_, prov) => prov.pzaResults,
            builder: (_, lst, __) {

              return Column(
                children: [
                  TituloSeccion(
                    ico: Icons.extension,
                    titulo: 'LISTA DE PIEZAS', chip: '${lst.length}',
                  ),
                  Expanded(
                    child: (lst.isNotEmpty)
                    ? ListView.builder(
                      controller: _ctrPzas,
                      primary: false,
                      padding: const EdgeInsets.only(
                        left: 8, top: 0, right: 15, bottom: 30
                      ),
                      itemCount: lst.length,
                      itemBuilder: (_, int index) => TilePza(
                        pieza: lst[index],
                      ),
                    )
                    : _sinResultsPiezas()
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }

  ///
  Widget _sinResultsPiezas() {

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.extension, size: 150, color: Color.fromARGB(255, 34, 34, 34)),
            SizedBox(height: 10),
            Texto(txt: 'Piezas de la Orden...')
          ],
        ),
      ),
    );
  }

  ///
  Future<List<String>> _getAllOrds(String from) async {

    if(!_isInit) {
      _isInit = true;
      _invirt = context.read<InvirtProvider>();
    }else{
      from = 'cache';
    }

    final res = await InventarioInjectService(em: _invEm, prov: _invirt).getAllOrds(from);
    return res;
  }

  /// Procesamos comandos que no afecten el filtrado un tipo ordenes generales
  Future<void> _procesarSubCommand(Map<String, dynamic> cmd) async {
    
    // Refrescamos la seccion indicada
    if(cmd['clv'] == 'rfs') {
      _invEm.cleanOrdenes();
    }
  }


}