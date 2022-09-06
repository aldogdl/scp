import 'package:scp/src/entity/empres_entity.dart';

class ContactoEntity {

  int id = 0;
  int empresaId = 0;
  String curc = '';
  List<String> roles = [];
  String password = '';
  String nombre = '';
  String tkServ = '';
  bool isCot = false;
  String cargo = '';
  String celular = '';
  EmpresaEntity? emp;

  ///
  Map<String, dynamic> toJson() {

    return {
      'id': id,
      'empresaId': empresaId,
      'curc': curc,
      'roles': roles,
      'password': (password.isEmpty) ? '1234567' : password,
      'nombre': nombre,
      'isCot': isCot,
      'cargo': cargo,
      'celular': celular,
      'empresa': (emp != null) ? emp!.toJson() : {}
    };
  }

  ///
  Map<String, dynamic> toJsonForUpdateHarbi() {

    return {
      'idC' : id,
      'nombre' : nombre, 
      'password' : password, 
      'curc' : curc,
      'roles' : roles
    };
  }

  ///
  Map<String, dynamic> toJsonForAdminUser() {
    
    return {
      'id': id,
      'empresaId': 1,
      'curc': curc,
      'roles': roles,
      'password': (password.isEmpty) ? '1234567' : password,
      'nombre': nombre,
      'isCot': false,
      'cargo': cargo,
      'celular': celular,
    };
  }

  /// Este metodo es usado para hidratar la variable de globals es solo para
  /// los usuarios que estan usando esta app.
  void fromFile(Map<String, dynamic> user) {
    id = user['id'];
    curc = user['curc'];
    roles = List<String>.from(user['roles']);
    password = user['password'];
    nombre = user['nombre'];
    tkServ = user['tkServ'];
  }

  Map<String, dynamic> userToJson() {
    return {
      'id': id,
      'curc': curc,
      'roles': roles,
      'password': password,
      'nombre': nombre,
      'tkServ': tkServ,
    };
  }

  Map<String, dynamic> userConectado({
    required String app, required String ip, required String idCon
  }) {
    return {
      'ip': ip,
      'app':app,
      'id': id,
      'idCon': idCon,
      'curc': curc,
      'roles': roles,
      'name': nombre,
      'pass': password,
    };
  }

  ///
  void fromFrmToList(Map<String, dynamic> dataFrm) {

    Map<String, dynamic> data = (dataFrm.containsKey('contacto'))
      ? dataFrm['contacto'] : dataFrm;

    id = data['id'];
    curc = data['curc'];
    roles = data['roles'];
    password = data['password'];
    nombre = data['nombre'];
    isCot = data['isCot'];
    cargo = data['cargo'];
    celular = data['celular'];
    if(dataFrm.containsKey('empresa')) {

      final empObj = EmpresaEntity();
      empObj.fromFrmToList(dataFrm['empresa']);
      emp = empObj;
      empresaId = emp!.id;
    }else{
      empresaId = dataFrm['empresaId'];
    }
    data = {}; dataFrm = {};
  }

  ///
  void fromServerWidtEmpresa(Map<String, dynamic> data) {

    id = data['c_id'];
    empresaId = data['e_id'];
    curc = data['c_curc'];
    roles = List<String>.from(data['c_roles']);
    password = '';
    nombre = data['c_nombre'];
    isCot = data['c_isCot'];
    cargo = data['c_cargo'];
    celular = data['c_celular'];
    final empObj = EmpresaEntity();
    empObj.fromServer(data);
    emp = empObj;
  }

}