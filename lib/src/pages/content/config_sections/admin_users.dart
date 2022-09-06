import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/decoration_field.dart';
import 'widgets/lst_contactos.dart';
import '../../widgets/texto.dart';
import '../../../config/sng_manager.dart';
import '../../../entity/request_event.dart';
import '../../../entity/contacto_entity.dart';
import '../../../repository/contacts_repository.dart';
import '../../../providers/socket_conn.dart';
import '../../../services/get_content_files.dart';
import '../../../vars/globals.dart';

class AdminUsers extends StatefulWidget {

  const AdminUsers({Key? key}) : super(key: key);

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {

  final ContactsRepository _contacEm = ContactsRepository();
  final Globals globals = getSngOf<Globals>();

  final GlobalKey<FormState> _frmKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _cargoCtrl = TextEditingController();
  final TextEditingController _celCtrl = TextEditingController();
  final FocusNode _cargoFcs = FocusNode();
  final FocusNode _userFcs = FocusNode();
  final FocusNode _passFcs = FocusNode();
  final FocusNode _celFcs = FocusNode();

  final ValueNotifier<bool> _refreshList = ValueNotifier<bool>(false);
  ContactoEntity? _contact;
  String _cargoSelect = '';
  List<Map<String, dynamic>> cargos = [];
  bool _isAbsorbing = false;
  bool _showPass = true;
  bool _isAdmin = false;
  bool _isAVO = false;
  int _idContac = 0;
  late Future<void> _getMetas;

  @override
  void initState() {
    _getMetas = _getDatosMeta();
    super.initState();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _cargoCtrl.dispose();
    _celCtrl.dispose();
    _cargoFcs.dispose();
    _userFcs.dispose();
    _passFcs.dispose();
    _celFcs.dispose();
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
            child: Column(
              children: [
                const Texto(txt: 'GESTIONA DATOS DE COLABORADORES', txtC: Colors.white, isBold: true),
                const SizedBox(height: 26),
                const Texto(txt: 'CAPTURA LA INFORMACIÓN SOLICITADA', txtC: Colors.green, isBold: true),
                const Divider(color: Colors.grey),
                const SizedBox(height: 20),
                _frm(),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _isAdminAndAvo(),
                    const Spacer(),
                    _btnSend(),
                    if(_isAbsorbing)
                      ...[
                        const SizedBox(width: 10),
                        const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(),
                        )
                      ]
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
        ValueListenableBuilder<bool>(
          valueListenable: _refreshList,
          builder: (_, refresh, __) => LstContactos(
            refresh: refresh,
            isAdmin: true,
            onTap: (contac, acc) => _accContactos(contac, acc),
          )
        )
      ],
    );
  }

