import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/texto.dart';

import '../widgets/scranet/build_data_gral.dart';
import '../../config/sng_manager.dart';
import '../../providers/socket_conn.dart';
import '../../providers/pages_provider.dart';
import '../../services/get_paths.dart';
import '../../vars/globals.dart';

class SplasPage extends StatefulWidget {

  const SplasPage({Key? key}) : super(key: key);

  @override
  State<SplasPage> createState() => _SplasPageState();
}

class _SplasPageState extends State<SplasPage> {

  final _globals = getSngOf<Globals>();

  late PageProvider prov;
  late SocketConn conn;
  bool _isInit = false;
  String _codeSwh = '';

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      prov = context.read<PageProvider>();
      conn = context.read<SocketConn>();
    }

    return Scaffold(
      body: Center(
        child: StreamBuilder<String>(
          stream: _initialization(),
          initialData: 'Iniciando tu SCP',
          builder: (_, AsyncSnapshot<String> snap) {

            if(snap.hasData) {
              if(snap.data!.isNotEmpty) {
                if(snap.data == '...') {
                  return BuildDataGral(onFinish: (_) => prov.isSplash = false);
                }
                if(snap.data == 'noCode') {
                  return _askCodeSwh();
                }
              }
            }

            return _initSystem(snap.data);
          },
        ),
      ),
    );
  }

  ///
  Widget _askCodeSwh() {

    final size = MediaQuery.of(context).size;
    return Center(
      child: SizedBox(
        width: size.width * 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Texto(
              txt: 'SWH', isBold: true,
              sz: 50, isCenter: true,
            ),
            const Texto(
              txt: 'No se encontró una clave de estación de trabajo valida',
              sz: 18, isCenter: true,
            ),
            TextField(
              autofocus: true,
              onChanged: (value) {
                _codeSwh = value;
              },
              onSubmitted: (value) => _setSwh(),
            )
          ],
        ),
      ),
    );
  }

  ///
  Widget _initSystem(String? snap) {

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            'Hola',
            textScaleFactor: 1,
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.w200,
              color: Colors.white
            ),
          ),
          Text(
            snap ?? 'Configurando...',
            textScaleFactor: 1,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7)
            ),
          ),
          const SizedBox(height: 20),
          if(snap != null && snap.startsWith('ERR'))
            IconButton(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh, size: 35, color: Colors.white.withOpacity(0.5))
            )
        ],
      ),
    );
  }

  ///
  Stream<String> _initialization() async* {

    String response = '';
    yield 'Recuperando datos de Conexión';

    if(_globals.env == 'dev') {
      response = await conn.getIpToHarbiFromLocal();
    }else{
      response = await conn.getIpToHarbiFromServer();
    }
    
    yield response;
    
    if(response.contains('ERROR')){ return; }
    if(response.contains('noCode')){ return; }

    yield 'Revisando tu sistema de archivos';
    GetPaths.existeFileSystemRoot();

    yield 'Buscando uris internas de producción';
    response = await conn.hasFilePathProduction();
    yield response;
    if(response.contains('ERROR')){ return; }

    yield 'Recuperando Datos [CARGOS]';
    await conn.getDataFixed('cargos');

    yield 'Recuperando Datos [ROLES]';
    await conn.getDataFixed('roles');
    
    yield 'Recuperando Datos [RUTAS]';
    await conn.getDataFixed('rutas');

    yield 'Recuperando Datos [AUTOS]';
    await conn.getDataFixed('autos');

    yield 'Recuperando Datos [CENTINELA]';
    await conn.getDataFixed('centinela');

    yield 'Recuperando Datos [COTIZADORES]';
    await conn.getCotizadores();

    yield 'Comencemos...';
    await Future.delayed(const Duration(milliseconds: 500));
    prov.isSplash = false;
  }
  
  ///
  Future<void> _setSwh() async {

    _codeSwh = _codeSwh.toUpperCase().trim();
    conn.setSwh(_codeSwh);
    setState(() {});
  }
}