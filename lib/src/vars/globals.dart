import 'package:flutter/material.dart' show FocusNode;
import 'package:scp/src/entity/contacto_entity.dart';

class Globals {

  String verApp = '1.0.1';
  bool isLocalConn = true;
  String wifiName = '';
  String myIp = '';
  String ipHarbi = '';
  String portHarbi = '';
  // La ultima version del centinela
  String currentVersion = '0';
  Map<String, dynamic> ipDbs = {};
  ContactoEntity user = ContactoEntity();
  FocusNode focusMain = FocusNode();
  
  List<String> posic = ['DELANTERA', 'TRASERA', 'LATERAL', 'MOTOR', 'SUSPENSION'];
  List<String> lugar = ['IZQUIERDO', 'DERECHO', 'CENTRAL', 'SUPERIOR', 'INFERIOR'];
  List<String> origenes = ['SEMINUEVA Original', 'GENÉRICA nueva', 'CUALQUIER Orígen'];
}