  ///
  Widget _frm() {

    return Form(
      key: _frmKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  DecorationField.fieldBy(
                    orden: 1,
                    ctr: _usernameCtrl,
                    fco: _userFcs, help: 'Nombre Completo',
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
                    iconoPre: Icons.person_add,
                    isPass: false,
                    onPressed: (val){},
                    showPass: true
                  ),
                  const SizedBox(height: 20),
                  DecorationField.fieldBy(
                    orden: 3,
                    ctr: _passwordCtrl,
                    fco: _passFcs, help: 'Contraseña [Sólo Números]',
                    validate: (String? val) {
                      if(val != null) {
                        if(val.isNotEmpty) {
                          if(val.length > 5) {
                            if(val != 'same-password') {
                              int ? soloDig = int.tryParse(val);
                              if(soloDig != null) {
                                return null;
                              }else{
                                return 'Coloca sólo números.';
                              }
                            }else{
                              return null;
                            }
                          }
                          return 'Mínimo 6 caracteres';
                        }
                      }
                      return 'Éste campo es requerido';
                    },
                    iconoPre: Icons.security,
                    isPass: true,
                    onPressed: (val) => setState(() {
                      _showPass = val;
                    }),
                    showPass: _showPass
                  )
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  DecorationField.fieldBy(
                    orden: 2,
                    ctr: _celCtrl,
                    fco: _celFcs, help: 'Celular',
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
                    iconoPre: Icons.security,
                    isPass: false,
                    onPressed: (val) {},
                    showPass: true
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                    future: _getMetas,
                    builder: (_, __) {
                      if(cargos.isNotEmpty) {
                        return DecorationField.dropBy(
                          orden: 4,
                          items: cargos.map<String>((e) => e['tit']).toList(),
                          fco: _cargoFcs,
                          help: 'Cargo',
                          iconoPre: Icons.category,
                          defaultValue: _cargoSelect,
                          onChange: (String? val) {
                            setState(() {
                              _cargoSelect = val ?? '';
                            });
                          },
                        );
                      }
                      return DecorationField.dropBy(
                        items: ['CARGANDO...'],
                        fco: _cargoFcs,
                        help: 'Cargo',
                        iconoPre: Icons.category,
                        onChange: (String? val) {
                          setState(() {
                            _cargoSelect = val ?? '';
                          });
                        },
                        orden: 1
                      );
                    }
                  )
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  ///
  Widget _isAdminAndAvo() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Texto(txt: 'Puede fungir como:', txtC: Colors.blue),
        Row(
          children: [
            const Texto(txt: 'Administrador', txtC: Colors.white),
            Checkbox(
              value: _isAdmin,
              checkColor: Colors.black,
              onChanged: (val) {
                setState(() {
                  _isAdmin = val ?? false;
                });
              }
            ),
            const SizedBox(width: 10),
            const Texto(txt: 'Asesor de Ventas OnLine', txtC: Colors.white),
            Checkbox(
              value: _isAVO,
              checkColor: Colors.black,
              onChanged: (val) {
                setState(() {
                  _isAVO = val ?? false;
                });
              }
            ),
          ],
        )
      ],
    );
  }
  
  ///
  Widget _btnSend() {

    return FocusTraversalOrder(
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
          child: const Texto(txt: 'CONTINUAR', txtC: Colors.black)
        ),
      )
    );
  }


  // ------------------------- CONTROLADOR -------------------------------


  ///
  void _accContactos(ContactoEntity contac, String acc) {

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
        _userFcs.requestFocus();
        break;
      default:
        _contact = contac;
        _hidratarScreenByIdContact();
        break;
    }
  }

  ///
  Future<void> _getDatosMeta() async {

    final tCargos = await GetContentFile.roles();
    if(tCargos.isNotEmpty) {
      tCargos.map((e){
        if(e['pre'] == 'anet') {
          cargos.add(e);
        }
      }).toList();
      _cargoSelect = cargos.first['tit'];
    }
  }

  ///
  Future<void> _saveData() async {

    if(_frmKey.currentState!.validate()) {

      final provi = context.read<SocketConn>();
      provi.msgErr = 'Actualizando datos directamente en el Servidor'; 
      ContactoEntity cont = _hidratarContactoFromScreen();
      var data = cont.toJsonForAdminUser();
      
      setState(() { _isAbsorbing = true; });
      
      await _contacEm.safeDataContact(data, isLocal: false);
      if(_contacEm.result['abort']) {
        provi.msgErr = _contacEm.result['body'];
        debugPrint(_contacEm.result['msg']);
      }

      provi.msgErr = 'Actualizando Servidor Local';
      data['local'] = true;
      cont.empresaId= _contacEm.result['body']['e'];
      cont.id  = _contacEm.result['body']['c'];
      cont.curc= _contacEm.result['body']['curc'];
      data = cont.toJsonForAdminUser();

      await _contacEm.safeDataContact(data, isLocal: true);
      if(_contacEm.result['abort']) {
        provi.msgErr = _contacEm.result['body'];
        debugPrint(_contacEm.result['msg']);
      }else{
        provi.msgErr = 'Datos guardados con éxito';
        _idContac= cont.id;
        await _updateDataToHarbi(cont.toJsonForAdminUser());
      }
      setState(() { _isAbsorbing = false; });
    }
  }

  ///
  Future<void> _updateDataToHarbi(Map<String, dynamic> data) async {

    final provi = context.read<SocketConn>();
    final ct = ContactoEntity();
    ct.fromFrmToList(data);

    var dataUpdate = ct.toJsonForUpdateHarbi();
    provi.msgErr = 'Espera..., estamos terminando de actualiza los datos';
    provi.send(
      RequestEvent(event: 'connection', fnc: 'edit_user', data: dataUpdate)
    );
    _refreshList.value = !_refreshList.value;
    _resetScreen();
    
    if(mounted) {
      setState(() { _isAbsorbing = false; });
    }else{
      _isAbsorbing = false;
    }
    Future.delayed(const Duration(milliseconds: 2000), (){
      provi.msgErr = '';
    });
  }

  ///
  void _resetScreen() {

    _idContac= 0;
    _usernameCtrl.text = '';
    _celCtrl.text = '';
    _isAdmin = false;
    _isAVO = false;
    _passwordCtrl.text = '1234567';
    _cargoSelect = cargos.first['tit'];
  }

  ///
  void _hidratarScreenByIdContact() {

    if(_contact != null) {
      if(_contact!.id == 0){
        _resetScreen();
      }
      _usernameCtrl.text = _contact!.nombre;
      _celCtrl.text = _contact!.celular;
      _passwordCtrl.text = 'same-password';
      _idContac = _contact!.id;
      _cargoSelect = _contact!.cargo;
      _isAdmin = (_contact!.roles.contains('ROLE_ADMIN')) ? true : false;
      _isAVO = (_contact!.roles.contains('ROLE_AVO')) ? true : false;

      setState(() {});
    }
  }

  ///
  ContactoEntity _hidratarContactoFromScreen() {

    ContactoEntity ent = ContactoEntity();
    if(_idContac != 0) {
      ent.id = _idContac;
    }
    ent.nombre = _usernameCtrl.text.toUpperCase().trim();
    ent.celular= _celCtrl.text.trim();
    ent.password = _passwordCtrl.text.trim();

    ent.cargo  = _cargoSelect;
    String role = '';
    String roleAvo = 'ROLE_AVO';
    String admin = 'ROLE_ADMIN';
    final strR = cargos.where((element) => element['tit'] == _cargoSelect);
    if(strR.isNotEmpty) {
      role = strR.first['role'];
    }

    List<String> losRoles = [];
    if(role.isNotEmpty) {
      if(!losRoles.contains(role)) {
        losRoles.add(role);
      }
    }
    if(_isAdmin) {
      if(!losRoles.contains(admin)) {
        losRoles.add(admin);
      }
    }
    if(_isAVO) {
      if(!losRoles.contains(roleAvo)) {
        losRoles.add(roleAvo);
      }
    }
    ent.roles = (losRoles.isEmpty) ? [roleAvo] : losRoles;
    return ent;
  }

}