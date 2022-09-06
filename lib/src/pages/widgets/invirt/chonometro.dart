import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/pages/widgets/invirt/tile_resps_cant.dart';
import 'package:scp/src/repository/inventario_repository.dart';

import '../../../providers/invirt_provider.dart';
import '../../widgets/texto.dart';

class Chonometro extends StatefulWidget {

  final String filename;
  final String created;
  final int idOrd;
  final int nPzas;
  const Chonometro({
    Key? key,
    required this.filename,
    required this.created,
    required this.idOrd,
    required this.nPzas,
  }) : super(key: key);

  @override
  State<Chonometro> createState() => _ChonometroState();
}

class _ChonometroState extends State<Chonometro> {

  final _invEm = InventarioRepository();
  late InvirtProvider _invProv;
  
  static const Color _inTime = Color.fromARGB(255, 65, 65, 65);
  static const Color _alert  = Color.fromARGB(255, 17, 219, 10);
  static const Color _warning= Color.fromARGB(255, 255, 164, 121);

  static const IconData _icoAlertInTime = Icons.timer_sharp;
  static const IconData _icoAlertAlert  = Icons.warning_amber;
  static const IconData _icoAlertwarning= Icons.disabled_visible_rounded;

  IconData _icoAlert = Icons.timer_sharp;
  Color _icoAlertColor = const Color.fromARGB(255, 65, 65, 65);

  Duration duration = const Duration();
  Timer? timer;
  bool _isInit = false;
  bool _isPaused = false;
  bool _showWidget = false;
  bool _showCron = false;
  String _tipAlert = '';

  late Future<void> _initialice;

  @override
  void initState() {
    _tipAlert = 'Sin Respuestas aún...';
    _reset();
    _initialice = _iniWidget();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    // _invProv.cronos.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Se realiza aqui el _iniWidget, ya que este widget es cargado inicialmente
    // con ordenes que contienen valores nulos, y hasta recibir valores validos este
    // widget deja de renderizarce.
    // if(!_isInit) { _iniWidget(); }

    return (!_showWidget)
      ? _load()
      : FutureBuilder(
        future: _initialice,
        builder: (_, __) => _body(),
      );
  }

