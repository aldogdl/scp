import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/texto.dart';
import '../widgets/widgets_utils.dart';
import '../../config/sng_manager.dart';
import '../../services/get_content_files.dart';
import '../../providers/pages_provider.dart';
import '../../providers/socket_conn.dart';
import '../../providers/invirt_provider.dart';
import '../../vars/globals.dart';

class ConfigPage extends StatefulWidget {

  const ConfigPage({Key? key}) : super(key: key);

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {

  final Globals globals = getSngOf<Globals>();
  final ScrollController _scrCtr = ScrollController();
  final ScrollController _scrCtrLog = ScrollController();
  final ValueNotifier<List<Map<String, dynamic>>> _logs = ValueNotifier<List<Map<String, dynamic>>>([]);

  bool isAdmin = false;
  List<Map<String, dynamic>> _regsLogins = [];

  @override
  void initState() {

    for (var i = 0; i < globals.user.roles.length; i++) {
      if(globals.user.roles[i].contains('ADMIN')) {
        isAdmin = true;
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _scrCtr.dispose();
    _logs.dispose();
    _scrCtrLog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    Widget s10 = const SizedBox(height: 10);
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.read<PageProvider>().page = Paginas.solicitudes,
              icon: const Icon(Icons.close, size: 18,)
            ),
            const Texto(txt: 'MENÚ PRINCIPAL', txtC: Colors.white, isBold: true),
          ],
        ),
        const Divider(color: Colors.grey),
        const Texto(txt: 'ACCIONES Y CONFIGURACIONES', sz: 13),
        s10,
        _iteMenu(context, icon: Icons.home, label: 'Portada', secc: 'home'),
        s10,
        _iteMenu(context, icon: Icons.fact_check_outlined, label: 'Ordenes por Revisar', secc: 'soliOk'),
        s10,
        _iteMenu(context, icon: Icons.dvr_outlined, label: 'Almacén Virtual', secc: 'almacenVirtual'),
        s10,
        _iteMenu(context, icon: Icons.shopify_outlined, label: 'Generar Solicitud de Cotización', secc: 'cotiza'),
        s10,
        const Divider(),
        s10,
        _iteMenu(context, icon: Icons.logout, label: 'Cerrar Sesión', secc: 'cerrar_sesion'),
        if(isAdmin)
          ...[
            const Divider(color: Colors.grey),
            s10,
            const Texto(txt: 'ADMINISTRACIÓN', sz: 13),
            s10,
            _iteMenu(context, icon: Icons.not_listed_location_outlined, label: 'Asiganar Nuevas ORDENES', secc: 'soliNon'),
            s10,
            _iteMenu(context, icon: Icons.business, label: 'Empresas y Cotizadores', secc: 'empresas'),
            s10,
            _iteMenu(context, icon: Icons.calculate_rounded, label: 'Gestión Cotizadores', secc: 'gestCotz'),
            s10,
            _iteMenu(context, icon: Icons.account_circle_outlined, label: 'Miembros Administrativos', secc: 'admin_user'),
            s10,
            _iteMenu(context, icon: Icons.clear_all, label: 'Borrar Registro de Login', secc: 'dialog_del_reg'),
            s10,
            _iteMenu(context, icon: Icons.video_settings_rounded, label: 'Build ScraNet', secc: 'data_scranet'),
          ]
      ],
    );
  }

  ///
  Widget _iteMenu(BuildContext context, {
    required IconData icon, required String label, required String secc })
  {
    
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
  Widget _lstRegLogins(StateSetter setStateInt) {

    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.height * 0.2,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        maxHeight: MediaQuery.of(context).size.height * 0.35,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5)
              ),
              child: SizedBox.expand(
                child: _listaOf(
                  type: 'user', items: _regsLogins, ctr: _scrCtr,
                  onDelete: (index) async => await _borrarEntradaAction(setStateInt, index)
                ),
              )
            )
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2)
              ),
              child: SizedBox.expand(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _logs,
                  builder: (_, lstItems, __) {

                    if(lstItems.isEmpty) {
                      return Center(
                        child: Icon(Icons.receipt_long, size: 100, color: Colors.black.withOpacity(0.3)),
                      );
                    }

                    return _listaOf(type: 'logs', items: lstItems, ctr: _scrCtrLog);
                  },
                ),
              ),
            )
          ),
        ],
      ),
    );
  }

  ///
  Widget _listaOf({
    required String type, required List<Map<String, dynamic>> items,
    required ScrollController ctr, ValueChanged<int>? onDelete})
  {

    return Scrollbar(
      controller: ctr,
      thumbVisibility: true,
      radius: const Radius.circular(3),
      trackVisibility: true,
      child: ListView.builder(
        controller: ctr,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 10),
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (_, index) => (type == 'user')
        ? _tileRegLogin(index, onDelete: onDelete!)
        : _tileRegLogs(index, items)
      ),
    );
  }
  
  ///
  Widget _tileRegLogin(int index, {required ValueChanged<int> onDelete}) {

    return ListTile(
      leading: IconButton(
        icon: const Icon(Icons.delete_forever),
        color: Colors.red,
        padding: const EdgeInsets.all(0),
        constraints: const BoxConstraints(
          maxWidth: 20
        ),
        iconSize: 19,
        onPressed: () => onDelete(index),
        visualDensity: VisualDensity.compact,
      ),
      minLeadingWidth: 19,
      dense: true,
      visualDensity: VisualDensity.compact,
      trailing: Texto(txt: '${_regsLogins[index]['id']}'),
      title: Texto(txt: _regsLogins[index]['nombre']),
      subtitle: Texto(txt: _regsLogins[index]['curc'], sz: 12, txtC: Colors.white),
      mouseCursor: SystemMouseCursors.click,
      onTap: () {
        _logs.value = _regsLogins[index]['logs'];
      },
    );
  }

  ///
  Widget _tileRegLogs(int index, List<Map<String, dynamic>> items) {

    return Column(
      children: [
        _lineDataLog(label: 'REGISTROS DE:', value: '${items[index]['name']}'),
        _lineDataLog(label: 'Clave Única de Registro C.:', value: items[index]['curc']),
        _lineDataLog(label: 'Cantidad de Entradas', value: '${items[index]['cnt']}'),
        _lineDataLog(label: 'Última Entrada', value: items[index]['echo']),
        _lineDataLog(label: 'Realizada desde:', value: items[index]['app']),
        _lineDataLog(label: 'Protocolo de Internet:', value: items[index]['ip']),
        const Divider()
      ],
    );
  }

  ///
  Widget _lineDataLog({ required String label, required String value }) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 5),
          Texto(txt: label, sz: 13, txtC: Colors.amber),
          const Spacer(),
          Texto(txt: value, sz: 13, txtC: Colors.white),
        ],
      ),
    );
  }

  ///
  void _changeSecc(BuildContext context, String secc) {

    if(secc == 'dialog_del_reg') {
      _deleteRegUserLogin();
    }else{

      final pProv = context.read<PageProvider>();

      switch (secc) {
        case 'cerrar_sesion':
        final sock = context.read<SocketConn>();
          sock.cerrarConection();
          sock.isLoged = false;
          sock.makeRegToHarbi = false;
          pProv.resetPage();
          context.read<InvirtProvider>().cleanVars();
          return;
        case 'soliNon':
          pProv.page = Paginas.solicitudesNon;
          return;
        case 'soliOk':
          pProv.page = Paginas.solicitudes;
          return;
        case 'almacenVirtual':
          pProv.page = Paginas.almacenVirtual;
          return;
        case 'cotiza':
          pProv.page = Paginas.cotiza;
          return;
      }

      pProv.confSecction = secc;
      setState(() {});
    }
  }

  /// Visualizamos las entradas del registro al login para su Gestión
  Future<void> _deleteRegUserLogin() async {

    WidgetsAndUtils.showAlertBody(
      context,
      titulo: 'HISTORIAL DE ENTRADAS AL LOGIN',
      onlyAlert: false,
      onlyYES: true,
      msgOnlyYes: 'CERRAR VENTANA',
      body: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {

          return FutureBuilder(
            future: _getAllRegistroUserLogin(),
            builder: (_, AsyncSnapshot snap) {
              
              if(snap.connectionState == ConnectionState.done) {
                if(_regsLogins.isNotEmpty) {
                  return _lstRegLogins(setState);
                }else{
                  return const Texto(txt: 'No hay registros que mostrar');
                }
              }

              return const Center(
                child: SizedBox(
                  height: 40, width: 40,
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        }
      )
    );
  }

  ///
  Future<void> _getAllRegistroUserLogin() async {

    _regsLogins = await GetContentFile.regOfLogin();
  }

  ///
  Future<void> _borrarEntradaAction(StateSetter setStateInt, int index) async {

    bool? acc = await WidgetsAndUtils.showAlert(
      context,
      titulo: 'Eliminando el Registro de Entrada',
      onlyAlert: false,
      withYesOrNot: true,
      msg: 'Se eliminará permanentemente el registro de entrada para '
      '${_regsLogins[index]['nombre']}.\n¿Estás segur@ de continuar?'
    );
    acc = (acc == null) ? false : acc;
    if(acc) {
      bool hecho = await GetContentFile.deleteRegOfLogin(_regsLogins[index]['curc']);
      if(hecho) {
        setStateInt((){});
      }
    }
  }
}