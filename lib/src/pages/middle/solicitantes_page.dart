import 'package:flutter/material.dart';
import 'package:scp/src/config/sng_manager.dart';
import 'package:scp/src/vars/globals.dart';

class SolicitantesPage extends StatelessWidget {

  SolicitantesPage({Key? key}) : super(key: key);

  final Globals globals = getSngOf<Globals>();

  @override
  Widget build(BuildContext context) {

    return const SizedBox(
      child: Text('solicitantes'),
    );
  }
}