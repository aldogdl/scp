enum Operadores {
  harbi
}

class LogsEntity {

  int timeIni = 0;
  int timeFin = 0;
  String task = '';
  String msgR = '';
  String func = '';
  String call = '';

  ///
  Map<String, dynamic> toJson() {

    int duracion = timeFin - timeIni;
    DateTime hoy = DateTime.fromMillisecondsSinceEpoch(timeFin);

    return {
      'created' : '[${hoy.day}-${hoy.month}]',
      'time' : '[${duracion/1000} Seg]',
      'task' : task,
      'msgR' : msgR,
      'func' : func,
      'call' : call
    };
  }

  ///
  String toFile() {

    int duracion = timeFin - timeIni;
    DateTime hoy = DateTime.now();
    return '<$call> [${hoy.day}-${hoy.month}][${duracion/1000} Seg] :: ${task.toUpperCase()} -> ${msgR.toUpperCase()} ($func)';
  }

  String ok() => 'hecho';
  String toError(String err) => '[error]->$err';
}