import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/decoration_field.dart';
import 'widgets/lst_contactos.dart';
import '../../widgets/texto.dart';
import '../../../entity/contacto_entity.dart';
import '../../../entity/empres_entity.dart';
import '../../../providers/socket_conn.dart';
import '../../../repository/contacts_repository.dart';
import '../../../services/get_content_files.dart';

class Empresas extends StatefulWidget {

  const Empresas({Key? key}) : super(key: key);
  @override
  State<Empresas> createState() => _EmpresasState();
}

class _EmpresasState extends State<Empresas> {

  final ContactsRepository _contacEm = ContactsRepository();

  final GlobalKey<FormState> _frmKey = GlobalKey<FormState>();
  final TextEditingController _nomEmpCtrl = TextEditingController();
  final TextEditingController _domicilioCtrl = TextEditingController();
  final TextEditingController _cpCtrl = TextEditingController();
  final TextEditingController _telFCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _celCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController(text: '1234567');

  final FocusNode _nomEmpFcs = FocusNode();
  final FocusNode _domicilioFcs = FocusNode();
  final FocusNode _cpFcs = FocusNode();
  final FocusNode _telFFcs = FocusNode();
  final FocusNode _cargosFcs = FocusNode();
  final FocusNode _nomFcs = FocusNode();
  final FocusNode _celFcs = FocusNode();
  final FocusNode _passFcs = FocusNode();


  late Future<void> _recuperarDatosMeta;
  ContactoEntity? _contact;
  final ValueNotifier<bool> _refreshList = ValueNotifier<bool>(false);

  List<String> cargos = [];
  List<Map<String, dynamic>> roles = [];
  bool _isLocal = true;
  bool _isCot = true;
  bool _showPass = true;
  String _cargoSelect = '';
  bool _isAbsorbing = false;
  int _idEmp = 0;
  int _idContac = 0;
  bool _isOtherContac = false;

  @override
  void initState() {
    _recuperarDatosMeta = _getDatosMeta();
    super.initState();
  }

