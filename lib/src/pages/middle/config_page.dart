import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/texto.dart';
import 'package:scp/src/providers/pages_provider.dart';

class ConfigPage extends StatefulWidget {

  const ConfigPage({Key? key}) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  @override
  Widget build(BuildContext context) {

    Widget s10 = const SizedBox(height: 10);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        const Texto(txt: 'MENÚ PRINCIPAL', txtC: Colors.white, isBold: true),
        const Divider(color: Colors.grey),
        const Texto(txt: 'ACCIONES Y CONFIGURACIONES', sz: 13),
        s10,
        _iteMenu(context, icon: Icons.home, label: 'Portada', secc: 'home'),
        const Divider(color: Colors.grey),
        const Texto(txt: 'ADMINISTRACIÓN', sz: 13),
        s10,
        _iteMenu(context, icon: Icons.business, label: 'Empresas y Miembros', secc: 'empresas'),
        s10,
        _iteMenu(context, icon: Icons.account_circle_outlined, label: 'Miembros Administrativos', secc: 'admin_user'),
        s10,
        const Divider(),
      ],
    );
  }

  Widget _iteMenu(BuildContext context, {
    required IconData icon,
    required String label,
    required String secc,
  }) {

    return TextButton.icon(
      onPressed: () => _changeSecc(context, secc),
      icon: Icon(icon),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Texto(
          txt: label,
          txtC: (secc == context.read<PageProvider>().confSecction)
          ? Colors.white : Colors.grey,
        ),
      )
    );
  }

  ///
  void _changeSecc(BuildContext context, String secc) {
    context.read<PageProvider>().confSecction = secc;
    setState(() {});
  }
}