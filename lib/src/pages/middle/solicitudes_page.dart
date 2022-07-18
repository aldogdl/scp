import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/providers/pages_provider.dart';

import '../widgets/loading_middle.dart';
import '../widgets/lst_ordenes.dart';
import '../widgets/txt_bsk_orden.dart';
import '../../config/sng_manager.dart';
import '../../vars/globals.dart';

class SolicitudesPage extends StatefulWidget {

  const SolicitudesPage({ Key? key }) : super(key: key);

  @override
  State<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends State<SolicitudesPage> {

  final Globals globals = getSngOf<Globals>();
  
  final ValueNotifier<bool> _showLoading = ValueNotifier<bool>(true);
  String _txtLoading = 'Ordenes';

  @override
  void dispose() {
    _showLoading.dispose();
    super.dispose();
  }

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
              onRefresh: (String val) {
                _txtLoading = val;
                _showLoading.value = true;
                final pagePro = context.read<PageProvider>();
                pagePro.refreshLsts = true;
              }
            ),
            Expanded(
              child: LstOrdenes(
                asignadas: true,
                onLoading: (Map<String, dynamic> res) {
                  _showLoading.value = res['isLoading'];
                  _txtLoading = res['msg'];
                },
              ),
            ),
          ],
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _showLoading,
          builder: (_, val, child) => (val) ? child! : const SizedBox(),
          child: Positioned.fill(
            child: LoadingMiddle(msg: _txtLoading),
          ),
        )
      ],
    );
  }

}