  @override
  void dispose() {
    
    _nomEmpCtrl.dispose();
    _domicilioCtrl.dispose();
    _cpCtrl.dispose();
    _telFCtrl.dispose();
    _nomCtrl.dispose();
    _celCtrl.dispose();
    _passCtrl.dispose();
    _nomEmpFcs.dispose();
    _domicilioFcs.dispose();
    _cpFcs.dispose();
    _telFFcs.dispose();
    _nomFcs.dispose();
    _celFcs.dispose();
    _passFcs.dispose();
    _cargosFcs.dispose();
    _refreshList.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _frmKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(
                  children: [
                    const Texto(txt: 'GESTIONA DATOS EMPRESARIALES', txtC: Colors.white, isBold: true),
                    const SizedBox(height: 26),
                    const Texto(txt: 'DATOS DE LA EMPRESA', txtC: Colors.green, isBold: true),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 21),
                    _frm(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Texto(txt: 'Agregar como Nuevo Contacto?'),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(9),
                          child: Checkbox(
                            value: _isOtherContac,
                            checkColor: Colors.black,
                            onChanged: (val) => setState(() {
                              _isOtherContac = val ?? false;
                            })
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Texto(txt: 'Es local?'),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(9),
                          child: Checkbox(
                            value: _isLocal,
                            checkColor: Colors.black,
                            onChanged: (val) => setState(() {
                              _isLocal = val ?? false;
                            })
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Texto(txt: 'Es Cotizador?'),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(10),
                          child: Checkbox(
                            value: _isCot,
                            checkColor: Colors.black,
                            onChanged: (val) => setState(() {
                              _isCot = val ?? false;
                            })
                          ),
                        ),
                        const SizedBox(width: 20),
                        FocusTraversalOrder(
                          order: const NumericFocusOrder(11),
                          child: AbsorbPointer(
                            absorbing: _isAbsorbing,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                  (_isAbsorbing) ? Colors.black : Colors.blue
                                )
                              ),
                              onPressed: () => _saveData(),
                              child: const Texto(txt: 'Continuar', txtC: Colors.black)
                            ),
                          )
                        ),
                        const SizedBox(width: 10),
                        if(_isAbsorbing)
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(),
                          )
                        else
                          const SizedBox(width: 20),
                      ],
                    ),
                    Expanded(
                      child: SizedBox.expand(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Divider(),
                            Texto(txt: context.watch<SocketConn>().msgErr),
                            const Divider(),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ),
          )
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _refreshList,
          builder: (_, refresh, __) {

            return LstContactos(
              refresh: refresh,
              onTap: (contac, acc) {
                switch (acc) {
                  case 'hidratarScreen':
                    _contact = contac;
                    _hidratarScreenByIdContact();
                    break;
                  case 'clear':
                    _resetScreen();
                    break;
                  case 'add':
                    _resetScreen();
                    _nomEmpFcs.requestFocus();
                    break;
                  default:
                    _contact = contac;
                    _hidratarScreenByIdContact();
                    break;
                }
              },
            );
          }
        )
      ],
    );
  }

  ///
  Widget _frm() {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  DecorationField.fieldBy(
                    orden: 1,
                    ctr: _nomEmpCtrl,
                    fco: _nomEmpFcs,
                    iconoPre: Icons.business,
                    help: 'Nombre de la Empresa:',
                    isPass: false,
                    onPressed: (val){},
                    showPass: true,
                    validate: (String? val){
                      if(val != null) {
                        if(val.isNotEmpty) {
                          if(val.length > 3) {
                            return null;
                          }
                          return 'Mínimo 3 caracteres';
                        }
                      }
                      return 'Éste campo es requerido';
                    },
                  ),
                  const SizedBox(height: 20),
                  DecorationField.fieldBy(
                    orden: 2,
                    ctr: _domicilioCtrl,
                    fco: _domicilioFcs,
                    iconoPre: Icons.location_on,
                    help: 'Domicilio de la Empresa:',
                    isPass: false,
                    onPressed: (val){},
                    showPass: true,
                    validate: (String? val) {
                      if(val != null) {
                        if(val.isNotEmpty) {
                          if(val.length > 3) {
                            return null;
                          }
                          return 'Mínimo 3 caracteres';
                        }
                      }
                      return 'Éste campo es requerido';
                    },
                  )
                ],
              )
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DecorationField.fieldBy(
                          orden: 3,
                          ctr: _cpCtrl,
                          fco: _cpFcs,
                          isPass: false,
                          onPressed: (val){},
                          showPass: true,
                          iconoPre: Icons.location_searching,
                          help: 'C.P.:',
                          validate: (val) {
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.location_city_outlined, size: 35, color: Colors.green.withOpacity(0.5))
                    ],
                  ),
                  const SizedBox(height: 20),
                  DecorationField.fieldBy(
                    orden: 4,
                    ctr: _telFCtrl,
                    fco: _telFFcs,
                    iconoPre: Icons.phone,
                    help: 'Teléfono de la Empresa:',
                    isPass: false,
                    onPressed: (val){},
                    showPass: true,
                    validate: (val){
                      return null;
                    },
                  )
                ],
              )
            )
          ],
        ),
        const SizedBox(height: 20),
        const Texto(txt: 'DATOS DEL CONTACTO', txtC: Colors.green, isBold: true),
        const Divider(color: Colors.grey),
        const SizedBox(height: 21),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  DecorationField.fieldBy(
                    orden: 5,
                    ctr: _nomCtrl,
                    fco: _nomFcs,
                    iconoPre: Icons.location_history,
                    help: 'Nombre del Contácto:',
                    isPass: false,
                    onPressed: (val){},
                    showPass: true,
                    validate: (String? val) {
                      if(val != null) {
                        if(val.isNotEmpty) {
                          if(val.length > 3) {
                            return null;
                          }
                          return 'Mínimo 3 caracteres';
                        }
                      }
                      return 'Éste campo es requerido';
                    },
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                    future: _recuperarDatosMeta,
                    builder: (_, AsyncSnapshot snap) {

                      if(snap.connectionState == ConnectionState.done) {
                        if(cargos.isNotEmpty) {
                          return DecorationField.dropBy(
                            orden: 6,
                            fco: _cargosFcs,
                            iconoPre: Icons.location_history_rounded,
                            help: 'Cargo del Contácto:',
                            items: cargos,
                            onChange: (String? val) => setState(() {
                              _cargoSelect = val ?? '';
                            })
                          );
                        }else{
                          return const Texto(txt: 'No se recueraron los CARGOS', sz: 12, txtC: Colors.amber);
                        }
                      }

                      return const Center(
                        child: SizedBox(
                          width: 40, height: 40,
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  )
                ],
              )
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DecorationField.fieldBy(
                          orden: 7,
                          ctr: _celCtrl,
                          fco: _celFcs,
                          iconoPre: Icons.smartphone_rounded,
                          help: 'Celular:',
                          isPass: false,
                          onPressed: (val){},
                          showPass: true,
                          validate: (String? val) {
                            if(val != null) {
                              if(val.isNotEmpty) {
                                if(val.length > 6) {
                                  return null;
                                }
                                return 'Mínimo 6 caracteres';
                              }
                            }
                            return 'Éste campo es requerido';
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.people_alt, size: 35, color: Colors.green.withOpacity(0.5))
                    ],
                  ),
                  const SizedBox(height: 20),
                  DecorationField.fieldBy(
                    orden: 8,
                    ctr: _passCtrl,
                    fco: _passFcs,
                    iconoPre: Icons.password,
                    help: 'Contaseña:',
                    isPass: true,
                    showPass: _showPass,
                    onPressed: (val) => setState(() {
                      _showPass = val;
                    }),
                    validate: (String? val) {
                      if(val != null) {
                        if(val.isNotEmpty) {
                          if(val.length > 5) {
                            return null;
                          }
                          return 'Mínimo 6 caracteres';
                        }
                      }
                      return 'Éste campo es requerido';
                    },
                  )
                ],
              )
            )
          ],
        ),
      ],
    );
  }

  ///
  void _hidratarScreenByIdContact() {

    if(_contact != null) {
      if(_contact!.id == 0){
        _resetScreen();
      }
      _nomEmpCtrl.text = _contact!.emp!.nombre;
      _domicilioCtrl.text = _contact!.emp!.domicilio;
      _cpCtrl.text = '${_contact!.emp!.cp}';
      _telFCtrl.text = _contact!.emp!.telFijo;
      _nomCtrl.text = _contact!.nombre;
      _celCtrl.text = _contact!.celular;
      _passCtrl.text = 'same-password';
      _idContac = _contact!.id;
      _idEmp = _contact!.emp!.id;
      _isLocal = _contact!.emp!.isLocal;
      _isCot = _contact!.isCot;
      _cargoSelect = _contact!.cargo;
      setState(() {});
    }
  }

  ///
  Future<void> _getDatosMeta() async {
    cargos = await GetContentFile.cargos();
    if(cargos.isNotEmpty) {
      _cargoSelect = cargos.first;
    }
    roles = await GetContentFile.roles();
  }

  ///
  Future<void> _saveData() async {

    if(_frmKey.currentState!.validate()) {

      final provi = context.read<SocketConn>();
      
      EmpresaEntity emp = _hidratarEmpresaFromScreen(); 
      ContactoEntity cont = _hidratarContactoFromScreen();
      Map<String, dynamic> dataContac = cont.toJson();
      if(_isOtherContac) {
        dataContac['isOtherContac'] = _isOtherContac;
        dataContac['id'] = 0;
      }
      final data = {'empresa' : emp.toJson(), 'contacto': dataContac};
      setState(() { _isAbsorbing = true; });

      provi.msgErr = 'Actualizando datos directamente en el Servidor';
      await _contacEm.safeDataContact(data, isLocal: false);

      if(_contacEm.result['abort']) {
        provi.msgErr = _contacEm.result['body'];
        debugPrint(_contacEm.result['msg']);
      }else{

        emp.id   = _contacEm.result['body']['e'];
        cont.id  = _contacEm.result['body']['c'];
        cont.curc= _contacEm.result['body']['curc'];
        _idEmp   = emp.id;
        _idContac= cont.id;
        Map<String, dynamic> dataContac = cont.toJson();
        if(_isOtherContac) {
          dataContac['isOtherContac'] = _isOtherContac;
          dataContac['id'] = 0;
        }

        provi.msgErr = 'Actualizando Servidor Local';
        await _updateDataBaseLocal({'empresa' : emp.toJson(), 'contacto': dataContac});
      }
      
      setState(() { _isAbsorbing = false; });
    }
  }

  ///
  Future<void> _updateDataBaseLocal(Map<String, dynamic> data) async {

    final provi = context.read<SocketConn>();
    data['empresa']['local'] = true;
    data['contacto']['local'] = true;
    
    await _contacEm.safeDataContact(data, isLocal: true);

    if(_contacEm.result['abort']) {
      provi.msgErr = _contacEm.result['body'];
      debugPrint(_contacEm.result['msg']);
    }else{
      provi.msgErr = 'Datos guardados con éxito';
      Future.delayed(const Duration(milliseconds: 2000), (){
        provi.msgErr = '';
      });
      final ct = ContactoEntity();
      ct.fromFrmToList(data);
      _refreshList.value = !_refreshList.value;
      _resetScreen();
    }
    
    if(mounted) {
      setState(() { _isAbsorbing = false; });
    }else{
      _isAbsorbing = false;
    }
  }

  ///
  void _resetScreen() {

    _idEmp   = 0;
    _idContac= 0;
    _nomEmpCtrl.text = '';
    _domicilioCtrl.text = '';
    _cpCtrl.text = '';
    _telFCtrl.text = '';
    _nomCtrl.text = '';
    _celCtrl.text = '';
    _passCtrl.text = '1234567';
    _cargoSelect = cargos.first;
    _isCot = true;
    _isLocal = true;
  }

  ///
  EmpresaEntity _hidratarEmpresaFromScreen() {

    EmpresaEntity ent = EmpresaEntity();
    if(_idEmp != 0) {
      ent.id = _idEmp;
    }
    ent.nombre = _nomEmpCtrl.text.toUpperCase().trim();
    ent.domicilio = _domicilioCtrl.text.toUpperCase().trim();
    ent.cp = (_cpCtrl.text.isNotEmpty) ? int.parse(_cpCtrl.text) : 0;
    ent.isLocal = _isLocal;
    ent.telFijo = (_telFCtrl.text.isNotEmpty) ? _telFCtrl.text.trim() : '0';
    return ent;
  }

  ///
  ContactoEntity _hidratarContactoFromScreen() {

    ContactoEntity ent = ContactoEntity();
    if(_idContac != 0) {
      ent.id = _idContac;
    }
    ent.nombre = _nomCtrl.text.toUpperCase().trim();
    ent.cargo  = _cargoSelect;
    ent.celular= _celCtrl.text.trim();
    ent.isCot = _isCot;
    ent.password = _passCtrl.text.trim();
    ent.roles = [];
    Iterable<Map<String, dynamic>> rol = roles.where((element) => element['tit'] == 'SOLICITANTE');
    if(rol.isNotEmpty) {
      ent.roles.add(rol.first['role']);
    }
    if(_isCot) {
      rol = roles.where((element) => element['tit'] == 'COTIZADOR');
      if(rol.isNotEmpty) {
        ent.roles.add(rol.first['role']);
      }
    }
    return ent;
  }

}