import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/socket_conn.dart';
import '../../services/get_paths.dart';
import '../../providers/pages_provider.dart';

class SplasPage extends StatefulWidget {

  const SplasPage({Key? key}) : super(key: key);

  @override
  State<SplasPage> createState() => _SplasPageState();
}

class _SplasPageState extends State<SplasPage> {

  late PageProvider prov;
  late SocketConn conn;
  bool _isInit = false;

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
                    snap.data ?? 'Configurando...',
                    textScaleFactor: 1,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.7)
                    ),
                  ),
                  const SizedBox(height: 20),
                  if(snap.data != null && snap.data!.startsWith('ERR'))
                    IconButton(
                      onPressed: () => setState(() {}),
                      icon: Icon(Icons.refresh, size: 35, color: Colors.white.withOpacity(0.5))
                    )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ///
  Stream<String> _initialization() async* {

    String response = '';
    yield 'Recuperando datos de Conexi??n';
    response = await conn.getIpToHarbiFromServer();
    yield response;
    if(response.contains('ERROR')){ return; }

    yield 'Checando existencia del Servidor HARBI';
    response = await conn.probandoConnWithHarbi();
    yield response;
    if(response.contains('ERROR')){ return; }

    yield 'Revisando tu sistema de archivos';
    GetPaths.existeFileSystemRoot();

    yield 'Buscando uris internas de producci??n';
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

    yield 'Comencemos...';
    await Future.delayed(const Duration(milliseconds: 500));
    prov.isSplash = false;
  }
}