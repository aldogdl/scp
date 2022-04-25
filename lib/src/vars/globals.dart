import 'package:flutter/material.dart' show FocusNode;

class Globals {

  bool isLocalConn = true;
  String wifiName = '';
  String myIp = '';
  String ipHarbi = '';
  String portHarbi = '';
  Map<String, dynamic> ipDbs = {};
  String tkServ = '';
  int idUser = 0;
  String curc = '';
  String password = '';
  List<String> roles = [];
  FocusNode focusMain = FocusNode();
  
  List<String> posic = ['DELANTERA', 'TRASERA', 'LATERAL', 'MOTOR', 'SUSPENSION'];
  List<String> lugar = ['IZQUIERDO', 'DERECHO', 'CENTRAL', 'SUPERIOR', 'INFERIOR'];
  List<String> origenes = ['SEMINUEVA Original', 'GENÉRICA nueva', 'CUALQUIER Orígen'];
}