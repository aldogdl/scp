import 'package:intl/intl.dart' as intl;
import 'commands.dart';
import 'get_path_images.dart';

class InventarioService { 

  static get cmds => commands;

  /// Desmenusamos el comando recibido por parametro
  static Map<String, dynamic> spell(String cmd) {
    
    // El tipo indica si se solicita un proceso o si se esta buscando algo
    String comm = cmd.trim().toLowerCase();
    bool isAll = false;
    
    if(comm.startsWith('t')) {
      isAll = true;
      comm = comm.replaceFirst('t', '');
      comm = comm.trim().toLowerCase();
    }
    
    List cmms = comm.split('.');
    String command = '${cmms.first}';
    String eval = '${cmms.last}';
    if(!cmds.containsKey(command)) {
      // El comando no existe
      return {
        'err': 'El comando no existe',
        'cmd' : command
      };
    }

    // Comandos especiales
    if(command == 'vd') {
      var copy = Map<String, dynamic>.from(cmds[command]);
      cmms.removeAt(0);
      copy['eval'] = cmms.join('.');
      copy['val'] = 'subCmd';
      return copy;
    }

    if(command == 'rfs') {
      var copy = Map<String, dynamic>.from(cmds[command]);
      cmms.removeAt(0);
      copy['eval'] = '0';
      copy['val'] = 'subCmd';
      return copy;
    }

    String tipo = 'proceso';
    if(eval.startsWith(RegExp(r'[a-z]'))) { tipo = 'buscador'; }
    if(eval.startsWith(RegExp(r'[1-9]'))) { tipo = 'proceso'; }
    cmms = [];

    if(tipo == 'proceso') {

      // Se espera que el valor sea numerico.
      int? valor = int.tryParse(eval);
      if(valor == null) {
        return {
          'err': 'Se espera un valor de tipo numérico',
          'cmd' : command
        };
      }

      var copy = Map<String, dynamic>.from(cmds[command]);
      copy['eval'] = valor;
      copy['tipo'] = tipo;
      if(isAll) {
        copy['all'] = isAll;
      }
      return copy;

    }else{

      var copy = Map<String, dynamic>.from(cmds[command]);
      copy['eval'] = eval;
      copy['tipo'] = tipo;
      if(isAll) {
        copy['all'] = isAll;
      }
      return copy;
    }
    
  }

  /// Ordenamos los costos y sacamos los mejores 3
  static List<Map<String, dynamic>> sortCotsByPrice(List<Map<String, dynamic>> cots) {

    if(cots.isEmpty) { return cots; }
    
    double dineroMax = 0.0;
    double dineroMin = 0.0;
    double dineroMed = 0.0;
    List<double> todos = [];
    List<Map<String, dynamic>> best = [];

    for (var i = 0; i < cots.length; i++) {
      todos.add(_toDouble('${cots[i]['r_costo']}'));
    }

    todos.sort();
    final tot = todos.reduce((value, element) => value + element);
    dineroMax = todos.last;
    dineroMed = tot/todos.length;
    dineroMin = todos.first;

    // Buscando la cotizacion que mas se aproxime a la media
    double medMin = 0.0;
    double medMax = 0.0;
    final menores = todos.where((element) => element < dineroMed).toList();
    final mayores = todos.where((element) => element > dineroMed).toList();
    menores.sort();
    mayores.sort();
    medMin = (menores.isNotEmpty) ? menores.last : todos.first;
    medMax = (mayores.isNotEmpty) ? menores.first : todos.last;

    // Calcular cual de los dos numeros esta mas cerca de la media
    final resMin = dineroMed - medMin;
    final resMax = dineroMed - medMax;
    dineroMed = (resMin < resMax) ? medMin : medMax;

    final min = _extraerCotsCosto(dineroMin, cots);
    if(min.isNotEmpty) {
      final existe = best.where((element) => element['r_id'] == min['r_id']);
      if(existe.isEmpty) {
        best.add(min);
      }
    }

    if(cots.length > 3) {

      final med = _extraerCotsCosto(dineroMed, cots);
      if(med.isNotEmpty) {
        final existe = best.where((element) => element['r_id'] == med['r_id']);
        if(existe.isEmpty) {
          best.add(med);
        }
      }
      
    }else{

      final med = cots.firstWhere((e) {
        final costo = _toDouble(e['r_costo']);
        return (costo > dineroMin && costo < dineroMax);
      }, orElse: () => {});

      if(med.isNotEmpty) {
        final existe = best.where((element) => element['r_id'] == med['r_id']);
        if(existe.isEmpty) {
          best.add(med);
        }
      }
    }

    final max = _extraerCotsCosto(dineroMax, cots);
    if(max.isNotEmpty) {
      final existe = best.where((element) => element['r_id'] == max['r_id']);
      if(existe.isEmpty) {
        best.add(max);
      }
    }

    return best;
  }

  /// Ordenamos los costos y sacamos los mejores 3
  static List<Map<String, dynamic>> sortCotsByPriceMinToMax(List<Map<String, dynamic>> cots) {

    if(cots.isEmpty) { return cots; }

    List<double> todos = [];
    List<Map<String, dynamic>> sort = [];
    
    for (var i = 0; i < cots.length; i++) {
      final costo = _toDouble('${cots[i]['r_costo']}');
      if(!todos.contains(costo)) {
        todos.add(costo);
      }
    }
    todos.sort();
    for (var i = 0; i < todos.length; i++) {
      final results = cots.where((element) {
        double? origin = double.tryParse('${element['r_costo']}');
        return (origin == todos[i]) ? true : false;
      }).toList();
      if(results.isNotEmpty) {
        sort.addAll(results);
      }
    }
    return sort;
  }

  ///
  static Map<String, dynamic> _extraerCotsCosto
    (double costo, List<Map<String, dynamic>> cots)
  {

    List<int> ids = [];
    var has = cots.where((resp) => _toDouble('${resp['r_costo']}') == costo).toList();
    if(has.isNotEmpty) {
      if(has.length > 2) {
        for (var i = 0; i < has.length; i++) {
          ids.add(has[i]['r_id']);
        }
        ids.sort();
        has = has.where((resp) => resp['r_id'] == ids.first).toList();
      }
      return has.first;
    }

    return {};
  }

  ///
  static double _toDouble(String val) {

    var current = double.tryParse(val);
    return current ??= 0.0;
  }

  ///
  static String calcUtilidad(String precio, String costo) {

    double? prec = 0.0;
    double? cost = 0.0;
    if(precio.runtimeType == String) {
      if(precio != '0') {
        prec = double.tryParse(precio);
        prec = prec ??= 0.0; 
      }
    }
    if(costo.runtimeType == String) {
      if(costo != '0') {
        cost = double.tryParse(costo);
        cost = cost ??= 0.0; 
      }
    }

    return toFormat('${ (prec-cost) }');
  }

  /// 
  static String toFormat(String number) {

    double? numero = 0.0;
    if(number.runtimeType == String) {
      if(number != '0') {
        numero = double.tryParse(number);
        numero = numero ??= 0.0; 
      }
    }
    return intl.NumberFormat.currency(locale: 'en_US', customPattern: '\$ #,###.##').format(numero);
  }

  ///
  static Future<String> getPathImage(String foto) async {

    if(foto.startsWith('http')) {
      return foto;
    }else{
      return await GetPathImages.getPathCots(foto);
    }
  }


}