import 'package:extended_image/extended_image.dart';
import 'package:flutter/widgets.dart' show GlobalKey, ChangeNotifier, ValueChanged,
Curves, Offset, Size;

import '../entity/contacto_entity.dart';
import '../entity/contacts_entity.dart';
import '../entity/orden_entity.dart';
import '../entity/piezas_entity.dart';

class ItemSelectGlobProvider extends ChangeNotifier {

  ///
  void disposeMy() {
    _idPzaSelect = -1;
    _piezas = [];
    _fotosByPiezas = [];
    gestureKey = [];
    _ordenesAsignadas = {};
    _ordenEntitySelect = null;
    _piezaSelect = null;
  }

  // ------------------ SECCION DE ASIGNACION -------------------------

  ///
  int _idOrdenSelect = -1;
  int get idOrdenSelect => _idOrdenSelect;
  set idOrdenSelect(int id) {
    _idOrdenSelect = id;
    notifyListeners();
  }

  OrdenEntity? _ordenEntitySelect;
  OrdenEntity? get ordenEntitySelect => _ordenEntitySelect;
  void setOrdenEntitySelect(OrdenEntity? orden) => _ordenEntitySelect = orden;

  ///
  int _idPzaSelect = -1;
  int get idPzaSelect => _idPzaSelect;
  set idPzaSelect(int id) {
    _idPzaSelect = id;
    notifyListeners();
  }

  ///
  List<ContactoEntity> _avos = [];
  List<ContactoEntity> get avos => _avos;
  set avos(List<ContactoEntity> avoslst) {
    _avos = avoslst;
    notifyListeners();
  }

  ///
  List<ContacsEntity> _contacts = [];
  List<ContacsEntity> get contacts => _contacts;
  set contactsOfNotified(List<ContacsEntity> contactslst) {
    _contacts = contactslst;
  }
  set contacts(List<ContacsEntity> contactslst) {
    _contacts = contactslst;
    notifyListeners();
  }

  ///
  Map<int, List<int>> _ordenesAsignadas = {};
  Map<int, List<int>> get ordenesAsignadas => _ordenesAsignadas;
  set ordenesAsignadas(Map<int, List<int>> ordenlst) {
    _ordenesAsignadas = ordenlst;
    notifyListeners();
  }

  ///
  void ordenesAsignadasInsert(int idAvo, int idOrden) {

    if(_ordenesAsignadas.containsKey(idAvo)) {
      _ordenesAsignadas[idAvo]!.insert(0, idOrden);
    }else{
      _ordenesAsignadas.putIfAbsent(idAvo, () => [idOrden]);
    }
    notifyListeners();
  }

  ///
  void ordenesAsignadasRemove(int idAvo, int idOrden) {
    if(_ordenesAsignadas.containsKey(idAvo)) {
      _ordenesAsignadas[idAvo]!.remove(idOrden);
      if(_ordenesAsignadas[idAvo]!.isEmpty) {
        _ordenesAsignadas.remove(idAvo);
      }
    }
    notifyListeners();
  }


  // ------------------ SECCION DE GENERAL -------------------------


  /// Variable usada desde la seccion de inventario virtual, para indicar
  /// que cuando se ven los datos no mostrar algunos widgets.
  bool isOnlyShow = false;
  
  ///
  List<Map<String, dynamic>> _ordenes = [];
  List<Map<String, dynamic>> get ordenes => _ordenes;
  OrdenEntity getOrden(int i) {
    OrdenEntity o = OrdenEntity();
    o.fromFile(ordenes[i][OrdCamp.orden.name]);
    return o;
  }
  set ordenes(List<Map<String, dynamic>> ordenlst) {
    _ordenes = ordenlst;
    notifyListeners();
  }

  ///
  List<PiezasEntity> _piezas = [];
  List<PiezasEntity> get piezas => _piezas;
  set piezas(List<PiezasEntity> pzas) {
    _piezas = pzas;
    notifyListeners();
  }

  /// Usada para refrescar el FRM de edicion de la orden y sus piezas
  PiezasEntity? _piezaSelect;
  PiezasEntity? get piezaSelect => _piezaSelect;
  set piezaSelect(PiezasEntity? pzas) {
    _piezaSelect = pzas;
    notifyListeners();
  }

