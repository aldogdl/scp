import 'package:flutter/material.dart' show FocusNode;
import '../entity/contacto_entity.dart';

class Globals {

  String verApp = '1.4.5';
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
  
  final List<String> origenCar = ['NACIONAL', 'IMPORTADO'];
  final List<String> posic = ['DELANTERA', 'TRASERA', 'LATERAL', 'SUPERIOR', 'CENTRAL', 'MOTOR', 'SUSPENSION'];
  final List<String> lugar = ['IZQUIERDO', 'DERECHO', 'CENTRAL', 'SUPERIOR', 'INFERIOR'];
  final Map<String, dynamic> lugAbr = {
    'IZQUIERDO':'IZQ.', 'DERECHO':'DER.', 'CENTRAL':'CEN.', 'SUPERIOR':'SUP.', 'INFERIOR':'INF.',
    'DELANTERA': 'DEL.', 'TRASERA': 'TRAS.', 'LATERAL': 'LAT.', 'SUSPENSION': 'SUSP.'
  };
  final List<String> origenes = ['SEMINUEVA Original', 'GENÉRICA nueva', 'CUALQUIER Orígen'];
  final List<String> conjunciones = ['DE', 'DEL', 'LA', 'EL', 'LOS', 'LAS', 'PARA'];
}