import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config_sections/gest_cotizadores.dart';
import 'config_sections/admin_users.dart';
import 'config_sections/empresas.dart';
import 'config_sections/home.dart';
import '../../providers/pages_provider.dart';

class CConfigPage extends StatelessWidget {
  const CConfigPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Selector<PageProvider, String>(
      selector: (_, pages) => pages.confSecction, 
      builder: (_, secc, __){
        
        return Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: _determinarSeccion(context, secc),
        );
      },
    );
  }

  ///
  Widget _determinarSeccion(BuildContext context, String secc) {

    late Widget child;

    switch (secc) {
      case 'empresas':
        child = const Empresas();
        break;
      case 'admin_user':
        child = const AdminUsers();
        break;
      case 'gestCotz':
        child = const GestCotizadores();
        break;
      default:
        child = Home();
    }
    return child;
  }
}