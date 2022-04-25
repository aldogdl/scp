class ScmEntity {

  int id = 0;
  bool prioridad = true;
  int acc = 0;
  String msg = '3-1'; 
  String sys = 'SCP';
  int? orden;
  int? pieza;
  int own = 0;
  int avo = 0;

  ///
  Map<String, dynamic> jsonToCotizar({
    required int idOrden,
    required int idOwn,
    required int idAvo,
    int? idReg
  }) {

    id = idReg ?? 0;
    orden = idOrden;
    own = idOwn;
    avo = idAvo;

    return {
      'id': id,
      'prioridad': prioridad,
      'acc': acc,
      'msg': msg,
      'sys': sys,
      'orden': orden,
      'pieza': pieza,
      'own': own,
      'avo': avo
    };
  }
}