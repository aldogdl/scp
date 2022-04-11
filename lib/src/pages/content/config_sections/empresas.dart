import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/contacto_entity.dart';
import '../../../entity/empres_entity.dart';
import '../../../providers/socket_conn.dart';
import '../../../providers/window_cnf_provider.dart';
import '../../../repository/contacts_repository.dart';
import '../../../services/get_content_files.dart';
import '../../widgets/texto.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();

  final FocusNode _nomEmpFcs = FocusNode();
  final FocusNode _domicilioFcs = FocusNode();
  final FocusNode _cpFcs = FocusNode();
  final FocusNode _telFFcs = FocusNode();
  final FocusNode _cargosFcs = FocusNode();
  final FocusNode _nomFcs = FocusNode();
  final FocusNode _celFcs = FocusNode();
  final FocusNode _passFcs = FocusNode();

  final ValueNotifier<List<ContactoEntity>> _contacts = ValueNotifier<List<ContactoEntity>>([]);
  List<ContactoEntity> _contactsBack = [];
  late Future<void> _recuperarDatosMeta;
  List<String> cargos = [];
  List<Map<String, dynamic>> roles = [];
  bool _isLocal = true;
  bool _isCot = true;
  bool _showPass = true;
  String _cargoSelect = '';
  String _showTypeContacts = 'cnet';
  bool _isAbsorbing = false;
  bool _makeBackUp = true;
  int _idEmp = 0;
  int _idContac = 0;
  int _cantCots = 0;
  int _cantSols = 0;

  @override
  void initState() {
    _recuperarDatosMeta = _getDatosMeta();
    _getAllContacts();
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
    _searchCtrl.dispose();
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
                        child: Texto(txt: context.watch<SocketConn>().msgErr),
                      ),
                    )
                  ],
                ),
              )
            ),
          )
        ),
        Container(
          width: context.read<WindowCnfProvider>().tamMiddle,
          height: MediaQuery.of(context).size.height,
          color: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.only(top: 10, right: 8, bottom: 5, left: 8),
          child: Column(
            children: [
              const Texto(txt: 'LISTA DE CONTACTOS', txtC: Colors.white, isBold: true),
              const SizedBox(height: 8),
              _txtBusk(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _showTypeContacts = 'cnet';
                    }),
                    child: Texto(
                      txt: 'COTIZADORES [$_cantCots]',
                      txtC: (_showTypeContacts == 'cnet') ? Colors.green : Colors.grey.withOpacity(0.5),
                      isBold: true
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _showTypeContacts = 'snet';
                    }),
                    child: Texto(
                      txt: 'SOLICITANTES [$_cantSols]',
                      txtC: (_showTypeContacts == 'snet') ? Colors.green : Colors.grey.withOpacity(0.5),
                      isBold: true
                    ),
                  )
                ],
              ),
              const Divider(color: Colors.grey),
              const SizedBox(height: 21),
              Expanded(
                child: ValueListenableBuilder<List<ContactoEntity>>(
                  valueListenable: _contacts,
                  builder: (_, lst, __) {

                    if(lst.isNotEmpty) {
                      return ListView.builder(
                        itemCount: lst.length,
                        padding: const EdgeInsets.all(0),
                        itemBuilder: (_, index) {
                          return (lst[index].curc.startsWith(_showTypeContacts))
                          ? _tileContacts(index) : const SizedBox();
                        }
                      );
                    }else{
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.people_alt_outlined, size: 100, color: Colors.white.withOpacity(0.1)),
                          const Texto(txt: 'No hay Contactos')
                        ],
                      );
                    }
                  }
                ),
              )
            ],
          ),
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
                  _fieldBy(
                    orden: 1,
                    ctr: _nomEmpCtrl,
                    fco: _nomEmpFcs,
                    iconoPre: Icons.business,
                    help: 'Nombre de la Empresa:',
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
                  _fieldBy(
                    orden: 2,
                    ctr: _domicilioCtrl,
                    fco: _domicilioFcs,
                    iconoPre: Icons.location_on,
                    help: 'Domicilio de la Empresa:',
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
                        child: _fieldBy(
                          orden: 3,
                          ctr: _cpCtrl,
                          fco: _cpFcs,
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
                  _fieldBy(
                    orden: 4,
                    ctr: _telFCtrl,
                    fco: _telFFcs,
                    iconoPre: Icons.phone,
                    help: 'Teléfono de la Empresa:',
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
                  _fieldBy(
                    orden: 5,
                    ctr: _nomCtrl,
                    fco: _nomFcs,
                    iconoPre: Icons.location_history,
                    help: 'Nombre del Contácto:',
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
                          return _dropBy(
                            orden: 6,
                            fco: _cargosFcs,
                            iconoPre: Icons.location_history_rounded,
                            help: 'Cargo del Contácto:',
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
                        child: _fieldBy(
                          orden: 7,
                          ctr: _celCtrl,
                          fco: _celFcs,
                          iconoPre: Icons.smartphone_rounded,
                          help: 'Celular:',
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
                  _fieldBy(
                    orden: 8,
                    ctr: _passCtrl,
                    fco: _passFcs,
                    iconoPre: Icons.password,
                    help: 'Contaseña:',
                    isPass: true,
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
  Widget _tileContacts(int index) {

    return ListTile(
      onTap: () => _hidratarScreenByIdContact(_contacts.value[index].id),
      visualDensity: VisualDensity.compact,
      dense: true,
      contentPadding: const EdgeInsets.all(0),
      leading: IconButton(
        padding: const EdgeInsets.all(0),
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
        onPressed: () => _deleteContact(_contacts.value[index].id),
      ),
      minLeadingWidth: 25,
      title: Row(
        children: [
          Texto(txt: _contacts.value[index].nombre, isBold: true),
          const Spacer(),
          _chipId(id: '${_contacts.value[index].id}')
        ],
      ),
      subtitle: Row(
        children: [
          Texto(txt: _contacts.value[index].emp!.nombre, sz: 12, txtC: Colors.blue),
          const Spacer(),
          Texto(txt: _contacts.value[index].curc, sz: 12, txtC: Colors.white),
          const SizedBox(width: 8),
          _chipId(id: '${_contacts.value[index].emp!.id}')
        ]
      ),
    );
  }

  ///
  Widget _chipId({
    required String id
  }) => Texto(txt: 'id: $id', sz: 12, isBold: true, txtC: Colors.orange);

  ///
  Widget _fieldBy({
    required TextEditingController ctr,
    required FocusNode fco,
    required String help,
    required Function validate,
    required IconData iconoPre,
    required double orden,
    bool isPass = false
  }) {

    return FocusTraversalOrder(
      order: NumericFocusOrder(orden),
      child: TextFormField(
        controller: ctr,
        focusNode: fco,
        textInputAction: TextInputAction.next,
        obscureText: (!isPass) ? false : _showPass,
        validator: (val) => validate(val),
        decoration: decoration(help: help, isPass: isPass, iconoPre: iconoPre),
      ),
    );
  }

  ///
  Widget _dropBy({
    required FocusNode fco,
    required String help,
    required IconData iconoPre,
    required double orden,
  }) {

    return FocusTraversalOrder(
      order: NumericFocusOrder(orden),
      child: DropdownButtonFormField<String>(
        focusNode: fco,
        onChanged: (valSel){
          _cargoSelect = valSel!;
        },
        value: cargos.first,
        items: cargos.map((cargo) => DropdownMenuItem(
          value: cargo,
          child: Texto(txt: cargo),
        )).toList(),
        decoration: decoration(help: help, iconoPre:iconoPre),
      ),
    );
  }

  ///
  Widget _txtBusk() {

    return TextField(
      controller: _searchCtrl,
      onChanged: (String? val) async => await _buscarContacto(val),
      onEditingComplete: (){
        if(_searchCtrl.text.contains(':')) {
          List<String> partes = _searchCtrl.text.split(':');
          int? idContact = int.tryParse(partes.last) ?? 0;
          if(idContact == 0) {
            _commands(partes.last);
            return;
          }
          _hidratarScreenByIdContact(idContact);
        }
      },
      decoration: decoration(help: 'Buscar Contacto', iconoPre: Icons.search),
    );
  }

  ///
  InputDecoration decoration({
    required String help,
    required IconData iconoPre,
    bool isPass = false,
  }) {

    return InputDecoration(
      suffixIcon: (!isPass)
      ? null
      : Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: IconButton(
          onPressed: () => setState((){ _showPass = !_showPass; }),
          icon: Icon((_showPass) ? Icons.visibility : Icons.visibility_off)
        ),
      ),
      hintText: help,
      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 88, 88, 88)
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1
        ),
      ),
      prefixIcon: Icon(iconoPre, size: 15, color: Colors.white.withOpacity(0.2)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1
        ),
      ),
      errorStyle: const TextStyle(
        color: Color.fromARGB(255, 255, 244, 149)
      ),
      helperText: help
    );
  }

  ///
  void _hidratarScreenByIdContact(int idContact) {

    List<ContactoEntity> res = _contacts.value.where((element) => element.id == idContact).toList();
    
    if(res.isNotEmpty) {
      _nomEmpCtrl.text = res.first.emp!.nombre;
      _domicilioCtrl.text = res.first.emp!.domicilio;
      _cpCtrl.text = '${res.first.emp!.cp}';
      _telFCtrl.text = res.first.emp!.telFijo;
      _nomCtrl.text = res.first.nombre;
      _celCtrl.text = res.first.celular;
      _passCtrl.text = 'same-password';
      _searchCtrl.text = '';
      _idContac = res.first.id;
      _idEmp = res.first.emp!.id;
      _isLocal = res.first.emp!.isLocal;
      _isCot = res.first.isCot;
      _cargoSelect = res.first.cargo;
      _contacts.value = List<ContactoEntity>.from(_contactsBack);
      setState(() {});
    }
  }

  ///
  void _commands(String command) {

    switch (command) {
      case 'clean':
        _resetScreen();
        break;
      case 'add':
        _resetScreen();
        _nomEmpFcs.requestFocus();
        break;
      default:
    }
    _searchCtrl.text = '';
  }

  ///
  Future<void> _deleteContact(int idContac) async {

    String msg = 'Estás a punto de eliminar permanentemente los datos del contacto '
    'seleccionado, esta acción borrará dicha imformación de nuestras base de datos '
    'permanentemente sin poder recuperala permanentemente.';

    bool acc = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Texto(txt: 'BORRAR CONTACTO', sz: 19, txtC: Colors.red, isBold: true,),
                const Divider(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Texto(txt: msg),
                ),
                const SizedBox(height: 15),
                const Texto(txt: '¿Estás segur@ de continuar con la operación?', txtC: Colors.white),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Texto(txt: 'Realizar una copia de Seguridad.', txtC: Colors.white),
                    const SizedBox(width: 8),
                    Switch(
                      value: _makeBackUp,
                      onChanged: (val) {
                        setState(() {
                          _makeBackUp = val;
                        });
                      }
                    )
                  ],
                )
              ],
            );
          },
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 15),
        actions: [
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red)
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Texto(txt: 'NO, CANCELAR', txtC: Colors.white),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue)
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Texto(txt: 'SÍ, BORRAR', txtC: Colors.white),
          ),
        ],
      )
    );

    if(acc) {
      late ContactoEntity contactDel;
      final ctD = _contacts.value.where((element) => element.id == idContac);
      if(ctD.isNotEmpty) {
        contactDel = ctD.first;
        if(_makeBackUp) {
          print(contactDel.toJson());
        }
        final provi = context.read<SocketConn>();
        provi.msgErr = 'ELIMINANDO CONTACTO REMOTO';

        await _contacEm.deleteContact(idContac, isLocal: false);
        if(_contacEm.result['abort']) {
          provi.msgErr = _contacEm.result['body'];
          debugPrint(_contacEm.result['msg']);
          return;
        }

        provi.msgErr = 'ELIMINANDO CONTACTO LOCAL';
        await _contacEm.deleteContact(idContac, isLocal: true);
        if(_contacEm.result['abort']) {
          provi.msgErr = _contacEm.result['body'];
          debugPrint(_contacEm.result['msg']);
          return;
        }

        provi.msgErr = 'EL CONTACTO FUÉ ELIMINADO CON ÉXITO';
        Future.delayed(const Duration(milliseconds: 2000), (){
          provi.msgErr = '';
        });
        _contacts.value.remove(contactDel);
        _contactsBack.remove(contactDel);
        if(contactDel.curc.startsWith('cnet')) {
          _cantCots--;
        }
        if(contactDel.curc.startsWith('snet')) {
          _cantSols--;
        }
      }
    }
  }

  ///
  Future<void> _buscarContacto(String? criterio) async {

    if(_contactsBack.isEmpty) {
      _contactsBack = List<ContactoEntity>.from(_contacts.value);
    }
    if(criterio == null) {
      _contacts.value = List<ContactoEntity>.from(_contactsBack);
      return;
    }
    if(criterio.contains(':')) {
      return;
    }
    _contacts.value = _contactsBack.where((element) => element.nombre.toLowerCase().contains(criterio.toLowerCase())).toList();
    if(_contacts.value.isEmpty) {
      _contacts.value = _contactsBack.where((element) => element.emp!.nombre.toLowerCase().contains(criterio.toLowerCase())).toList();
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
      
      provi.msgErr = 'Actualizando datos directamente en el Servidor';
      EmpresaEntity emp = _hidratarEmpresaFromScreen(); 
      ContactoEntity cont = _hidratarContactoFromScreen();

      final data = {'empresa' : emp.toJson(), 'contacto': cont.toJson()};
      setState(() { _isAbsorbing = true; });
      await _contacEm.safeDataContact(data, isLocal: false);

      if(_contacEm.result['abort']) {
        provi.msgErr = _contacEm.result['body'];
        setState(() { _isAbsorbing = false; });
      }else{
        provi.msgErr = 'Actualizando Servidor Local';
        emp.id   = _contacEm.result['body']['e'];
        cont.id  = _contacEm.result['body']['c'];
        cont.curc= _contacEm.result['body']['curc'];
        _idEmp   = emp.id;
        _idContac= cont.id;
        await _updateDataBaseLocal({'empresa' : emp.toJson(), 'contacto': cont.toJson()});
      }
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
      _contacts.value.insert(0, ct);
      _contactsBack.insert(0, ct);
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
  Future<void> _getAllContacts() async {

    List<ContactoEntity> losCon = [];
    await _contacEm.getAllContacts();
    _showTypeContacts = '';
    if(!_contacEm.result['abort']) {
      if(_contacEm.result['body'].isNotEmpty) {
        for (var i = 0; i < _contacEm.result['body'].length; i++) {
          final ct = ContactoEntity();
          ct.fromServerWidtEmpresa(_contacEm.result['body'][i]);
          if(_showTypeContacts.isEmpty) {
            if(ct.curc.startsWith('cnet')) {
              _showTypeContacts = 'cnet';
            }
          }
          if(ct.curc.startsWith('cnet')) {
            _cantCots++;
          }
          if(ct.curc.startsWith('snet')) {
            _cantSols++;
          }
          losCon.add(ct);
        }
      }
    }
    if(losCon.isNotEmpty && _showTypeContacts.isEmpty) {
      _showTypeContacts = 'snet';
    }
    _contacts.value = losCon;
    _contactsBack = losCon;
    losCon = [];
    setState(() {});
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