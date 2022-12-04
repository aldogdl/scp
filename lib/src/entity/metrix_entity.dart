class MetrixEntity {

  int stt = 0;
  List<int> toTot = [];
  List<int> sended = [];
  List<int> drash = [];
  int to = 0;
  int see = 0;
  int ntg = 0;
  int rsp = 0;
  int tpz = 0;
  int apr = 0;
  Map<String, dynamic> rpp = {};
  Map<String, dynamic> ntpp = {};
  Map<String, dynamic> aprp = {};
  String hIni = '0';
  String hFin = '0';

  ///
  void fromJson(Map<String, dynamic> data) {

    stt = (data.containsKey('stt')) ? data['stt'] : 3;
    toTot = (data.containsKey('toTot')) ? List<int>.from(data['toTot']) : [];
    sended = (data.containsKey('sended')) ? List<int>.from(data['sended']) : [];
    drash = (data.containsKey('sended')) ? List<int>.from(data['drash']) : [];
    to = (data.containsKey('to')) ? data['to'] : 0;
    see = (data.containsKey('see')) ? data['see'] : 0;
    ntg = (data.containsKey('ntg')) ? data['ntg'] : 0;
    rsp = (data.containsKey('rsp')) ? data['rsp'] : 0;
    tpz = (data.containsKey('tpz')) ? data['tpz'] : 0;
    rpp = (data.containsKey('rpp')) ? Map<String, dynamic>.from(data['rpp']) : {};
    ntpp = (data.containsKey('ntpp')) ? Map<String, dynamic>.from(data['ntpp']) : {};
    hIni = (data.containsKey('hIni')) ? data['hIni'] : '0';
    hFin = (data.containsKey('hFin')) ? data['hFin'] : '0';
    if(data.containsKey('apr')) {
      apr = data['apr'];
    }
    if(data.containsKey('aprp')) {
      aprp = data['aprp'];
    }
  }

  ///
  Map<String, dynamic> toJson() {

    return {
      'stt': stt,
      'toTot': toTot,
      'sended': sended,
      'drash': drash,
      'to': to,
      'see': see,
      'ntg': ntg,
      'rsp': rsp,
      'tpz': tpz,
      'rpp': rpp,
      'apr': apr,
      'aprp': aprp,
      'ntpp': ntpp,
      'hIni': hIni,
      'hFin': hFin
    };
  }
}