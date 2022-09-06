import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/loading_middle.dart';
import '../widgets/lst_ordenes.dart';
import '../widgets/txt_bsk_orden.dart';
import '../../config/sng_manager.dart';
import '../../providers/pages_provider.dart';
import '../../vars/globals.dart';

class SolicitudesPage extends StatefulWidget {

  const SolicitudesPage({ Key? key }) : super(key: key);

  @override
  State<SolicitudesPage> createState() => _SolicitudesPageState();
}

class _SolicitudesPageState extends State<SolicitudesPage> {

  final Globals globals = getSngOf<Globals>();
  
  final _showLoading = ValueNotifier<Map<String, dynamic>>(
    {'txt':'Ordenes', 'make':false}
  );

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
              onSearch: (String val) {},
              onRefresh: (String val) {
                _showLoading.value = {'txt':val, 'make':true};
                final pagePro = context.read<PageProvider>();
                pagePro.refreshLsts = true;
              }
            ),
            Expanded(
              child: LstOrdenes(
                asignadas: true,
                onLoading: (Map<String, dynamic> res) async {
                  if(mounted) {
                    try {
                      _showLoading.value = {'txt':res['msg'], 'make':res['isLoading']};
                    } catch (_) {}
                  }
                },
              ),
            ),
          ],
        ),
        ValueListenableBuilder<Map<String, dynamic>>(
          valueListenable: _showLoading,
          builder: (_, val, child) {

            if(val['make']) {
              return Positioned.fill(
                child: LoadingMiddle(msg: _showLoading.value['txt']),
              );
            }
            return const SizedBox();
          },
        )
      ],
    );
  }

}
