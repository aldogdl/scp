class OrdenEntity {

  int id = 0;
  int mkId = 0;
  int mdId = 0;
  int uId = 0;
  int eId = 0;
  String est = '';
  String stt = '';
  String ruta = '';
  int anio = 0;
  String mkLogo = '';
  String marca = '';
  String modelo = '';
  bool isNac = true;
  String own = '';
  String cargo = '';
  String celular = '0';
  String empresa = '';
  String createdAt = '';
  List<String> roles = [];

  ///
  void fromServer(Map<String, dynamic> data) {

    id = data['o_id'];
    mkId = data['mk_id'];
    mdId = data['md_id'];
    uId = data['u_id'];
    eId = data['e_id'];
    est = data['o_est'];
    stt = data['o_stt'];
    //ruta = data['o_ruta'];
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
  Map<String, dynamic> toJson() {

    return {
      'o_id': id,
      'mk_id': mkId,
      'md_id': mdId,
      'u_id': uId,
      'e_id': eId,
      'o_est': est,
      'o_stt': stt,
      'o_ruta': ruta,
      'o_anio': anio,
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
  Map<String, dynamic> status() => {'est': est, 'stt':stt, 'rta':ruta};
}