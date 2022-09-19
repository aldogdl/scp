import 'package:flutter/material.dart' show FocusNode;
import '../entity/contacto_entity.dart';

class Globals {

  String verApp = '1.3.1';
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
  Map<String, dynamic> lugAbr = {
    'IZQUIERDO':'IZQ.', 'DERECHO':'DER.', 'CENTRAL':'CEN.', 'SUPERIOR':'SUP.', 'INFERIOR':'INF.'
  };
  List<String> origenes = ['SEMINUEVA Original', 'GENÉRICA nueva', 'CUALQUIER Orígen'];
}