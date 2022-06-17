import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/socket_conn.dart';

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
          itemBuilder: (_, index) => _tileManifest(provi, index)
        ),
      )
    );
  }

  ///
  Widget _tileManifest(SocketConn provi, int index) {

    const sp5w = SizedBox(width: 5);
    const sp5h = SizedBox(height: 5);

    final m = provi.manifests[index];
    var cambios = <String>[];
    if(m['cambios'].isNotEmpty) {
      cambios = List<String>.from(m['cambios']);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _txt(m['created'], color: const Color.fromARGB(255, 190, 190, 190)),
            const Spacer(),
            _txt('Ver: ${m['ver']}', color: const Color.fromARGB(255, 7, 151, 43)),
            sp5w,
          ],
        ),
        const Divider(height: 10, color: Color.fromARGB(255, 99, 99, 99)),
        if(m['cambios'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cambios.map(
              (e) => _txt('[√] $e')
            ).toList(),
          ),
        sp5h,
      ],
    );
  }

  ///
  Widget _txt(String label,{Color color = const Color(0xFF4d96fe)}) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        textScaleFactor: 1,
        style: GoogleFonts.inconsolata(
          fontSize: 15,
          color: color
        )
      ),
    );
  }
}