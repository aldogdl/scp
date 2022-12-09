import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/texto.dart';
import '../../config/sng_manager.dart';
import '../../providers/pages_provider.dart';
import '../../providers/socket_conn.dart';
import '../../services/push_in/gest_push_in.dart';
import '../../vars/globals.dart';

class NotiffConsola extends StatefulWidget {

  final int isRefresh;
  const NotiffConsola({
    Key? key,
    required this.isRefresh
  }) : super(key: key);

  @override
  State<NotiffConsola> createState() => _NotiffConsolaState();
}

class _NotiffConsolaState extends State<NotiffConsola> {

  final _globals = getSngOf<Globals>();

  final Map<String, String> _lstTitles = {
    'alta' : 'Notificaciones de Alta Prioridad',
    'media': 'Notificaciones de Prioridad Media',
    'baja' : 'Notificaciones de Actualización',
  };
  late SocketConn sock;

  String _seccCurrent = 'alta';
  String _foldsCurrent = '';
  List<Map<String, dynamic>> _lstFolds = [];
  final bool _isLoadingFold = false;
  bool _isInit = false;
  int _cantRefres = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_initWidget);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    if(!_isInit) {
      _isInit = true;
      sock = context.read<SocketConn>();
    }

    if(_cantRefres != widget.isRefresh) {
      _cantRefres = widget.isRefresh;
      Future.delayed(const Duration(milliseconds: 1000), (){
        _getNotiffByFolder(_seccCurrent);
      });
    }

    return SizedBox.expand(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.04,
            color: Colors.white.withOpacity(0.1),
            padding: const EdgeInsets.all(10),
            child: _prioSeccIconsNotif()
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                top: 0, right: 10, bottom: 10, left: 10
              ),
              child: _tabsInFolders(),
            )
          )
        ],
      )
    );
  }

  /// Las pestañas para Bandeja de entrada y papelera
  Widget _tabsInFolders() {

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${_lstTitles[_seccCurrent]}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w200
              )
            ),
            const Spacer(),
            _badgedTxt(
              txt: 'Bandeja de Entrada', cant: sock.allNotif['bandeja']!, fnc: () => _changeFolder('in')
            ),
            const SizedBox(width: 10),
            _badgedTxt(
              txt: 'Papelera', cant: sock.allNotif['pap']!, fnc: () => _changeFolder('lost')
            )
          ],
        ),
        const Divider( color: Colors.grey, height: 5 ),
        Expanded(
          child: _notificaciones()
        )
      ],
    );
  }

  ///
  Widget _notificaciones() {

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 3),
      constraints: BoxConstraints.expand(
        width: MediaQuery.of(context).size.width
      ),
      child: LayoutBuilder(
        builder: (_, BoxConstraints c) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: _lstNotif(c),
              ),
              Container(
                width: c.maxWidth * 0.28, height: c.maxHeight,
                padding: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color.fromARGB(255, 73, 73, 73))
                  )
                ),
                child: _lstInFolders(c),
              )
            ],
          );
        },
      )
    );
  }

  ///
  Widget _lstNotif(BoxConstraints c) {

    return SizedBox(
      width: c.maxWidth - (c.maxWidth * 0.28), height: c.maxHeight,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _lstFolds.length,
        itemBuilder: (_, index) => _tileNotif(index)
      ),
    );
  }

  ///
  Widget _tileNotif(int index) {

    String desc = _lstFolds[index]['descrip'];
    if(desc.length >= 49) {
      desc = desc.substring(0, 38);
      desc = '$desc...';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            Texto(
              txt: '${_lstFolds[index]['sended']}', sz: 13,
              txtC: Colors.green, isFecha: true,
            ),
            Texto(
              txt: '  ${_lstFolds[index]['titulo']}', sz: 15, txtC: Colors.white,
            ),
            const SizedBox(width: 5),
            Texto(
              txt: desc, sz: 13,
              txtC: const Color.fromARGB(255, 136, 136, 136),
            ),
            if(_seccCurrent == 'alta')
              ...[
                const Spacer(),
                TextButton(
                  onPressed: (){
                    final page = context.read<PageProvider>();
                    final String t = _lstFolds[index]['titulo'];
                    if(t.contains('ASIGNADA')) {
                      page.page = Paginas.solicitudes;
                    }
                    if(t.contains('ID. #')) {
                      page.page = Paginas.solicitudesNon;
                    }
                    if(page.sttConsole == 2) {
                      page.sttConsole = 1;
                    }
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 10)
                    )
                  ),
                  child: const Texto(
                    txt: 'Procesar', sz: 14,
                    txtC: Color.fromARGB(255, 98, 146, 189),
                  ),
                ),
                const SizedBox(width: 15),
              ]
          ],
        ),
        const Divider(color: Color.fromARGB(255, 73, 73, 73), height: 5),
      ],
    );
  }

  ///
  Widget _lstInFolders(BoxConstraints c) {

    if(_isLoadingFold) {
      return _loading('Buscando...');
    }

    return SizedBox(
      width: c.maxWidth * 0.28, height: c.maxHeight,
      child: ListView(
        padding: const EdgeInsets.only(right: 15),
        children: const [
          Text(
            'Las notificaciones puestas en "BANDEJA DE ENTRADA", son aquellas que '
            'fueron recuperadas con éxito, más no pudieron procesarce correctamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 126, 126, 126),
              fontSize: 12
            )
          ),
          SizedBox(height: 8),
          Text(
            'Notificaciones puestas en "PAPELERA", son todas aquellas que '
            'no pudieron ser recuperadas desde el servidor HARBI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 104, 104, 104),
              fontSize: 12
            )
          ),
        ],
      ),
    );
  }

  ///
  Widget _loading(String txt) {

    return SizedBox.expand(
      child: Row(
        children: [
          const SizedBox(
            height: 100, width: 100,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 5),
          Text(
            txt, textScaleFactor: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _prioSeccIconsNotif() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ico(ico: Icons.priority_high, fnc: () => _changeSecc('alta')),
        _ico(ico: Icons.online_prediction_rounded, fnc: () => _changeSecc('media')),
        _ico(ico: Icons.low_priority_outlined, fnc: () => _changeSecc('baja')),
      ],
    );
  }

  ///
  Widget _badgedTxt
    ({required String txt, required String cant, required Function fnc})
  {

    Color color = const Color.fromARGB(255, 39, 39, 39);
    Color colorB = color;

    if(txt.startsWith('Bandeja')) {
      if(sock.allNotif['bandeja'] != '0') {
        colorB= Colors.red;
      }
      if(_foldsCurrent == 'in') {
        color = Colors.blue;
      }
    }

    if(txt.startsWith('Papelera')) {
      if(sock.allNotif['pap'] != '0') {
        colorB= Colors.red;
      }
      if(_foldsCurrent == 'lost') {
        color = Colors.blue;
      }
    }

    return Row(
      children: [
        TextButton(
          onPressed: () => fnc(),
          child: Text(
            txt,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.05,
              color: color
            )
          )
        ),
        const SizedBox(width: 3),
        _badged(
          cant: cant, colorBg: colorB, colorTx: (cant != '0') ? Colors.white : color
        ),
      ],
    );
  }

  ///
  Widget _ico({required IconData ico, required Function fnc}) {

    Color color = const Color.fromARGB(255, 59, 59, 59);
    Color colorB = color;
    
    String cant = '0';
    if(ico == Icons.priority_high) {
      if(sock.allNotif['alta'] != '0') {
        colorB = Colors.red;
        cant = sock.allNotif['alta']!;
      }
      if(_seccCurrent == 'alta') {
        color = const Color.fromARGB(255, 255, 255, 255);
      }
    }

    if(ico == Icons.online_prediction_rounded) {
      if(sock.allNotif['media'] != '0') {
        colorB = Colors.red;
        cant = sock.allNotif['media']!;
      }
      if(_seccCurrent == 'media') {
        color = const Color.fromARGB(255, 255, 255, 255);
      }
    }

    if(ico == Icons.low_priority_outlined) {
      if(sock.allNotif['baja'] != '0') {
        colorB = Colors.red;
        cant = sock.allNotif['baja']!;
      }
      if(_seccCurrent == 'baja') {
        color = const Color.fromARGB(255, 255, 255, 255);
      }
    }
    
    return SizedBox(
      child: Stack(
        children: [
          IconButton(
            onPressed: () => fnc(),
            padding: const EdgeInsets.symmetric(horizontal: 0),
            visualDensity: VisualDensity.compact,
            icon: Icon(ico, color: color)
          ),
          Positioned(
            top: 0, right: 0,
            child: _badged(
              cant: cant, colorBg: colorB, colorTx: (cant != '0') ? Colors.white : color
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _badged({required String cant, required Color colorTx, required Color colorBg}) {

    const double radius = 15;
    return Container(
      width: radius, height: radius,
      decoration: BoxDecoration(
        color: colorBg,
        borderRadius: BorderRadius.circular(radius)
      ),
      child: Center(
        child: Text(
          cant, 
          textScaleFactor: 1,
          style: TextStyle(
            fontWeight: FontWeight.w300,
            color: colorTx,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  ///
  void _changeSecc(String secc) async {
    _lstFolds = [];
    await _getNotiffByFolder(secc);
  }

  ///
  void _changeFolder(String fold) {
    setState(() {
      _foldsCurrent = fold;
    });
  }

  ///
  Future<void> _initWidget(_) async {

    if(sock.allNotif['alta'] != '0') {
      _getNotiffByFolder('alta');
      _seccCurrent = 'alta';
    }
  }

  ///
  Future<void> _getNotiffByFolder(String folder) async {

    final gest = GestPushIn(socket: sock, user: _globals.user);
    _lstFolds = gest.getNotifByFolder(folder);
    _seccCurrent = folder;
    if(mounted) { setState(() {}); }
  }
}