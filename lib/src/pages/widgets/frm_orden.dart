import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'texto.dart';
import '../../entity/piezas_entity.dart';
import '../../providers/items_selects_glob.dart';


class FrmOrden extends StatefulWidget {

  const FrmOrden({
    Key? key,
  }) : super(key: key);

  @override
  State<FrmOrden> createState() => _FrmOrdenState();
}

class _FrmOrdenState extends State<FrmOrden> {

  final ScrollController _scrollFotos = ScrollController();

  late final ItemSelectGlobProvider _items;
  late Future _getDatos;
  late PiezasEntity _pieza;

  @override
  void initState() {
    _getDatos = _getDatosByOrdenAndPieza();  
    super.initState();
  }

  @override
  void dispose() {
    _scrollFotos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: _getDatos,
      builder: (_, AsyncSnapshot snapshot) {

        if(snapshot.hasData) {
          if(snapshot.data) {
            return Column(
              children: [
                _containerFotos(),
                const Divider(color: Colors.green),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Texto(
                            txt: 'ORDEN No. ${_items.idOrdenSelect}', 
                            txtC: Colors.blue, sz: 22,
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Texto(
                            txt: 'Datos del Solicitante', 
                            txtC: Colors.blue, sz: 22,
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            );
          }else{
            return const Center(child: Texto(txt: 'No se encontró la pieza'));    
          }
        }

        return const Center(child: Texto(txt: 'Cargando...'));
      }
    );
  }

  ///
  Widget _containerFotos() {

    return Container(
      constraints: const BoxConstraints.expand(
        height: 150
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
      ),
      padding: const EdgeInsets.all(10),
      child: FutureBuilder(
        future: _getFotosByIdPieza(),
        builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> fotosData) {

          if(fotosData.connectionState == ConnectionState.done) {
            if(fotosData.hasData) {
              if(fotosData.data!.isNotEmpty) {
                
                return Scrollbar(
                  controller: _scrollFotos,
                  trackVisibility: true,
                  child: ListView.builder(
                    controller: _scrollFotos,
                    scrollDirection: Axis.horizontal,
                    itemCount: fotosData.data!.length,
                    itemBuilder: (_, index) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        width: 200,
                        height: 150,
                        child: AspectRatio(
                          aspectRatio: 4/3,
                          child: CachedNetworkImage(
                            imageUrl: fotosData.data![index]['foto'],
                            fit: BoxFit.cover,
                          )
                        ),
                      );
                    }
                  )
                );
              }else{
                return Center(child: Texto(txt: 'Sin Fotos', txtC: Colors.amber.withOpacity(0.5)));
              }
            } 
          }
          return const SizedBox();
        },
      ),
    );
  }

  ///
  Future<List<Map<String, dynamic>>> _getFotosByIdPieza() async {
    return _items.fotosByPiezas.where(
      (element) => element['id'] == _pieza.id
    ).toList();
  }

  ///
  Future<bool> _getDatosByOrdenAndPieza() async {

    _items = context.read<ItemSelectGlobProvider>();
    final has = _items.piezas.where((element) => element.id == _items.idPzaSelect);
    if(has.isNotEmpty) {
      _pieza = has.first;      
      return true;
    }
    return false;
  }

}