  ///
  List<Map<String, dynamic>> _fotosByPiezas = [];
  List<Map<String, dynamic>> get fotosByPiezas => _fotosByPiezas;
  set fotosByPiezas(List<Map<String, dynamic>> fPzas) {
    _fotosByPiezas = fPzas;
    notifyListeners();
  }

  ///
  int sIniFotoW = 0;
  int sIniFotoH = 0;
  int currentPage = 0;
  List<GlobalKey<ExtendedImageGestureState>> gestureKey = [];
  
  ///
  Future<void> hidratarKeysAsFotos() async {

    if(fotosByPiezas.isEmpty){ return; }
    gestureKey.clear();
    for (var i = 0; i < fotosByPiezas.length; i++) {
      gestureKey.add(GlobalKey<ExtendedImageGestureState>());
    }
  }
  
  ///
  void sigFoto(ExtendedPageController pageCtl, ValueChanged<void> onFinish) async {

    if(fotosByPiezas.isNotEmpty) {
      await pageCtl.nextPage(
        duration: const Duration(milliseconds: 100), curve: Curves.easeIn
      );
      onFinish(null);
    }
  }

  ///
  void backFoto(ExtendedPageController pageCtl, ValueChanged<void> onFinish) async {

    if(fotosByPiezas.isNotEmpty) {
      await pageCtl.previousPage(
        duration: const Duration(milliseconds: 100), curve: Curves.easeIn
      );
      onFinish(null);
    }
  }

  ///
  void zoomFoto(Size mediaQ, double widthOfResto, ValueChanged<void> onFinish) {

    if(fotosByPiezas.isNotEmpty) {

      double nt = gestureKey[currentPage].currentState!.gestureDetails!.totalScale! + 0.5;
      gestureKey[currentPage].currentState!.gestureDetails = GestureDetails(
        actionType: ActionType.zoom,
        userOffset: true,
        offset: _calcularCentros(
          nt, gestureKey[currentPage].currentState!.gestureDetails!.offset!, true,
          mediaQ: mediaQ,
          widthOfResto: widthOfResto
        ),
        totalScale: nt
      );
      onFinish(null);
    }
  }

  ///
  void dismFoto(Size mediaQ, double widthOfResto, ValueChanged<void> onFinish) {

    if(fotosByPiezas.isNotEmpty) {

      if(gestureKey[currentPage].currentState!.gestureDetails!.totalScale! < 1) {
        gestureKey[currentPage].currentState!.reset();
        return;
      }
      double nt = gestureKey[currentPage].currentState!.gestureDetails!.totalScale! - 0.5;       
      gestureKey[currentPage].currentState!.gestureDetails=GestureDetails(
        actionType: ActionType.zoom,
        userOffset: true,
        offset: _calcularCentros(
          nt, gestureKey[currentPage].currentState!.gestureDetails!.offset!, false,
          mediaQ: mediaQ,
          widthOfResto: widthOfResto
        ),
        totalScale: nt
      );
      onFinish(null);
    }
  }

  ///
  Offset _calcularCentros(
    double nt, Offset current, bool isAdd,
    {required Size mediaQ, required double widthOfResto})
  {

    double difToCW = current.dx;
    double difToCH = current.dy;
  
    if(isAdd) {

      double w = (widthOfResto * 100) / mediaQ.width;
      double wContainer = mediaQ.width * ((100 - w) / 100);
      double hContainer = mediaQ.height;

      double cContainerW = wContainer / 2;
      double cContainerH = hContainer / 2;

      double centerImgWO = sIniFotoW / 2;
      double centerImgHO = sIniFotoW / 2;

      double centerImgW = (sIniFotoW * nt) / 2;
      double centerImgH = (sIniFotoH * nt) / 2;
      double difW = centerImgW - centerImgWO;
      double difH = centerImgH - centerImgHO;

      difToCW = cContainerW - difW;
      difToCH = cContainerH - difH;

      if(difToCW < -cContainerW) {
        difToCW = current.dx - (cContainerW * 0.5);
      }
      if(difToCH < -cContainerH) {
        difToCH = current.dy - (cContainerH * 0.5);
      }
    }
    return Offset(difToCW, difToCH);
  }

}