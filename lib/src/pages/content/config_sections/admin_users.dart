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
            child: Form(
              key: _frmKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(
                  children: [
                    const Texto(txt: 'GESTIONA ADMINISTRATIVOS', txtC: Colors.white, isBold: true),
                    const SizedBox(height: 26),
                    const Texto(txt: 'DATOS DE COLABORADORES', txtC: Colors.green, isBold: true),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 21),
                    _frm(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Texto(txt: 'Puede fungir como Administradora?', txtC: Colors.white),
                        Checkbox(
                          value: _isAdmin,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            setState(() {
                              _isAdmin = val ?? false;
                            });
                          }
                        ),
                        const Spacer(),
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
              isAdmin: true,
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
                    _userFcs.requestFocus();
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

    return Row(
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
    );
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

      setState(() {});
    }
  }

  ///
  Future<void> _saveData() async {

    if(_frmKey.currentState!.validate()) {

      final provi = context.read<SocketConn>();      
      bool isconected = await provi.ping();
      if(!isconected) {
        provi.cerrarConection();
        return;
      }

      provi.msgErr = 'Actualizando datos directamente en el Servidor'; 
      ContactoEntity cont = _hidratarContactoFromScreen();
      final data = cont.toJsonForAdmin(cargos, isAdmin: _isAdmin);
      
      setState(() { _isAbsorbing = true; });

      await _contacEm.safeDataContact(data, isLocal: false);

      if(_contacEm.result['abort']) {
        provi.msgErr = _contacEm.result['body'];
        debugPrint(_contacEm.result['msg']);
        setState(() { _isAbsorbing = false; });
      }else{
        provi.msgErr = 'Actualizando Servidor Local';
        cont.id  = _contacEm.result['body']['c'];
        cont.curc= _contacEm.result['body']['curc'];
        _idContac= cont.id;
        await _updateDataBaseLocal(cont.toJsonForAdmin(cargos, isAdmin: _isAdmin));
      }
    }
  }

  ///
  Future<void> _updateDataBaseLocal(Map<String, dynamic> data) async {

    final provi = context.read<SocketConn>();
    data['local'] = true;
    
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

      var dataUpdate = ct.toJsonForUpdateHarbi();
      provi.msgErr = 'Espera..., estamos terminando de actualiza los datos';
      provi.send(
        RequestEvent(event: 'connection', fnc: 'edit_user', data: dataUpdate)
      );
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

    _idContac= 0;
    _usernameCtrl.text = '';
    _celCtrl.text = '';
    _isAdmin = false;
    _passwordCtrl.text = '1234567';
    _cargoSelect = cargos.first['tit'];
  }

  ///
  ContactoEntity _hidratarContactoFromScreen() {

    ContactoEntity ent = ContactoEntity();
    if(_idContac != 0) {
      ent.id = _idContac;
    }
    ent.nombre = _usernameCtrl.text.toUpperCase().trim();
    ent.cargo  = _cargoSelect;
    ent.celular= _celCtrl.text.trim();
    ent.password = _passwordCtrl.text.trim();
    return ent;
  }

}