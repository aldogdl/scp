import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/providers/invirt_provider.dart';

import '../../../services/inventario_service.dart';
import '../texto.dart';

class CarritoSeccFinanzas extends StatefulWidget {
  const CarritoSeccFinanzas({Key? key}) : super(key: key);

  @override
  State<CarritoSeccFinanzas> createState() => _CarritoSeccFinanzasState();
}

class _CarritoSeccFinanzasState extends State<CarritoSeccFinanzas> {

  final _keyFrm = GlobalKey<FormState>();
  final _ctrDesc = TextEditingController();

  double _subTo = 0.0;
  double _iva = 0.0;
  double _desc = 0.0;
  double _dely = 0.0;
  double _delyValue = 0.0;
  double _tot = 0.0;
  double _mtoMin = 0.0;
  bool _aplyDelivery = true;
  bool _isInit = false;
  late InvirtProvider _invProv;

  @override
  void initState() {

    _subTo = 0;
    _delyValue = 350;
    _mtoMin = 1500;
    _dely = _delyValue;
    super.initState();
  }

  @override
  void dispose() {
    
    _ctrDesc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      _invProv = context.read<InvirtProvider>();
    }

    double w = MediaQuery.of(context).size.width;

    return Container(
      constraints: BoxConstraints.expand(
        width: w * 0.25
      ),
      padding: const EdgeInsets.all(10),
      color: Colors.white10,
      child: Column(
        children: [
          Selector<InvirtProvider, bool>(
            selector: (_, prov) => prov.recalcular,
            builder: (_, make, __) {
              return FutureBuilder(
                future: _recalcular(),
                builder: (_, AsyncSnapshot snap) => _numeros()
              );
            },
          ),
          CheckboxListTile(
            contentPadding: const EdgeInsets.all(0),
            value: _aplyDelivery,
            title: const Texto(
              txt: 'Aplicar Delivery:',
            ),
            subtitle: Texto(
              txt: '[ ${(_subTo >= _mtoMin) ? "NO":"SÍ"} ]. Monto mínimo ${InventarioService.toFormat('$_mtoMin')}',
              sz: 12,
            ),
            activeColor: Colors.black,
            onChanged: (val) {
              _dely = (val ?? false) ? _delyValue : 0;
              _aplyDelivery = val ?? false;
              _refresh();
            }
          ),
          _fieldDesc(),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red)
            ),
            onPressed: (){},
            child: const Texto(txt: 'Enviar al Cliente', txtC: Colors.white)
          )
        ],
      ),
    );
  }

  ///
  Widget _numeros() {

    return Column(
      children: [
        _row('Sub-Total', '$_subTo'),
        _row('I.V.A.', '$_iva'),
        _row('Delivery', '$_dely'),
        _row('Descuento', '$_desc'),
        const SizedBox(height: 5),
        const Divider(height: 1, color: Colors.black),
        const Divider(height: 2,),
        const SizedBox(height: 5),
        _row('TOTAL', '$_tot', isActive: true),
      ],
    );
  }

  ///
  Widget _row(String label, String value, {bool isActive = false}) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Texto(
            txt: '$label:',
            txtC: (isActive) ? Colors.white : const Color.fromARGB(255, 158, 158, 158),
          ),
          const Spacer(),
          Texto(
            txt: InventarioService.toFormat(value),
            txtC: (isActive) ? Colors.white : const Color.fromARGB(255, 158, 158, 158),
          ),
        ],
      ),
    );
  }

  ///
  Widget _fieldDesc() {

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 35,
      child: Row(
        children: [
          const Texto(
            txt: 'Descuento \$:'
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Form(
              key: _keyFrm,
              child: TextFormField(
                controller: _ctrDesc,
                onEditingComplete: () => _refresh(),
                validator: (val) {

                  if(val == null || val.isEmpty){ return null; }

                  String valor = ( val.contains('%') )
                    ? val.replaceAll('%', '').trim() : val.trim();
                  double? prueba = double.tryParse(valor);

                  if(prueba == null) {
                    return 'Dato Incorrecto';
                  }else{
                    if(val.contains('%')) {
                      if(prueba >= 100) {
                        return 'Porcentaje alto';
                      }
                    }else{
                      if(prueba >= _tot) {
                        return 'Dato Incorrecto';
                      }
                    }
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                    left: 5, right: 0, top: 3, bottom: 3
                  ),
                  prefixIcon: const Icon(Icons.sell, size: 15, color: Colors.blue),
                  errorStyle: const TextStyle(
                    color: Colors.amber
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    maxWidth: 30
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _refresh(),
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(Icons.calculate, size: 18)
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue)
                  )
                ),
              ),
            ),
          ),
        ],
      )
    );
  }

  ///
  double _getSubTotalOrigin() {

    double ft = 0;
    _invProv.costosSel.forEach((idPz, costo) {
      ft = ft + double.parse(costo['r_costo']);
    });
    return ft;
  }

  ///
  Future<void> _recalcular() async {

    _subTo = _getSubTotalOrigin();
    double? descVal = 0;
    final subTorigin = _getSubTotalOrigin();

    if(_ctrDesc.text.isNotEmpty) {
      if(_ctrDesc.text.contains('%')) {
        String desc = '';
        desc = _ctrDesc.text.replaceAll('%', '').trim();
        descVal = double.tryParse(desc);
        if(descVal != null && descVal > 0) {
          _desc = subTorigin * (descVal/100);
          _subTo = subTorigin - _desc;
        }else{
          _desc = subTorigin;
          _subTo = _desc;
        }
      }else{

        descVal = double.tryParse(_ctrDesc.text.trim());
        if(descVal != null && descVal > 0) {
          _desc = descVal;
        }else{
          _desc = 0;
        }
      }
    }
    
    _iva = _subTo * 0.16;
    _tot = (_subTo + _iva + _dely) - _desc;
    if(_ctrDesc.text.isNotEmpty) {
      Future.microtask(() {
        _ctrDesc.text = '';
      });
    }
  }

  ///
  void _refresh() {
    if(mounted) {
      Future.microtask(() => setState(() {}));
    }
  }
}