import 'package:scp/src/entity/empres_entity.dart';

class ContactoEntity {

  int id = 0;
  int empresaId = 0;
  String curc = '';
  List<String> roles = [];
  String password = '';
  String nombre = '';
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
  Map<String, dynamic> toJsonForAdmin(List<Map<String, dynamic>> cargos) {
    
    String role = 'ROLE_AVO';
    final strR = cargos.where((element) => element['tit'] == cargo);
    if(strR.isNotEmpty) {
      role = strR.first['role'];
    }
    return {
      'id': id,
      'empresaId': 1,
      'curc': curc,
      'roles': [role],
      'password': (password.isEmpty) ? '1234567' : password,
      'nombre': nombre,
      'isCot': false,
      'cargo': cargo,
      'celular': celular,
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