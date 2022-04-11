import 'package:flutter/material.dart';

import '../../widgets/texto.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Texto(txt: 'Admin Users')),
    );
  }
}