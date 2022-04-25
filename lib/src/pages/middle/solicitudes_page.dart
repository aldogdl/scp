import 'package:flutter/material.dart';

import '../widgets/loading_middle.dart';
import '../widgets/lst_ordenes.dart';
import '../widgets/txt_bsk_orden.dart';
import '../../config/sng_manager.dart';
import '../../services/rutas/rutas_cache.dart';
import '../../vars/globals.dart';

class SolicitudesPage extends StatefulWidget {

  const SolicitudesPage({ Key? key }) : super(key: key);

  @override
  State<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends State<SolicitudesPage> {

  final Globals globals = getSngOf<Globals>();
  final RutasCache rutasCache = getSngOf<RutasCache>();

  bool _isLoading = true;
  String _txtLoading = 'Ordenes';

  @override
  Widget build(BuildContext context) {

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            TxtBskOrden(
              onSearch: (String val) {
                _txtLoading = val;
              },
              onDowload: (String val) {
                _txtLoading = val;
              }
            ),
            Expanded(
              child: LstOrdenes(
                asignadas: true,
                onLoading: (Map<String, dynamic> res) {
                  _isLoading = res['isLoading'];
                  _txtLoading = res['msg'];
                  if(mounted) {
                    setState(() { });
                  }
                },
              ),
            ),
          ],
        ),
        if(_isLoading)
          Positioned.fill(
            child: LoadingMiddle(msg: _txtLoading),
          )
      ],
    );
  }

}
