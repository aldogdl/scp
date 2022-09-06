enum OrdCamp { filename, metrik, emisor, isVista, orden, piezas, resps, respToSolz }

class OrdenEntity {

  int id = 0;
  int mkId = 0;
  int mdId = 0;
  int uId = 0;
  int eId = 0;
  String est = '';
  String stt = '';
  int anio = 0;
  String mkLogo = '';
  String marca = '';
  String grupo = 'c';
  String modelo = '';
  bool isNac = true;
  String own = '';
  String cargo = '';
  String celular = '0';
  String empresa = '';
  String createdAt = '';
  List<String> roles = [];
  int cantPzas = 0;

  ///
  void fromArrayServer(Map<String, dynamic> data) {

    if(data.containsKey('o_id')) {
      fromServer(data);
      return;
    }
    id = data['id'];
    mkId = data['marca']['id'];
    mdId = data['modelo']['id'];
    uId = data['own']['id'];
    eId = data['own']['empresa']['id'];
    est = data['est'];
    stt = data['stt'];
    anio = data['anio'];
    mkLogo = data['marca']['logo'];
    grupo = (data['marca']['grupo'].isEmpty) ? 'c' : data['marca']['grupo'];
    marca = data['marca']['nombre'];
    modelo = data['modelo']['nombre'];
    isNac = data['isNac'];
    own = data['own']['nombre'];
    cargo = data['own']['cargo'];
    celular = data['own']['celular'];
    empresa = data['own']['empresa']['nombre'];
    createdAt = data['createdAt']['date'];
    roles = List<String>.from(data['own']['roles']);
    if(data.containsKey('piezas')) {
      cantPzas = data['piezas'].length;
    }
  }

  ///
  void fromServer(Map<String, dynamic> data) {

    if(data.containsKey('marca')) {
      fromArrayServer(data);
      return;
    }
    id = data['o_id'];
    mkId = data['mk_id'];
    mdId = data['md_id'];
    uId = data['u_id'];
    eId = data['e_id'];
    est = data['o_est'];
    stt = data['o_stt'];
    anio = data['o_anio'];
    mkLogo = data['mk_logo'];
    marca = data['mk_nombre'];
    modelo = data['md_nombre'];
    isNac = data['o_isNac'];
    own = data['u_nombre'];
    cargo = data['u_cargo'];
    celular = data['u_celular'];
    empresa = data['e_nombre'];
    createdAt = data['o_createdAt']['date'];
    roles = List<String>.from(data['u_roles']);
  }

  ///
  void fromFile(Map<String, dynamic> json) {

    id = json['o_id'];
    mkId = json['mk_id'];
    mdId = json['md_id'];
    uId = json['u_id'];
    eId = json['e_id'];
    est = json['o_est'];
    stt = json['o_stt'];
    anio = json['o_anio'];
    mkLogo = json['mk_logo'];
    marca = json['mk_nombre'];
    modelo = json['md_nombre'];
    isNac = json['o_isNac'];
    own = json['u_nombre'];
    cargo = json['u_cargo'];
    celular = json['u_celular'];
    empresa = json['e_nombre'];
    createdAt = json['o_createdAt'];
    roles = List<String>.from(json['u_roles']);
  }

  ///
  Map<String, dynamic> toJson() {

    return {
      'o_id': id,
      'mk_id': mkId,
      'md_id': mdId,
      'u_id': uId,
      'e_id': eId,
      'o_est': est,
      'o_stt': stt,
      'o_anio': anio,
      'p_cant': cantPzas,
      'mk_logo': mkLogo,
      'mk_nombre': marca,
      'md_nombre': modelo,
      'o_isNac': isNac,
      'u_nombre': own,
      'u_cargo': cargo,
      'u_celular': celular,
      'e_nombre': empresa,
      'o_createdAt': createdAt,
      'u_roles': roles
    };
  }

  ///
  Map<String, dynamic> status() => {'est': est, 'stt':stt};
}