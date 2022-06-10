import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/providers/socket_conn.dart';

import '../widgets/texto.dart';

class CentinelaConsola extends StatefulWidget {
  const CentinelaConsola({Key? key}) : super(key: key);

  @override
  State<CentinelaConsola> createState() => _CentinelaConsolaState();
}

class _CentinelaConsolaState extends State<CentinelaConsola> {

  final ScrollController _scrollCtr = ScrollController();

  @override
  void dispose() {
    _scrollCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final provi = context.read<SocketConn>();
    const sp5w = SizedBox(width: 5);
    const sp5h = SizedBox(height: 5);

    return Container(
      constraints: BoxConstraints.expand(
        width: MediaQuery.of(context).size.width
      ),
      child: Scrollbar(
        controller: _scrollCtr,
        radius: const Radius.circular(3),
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView.builder(
          controller: _scrollCtr,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 15),
          itemCount: provi.manifests.length,
          itemBuilder: (_, index) {
            
            final m = provi.manifests[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Texto(txt: '[ ${m['created']} ]', txtC: Colors.grey),
                    sp5w,
                    const Texto(txt: 'ENVIADO POR:', txtC: Colors.green),
                    sp5w,
                    Texto(txt: '${m['send_from']}', txtC: Colors.white, isBold: true),
                    const Spacer(),
                    sp5w,
                    const Texto(txt: 'UV:', txtC: Colors.green, sz: 12),
                    sp5w,
                    Texto(txt: '${m['to_version']}', txtC: Colors.amber, sz: 12),
                    sp5w,
                  ],
                ),
                sp5h,
                Texto(txt: '-> ${m['message']}', txtC: Colors.white, sz: 14),
                sp5h,
                Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                const SizedBox(height: 10),
              ],
            );
          }
        ),
      )
    );
  }
}