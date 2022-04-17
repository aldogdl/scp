import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/sng_manager.dart';
import 'pages/widgets/my_tool_tip.dart';
import 'providers/pages_provider.dart';
import 'vars/globals.dart';
import 'providers/window_cnf_provider.dart';

class ToolsBarr extends StatelessWidget {

  ToolsBarr({Key? key}) : super(key: key);
  final Globals globals = getSngOf<Globals>();

  @override
  Widget build(BuildContext context) {

    final pageProvi = context.watch<PageProvider>();
    return Container(
      width: context.read<WindowCnfProvider>().tamToolBar,
      color: context.read<WindowCnfProvider>().sidebarColor,
      child: Column(
        children: [
          _btn(
            tip: 'Solicitudes sin Asiganar', icono: Icons.extension_off_outlined,
            isActive: (context.watch<PageProvider>().page == Paginas.solicitudesNon) ? true : false,
            fnc: () => pageProvi.page = Paginas.solicitudesNon
          ),
          _btn(
            tip: 'Solicitudes', icono: Icons.extension_outlined,
            isActive: (context.watch<PageProvider>().page == Paginas.solicitudes) ? true : false,
            fnc: () => pageProvi.page = Paginas.solicitudes
          ),
          _btn(
            tip: 'Cotizadores', icono: Icons.personal_injury_outlined,
            isActive: (context.watch<PageProvider>().page == Paginas.cotizadores) ? true : false,
            fnc: () => pageProvi.page = Paginas.cotizadores
          ),
          _btn(
            tip: 'Solicitantes', icono: Icons.people_alt_outlined,
            isActive: (context.watch<PageProvider>().page == Paginas.solicitantes) ? true : false,
            fnc: () => pageProvi.page = Paginas.solicitantes
          ),
          const Spacer(),
          _btn(
            tip: 'Configuraciones', icono: Icons.settings_outlined,
            isActive: (context.watch<PageProvider>().page == Paginas.config) ? true : false,
            fnc: () => pageProvi.page = Paginas.config
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required String tip,
    required IconData icono,
    required Function fnc,
    required bool isActive,
  }) {

    return MyToolTip(
      msg: tip,
      child: IconButton(
        padding: const EdgeInsets.symmetric(vertical: 15),
        onPressed: () => fnc(),
        icon: Icon(icono, size: 30,
          color: (isActive) ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 133, 133, 133)
        )
      ),
    );
  }
}