  ///
  Widget _load() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          height: 10, width: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
        SizedBox(width: 10),
        Texto(txt: 'Analizando...', sz: 11, txtC: Colors.amber)
      ],
    );
  }

  ///
  Widget _body() {

    Widget sbw(double w) => SizedBox(width: w);

    if(!_showCron) {
      return _sensorDeCambios();
    }

    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final circle  = (int.parse(seconds) * 1) / 60;

    return Row(
      children: [
        _icoBtnAcc(
          tip: 'Reiniciar Cronometro', fnc: () => _reset(andInit: true),
          ico: Icons.restore, color: Colors.orange
        ),
        sbw(8),
        SizedBox(
          width: 13, height: 13,
          child: CircularProgressIndicator(
            value: circle,
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            backgroundColor: const Color.fromARGB(255, 19, 19, 19),
            color: const Color.fromARGB(255, 19, 19, 19)
          ),
        ),
        sbw(8),
        Texto(txt: minutes, sz: 13),
        const Texto(txt: ':', sz: 13),
        Texto(txt: seconds, sz: 13),
        sbw(8),
        _icoBtnAcc(
          tip: (_isPaused) ? 'Reanudar Conteo' : 'Pausar Cronómetro',
          fnc: () => _pausaPlayCron(),
          ico: (_isPaused) ? Icons.play_arrow : Icons.pause,
          color: (_isPaused) ? Colors.blue : Colors.red
        ),
        sbw(8),
        TileRespsCant(filename: widget.filename, idOrd: widget.idOrd, from: 'cron'),
        sbw(10),
        Tooltip(
          message: _tipAlert,
          child: Icon(_icoAlert, size: 15, color: _icoAlertColor),
        )
      ],
    );
  }

  ///
  Widget _sensorDeCambios() {

    return Selector<InvirtProvider, List<int>>(
      selector: (_, prov) => prov.trigger,
      builder: (_, idOrds, child) {

        if(idOrds.contains(widget.idOrd)) {
          if(mounted) {
            Future.microtask(() async {
              await _iniWidget();
            });
          }
        }
        return child!;
      },
      child: Row(
        children: [
          Texto(txt: _tipAlert, sz: 13),
          const SizedBox(width: 5),
          Icon(_icoAlert, size: 15, color: _icoAlertColor)
        ],
      ),
    );
  }

  ///
  Widget _icoBtnAcc
    ({ required IconData ico, required Function fnc, required Color color,
    required String tip })
  {

    return MouseRegion(
      child: IconButton(
        icon: Icon(ico, size: 15, color: color),
        iconSize: 15,
        onPressed: () => fnc(),
        tooltip: tip,
        padding: const EdgeInsets.all(0),
        constraints: const BoxConstraints(
          maxWidth: 40, maxHeight: 18, minWidth: 30
        ),
      ),
    );
  }

  ///
  String twoDigits(int n) => n.toString().padLeft(2,'0');

  ///
  void _pausaPlayCron() {

    if(_isPaused) {
                
      _invProv.cronos[widget.idOrd]['pausa'] = false;
      startTimer();
      setState(() => _isPaused = false);

    }else{

      _isPaused = true;
      _invProv.cronos[widget.idOrd]['timer'] = DateTime.now().toIso8601String();
      _invProv.cronos[widget.idOrd]['pausa'] = _isPaused;
      stopTimer(resets: false);
    }
  }

  ///
  Future<void> _iniWidget() async {

    if(!_isInit) {
      _isInit = true;
      _invProv = context.read<InvirtProvider>();
    }

    if(widget.idOrd == 0) { return; }
        
    Map<String, dynamic> metrix = await _invEm.getMetriksFromFile(widget.filename);
    
    if(metrix['rsp'] > 0) {

      await _calcularCron(metrix);
    }else{

      final instante = DateTime.now();
      DateTime quedeEn = DateTime.parse(widget.created);
      final diff = instante.difference(quedeEn);
      duration = _calcularRetrazo(diff, quedeEn.minute, quedeEn.second);
      
      if(_tipAlert.contains('día')) {
        String aviso = 'AVISO';
        if(diff.inDays == 2) { aviso = 'ALERTA'; }
        if(diff.inDays > 2) { aviso = 'PELIGRO'; }
        _tipAlert = _formatTip('${diff.inDays}', aviso);
      }
      duration = const Duration();
      if(mounted) {
        setState(() { _showWidget = true; });
      }
    }
  }

  ///
  String _formatTip(String l, String a) => 'Hán pasado $l día(s) [$a].';
  
  ///
  Future<void> _calcularCron(Map<String, dynamic> metrix) async {

    _isPaused = false;
    bool hasTimer = false;
    duration = const Duration();

    final instante = DateTime.now();
    var elCron = Map<String, dynamic>.from(metrix[Mtrik.cron.name]);
    if(elCron.isEmpty) {
      elCron = _invEm.getSchemaCron(widget.filename, instante.minute, instante.second);
    }else{
      if(!elCron.containsKey('filename')) {
        elCron['filename'] = widget.filename;
      }
    }

    if(_invProv.cronos.isNotEmpty) {
      // Si existe lo actualizo
      if(_invProv.cronos.containsKey(widget.idOrd)) {
        _invProv.cronos[widget.idOrd] = elCron;
        hasTimer = true;
      }
    }

    if(!hasTimer) {
      _invProv.cronos.putIfAbsent(widget.idOrd, () => elCron);
    }

    DateTime quedeEn = DateTime.parse(_invProv.cronos[widget.idOrd]['timer']);

    if(_invProv.cronos[widget.idOrd]['pausa']) {
      // Debo actualizar el dia y la hora y quedarme en el mismo min. y seg.
      // que cuando pause.
      quedeEn = DateTime.parse(
        '${instante.year}-${"${instante.month}".padLeft(2, '0')}-${"${instante.day}".padLeft(2, '0')} '
        '${"${instante.hour}".padLeft(2, '0')}:${"${_invProv.cronos[widget.idOrd]['min']}".padLeft(2, '0')}:${"${_invProv.cronos[widget.idOrd]['seg']}".padLeft(2, '0')}'
      );
      _invProv.cronos[widget.idOrd]['timer'] = quedeEn.toIso8601String();
      _isPaused = true;
      duration = Duration(
        minutes: _invProv.cronos[widget.idOrd]['min'],
        seconds: _invProv.cronos[widget.idOrd]['seg']
      );
      await _analizarArranque(metrix);
      return;
    }

    duration = _calcularRetrazo(
      instante.difference(quedeEn),
      _invProv.cronos[widget.idOrd]['min'], _invProv.cronos[widget.idOrd]['seg']
    );

    _invProv.cronos[widget.idOrd]['pausa'] = _isPaused;

    await _analizarArranque(metrix);
  }

  /// Calculamos el retrazo e indicamos desde donde poder comenzar a contar
  Duration _calcularRetrazo(Duration diff, int min, int seg) {

    final hoy = DateTime.now();
    int min = hoy.minute;
    int seg = hoy.second;

    if(_invProv.cronos.isNotEmpty) {
      if(_invProv.cronos.containsKey(widget.idOrd)) {
        min = _invProv.cronos[widget.idOrd]['min'];
        seg = _invProv.cronos[widget.idOrd]['seg'];
      }
    }
    if(diff.inDays == 0) {
      if(diff.inHours == 0) {

        final minDiff = diff.inMinutes;

        if(minDiff < min) {
          min = min - minDiff;
          seg = seg;
          _icoAlert = _icoAlertInTime;
          _icoAlertColor = _inTime;
        }else{
          
          _tipAlert = 'Ya pasó más de ${_invEm.conteo} minútos.';
          _icoAlert = _icoAlertAlert;
          _icoAlertColor = _alert;
          _isPaused = true;
        }

      }else{

        _tipAlert = 'Ya pasáron ${diff.inHours} hora(s)';
        _icoAlert = _icoAlertAlert;
        _icoAlertColor = _alert;
        _isPaused = true;
      }

    }else{

      _tipAlert = 'Ya pasó más de un día.';
      _icoAlert = _icoAlertwarning;
      _icoAlertColor = _warning;
      _isPaused = true;
    }

    return Duration(minutes: min, seconds: seg);
  }

  ///
  Future<void> _analizarArranque(Map<String, dynamic> metrix) async {

    int? pzas = int.tryParse('${metrix[Mtrik.pzas.name]}');
    int? rsp = int.tryParse('${metrix[Mtrik.rsp.name]}');

    if(rsp != null && pzas != null) {
      if(metrix[Mtrik.rsp.name] == 0) {
        if(pzas == 1 && rsp > 0) {
          // comparar el tiempo, si ya paso a los 30 min. pasar a proceso.
        }

        if(pzas > 1 && rsp > 0) {
          // Necesitamos ver si por lo menos cada pza cuenta con una respuesta
        }

        if(rsp == 0) {
          // comparar el tiempo, para ver si seguimos en tiempo.
        }

      }
    }

    if (!_isPaused) { startTimer(); }

    if(mounted) {
      setState(() {
        _showWidget = true;
        _showCron = true;
      });
    }
  }

  ///
  void _reset({bool andInit = false}){

    if(mounted) {
      setState(() {
        duration = Duration(minutes: _invEm.conteo);
        if(andInit) {
          stopTimer(resets: false);
          startTimer();
          _isPaused = false;
        }
      });
    }
  }

  ///
  void startTimer(){
    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());
  }

  ///
  void addTime(){

    if(mounted) {
      final seconds = duration.inSeconds + -1;
      if (seconds < 0){
        timer?.cancel();
      } else{
        final min = twoDigits(duration.inMinutes.remainder(60));
        final seg = twoDigits(duration.inSeconds.remainder(60));
        _invProv.cronos[widget.idOrd] = _invEm.getSchemaCron(
          widget.filename, int.parse(min), int.parse(seg), isPause: _isPaused
        );
      }
      setState(() {
        duration = Duration(seconds: seconds);
      });
    }
  }

  ///
  void stopTimer({bool resets = true}){

    if (resets){ _reset(); }
    if(mounted) {
      setState(() => timer?.cancel());
    }
  }

}