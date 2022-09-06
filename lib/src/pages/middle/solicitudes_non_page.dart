import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/pages_provider.dart';
import '../widgets/loading_middle.dart';
import '../widgets/lst_ordenes.dart';
import '../widgets/txt_bsk_orden.dart';
import '../../config/sng_manager.dart';
import '../../vars/globals.dart';
import '../../services/status/stts_cache.dart';

class SolicitudesNonPage extends StatefulWidget {

  const SolicitudesNonPage({ Key? key }) : super(key: key);

  @override
  State<SolicitudesNonPage> createState() => _SolicitudesNonPageState();
}

class _SolicitudesNonPageState extends State<SolicitudesNonPage> {

  final Globals globals = getSngOf<Globals>();
  final SttsCache rutasCache = getSngOf<SttsCache>();

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
            TxtBskOrden(
              onSearch: (String val) {
                _txtLoading = val;
              },
              onRefresh: (String val) {
                _txtLoading = val;
                _isLoading = true;
                final pagePro = context.read<PageProvider>();
                pagePro.refreshLsts = true;
              }
            ),
            Expanded(
              child: LstOrdenes(
                asignadas: false,
                onLoading: (Map<String, dynamic> res) {
                  if(mounted) {
                    setState(() {
                      _isLoading = res['isLoading'];
                      _txtLoading = res['msg'];
                    });
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
