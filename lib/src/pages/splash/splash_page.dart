import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/socket_conn.dart';
import '../../services/get_paths.dart';
import '../../providers/pages_provider.dart';

class SplasPage extends StatelessWidget {

  const SplasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final prov = context.read<PageProvider>();
    final conn = context.read<SocketConn>();

    return Scaffold(
      body: Center(
        child: StreamBuilder<String>(
          stream: _initialization(prov, conn),
          initialData: 'Iniciando tu SCP',
          builder: (_, AsyncSnapshot snap) {

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
                    snap.data,
                    textScaleFactor: 1,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.7)
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ///
  Stream<String> _initialization(PageProvider prov, SocketConn conn) async* {

    String response = '';
    yield 'Recuperando datos de Conexión';
    response = await conn.getIpToHarbiFromServer();
    yield response;
    if(response.contains('ERROR')){ return; }

    yield 'Checando existencia del Servidor HARBI';
    response = await conn.probandoConnWithHarbi();
    yield response;
    if(response.contains('ERROR')){ return; }

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

    yield 'Recuperando Datos [AUTOS]';
    await conn.getDataFixed('autos');

    yield 'Comencemos...';
    await Future.delayed(const Duration(milliseconds: 1000));
    prov.isSplash = false;
  }

}