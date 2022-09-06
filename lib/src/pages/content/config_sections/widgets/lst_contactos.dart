import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scp/src/config/sng_manager.dart';

import 'package:scp/src/pages/content/config_sections/widgets/decoration_field.dart';
import 'package:scp/src/pages/widgets/my_tool_tip.dart';
import 'package:scp/src/services/get_content_files.dart';

import '../../../../entity/contacto_entity.dart';
import '../../../../providers/socket_conn.dart';
import '../../../../providers/window_cnf_provider.dart';
import '../../../../repository/contacts_repository.dart';
import '../../../../vars/globals.dart';
import '../../../widgets/texto.dart';

class LstContactos extends StatefulWidget {

  final bool isAdmin;
  final bool refresh;
  final Function(ContactoEntity, String) onTap;
  const LstContactos({
    Key? key,
    required this.onTap,
    required this.refresh,
    this.isAdmin = false
  }) : super(key: key);

  @override
  State<LstContactos> createState() => _LstContactosState();
}

class _LstContactosState extends State<LstContactos> {

  final _globals = getSngOf<Globals>();
  final ContactsRepository _contacEm = ContactsRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  final ValueNotifier<List<ContactoEntity>> _contacts = ValueNotifier<List<ContactoEntity>>([]);
  List<ContactoEntity> _contactsBack = [];

  late final SocketConn provi;
  bool _isInit = false;
  String _showTypeContacts = 'anetc';
  String _titulo = 'LISTA DE CONTACTOS';
  bool _makeBackUp = true;
  bool _creanLst = true;
  int _cantCots = 0;
  int _cantSols = 0;
  String msg = 'Cargando...';

  @override
  void initState() {

    _creanLst = widget.refresh;
    if(widget.isAdmin) {
      _titulo = 'LISTA DE COLABORADORES';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getAllContacts();
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if(!_isInit) {
      _isInit = true;
      provi = context.read<SocketConn>();
    }

    if(widget.refresh != _creanLst) {
      _creanLst = widget.refresh;
      _contactsBack.clear();
      _contacts.value.clear();
      Future.delayed(const Duration(milliseconds: 300), () {
        _getAllContacts();
      });
    }

    return Container(
      width: context.read<WindowCnfProvider>().tamMiddle,
      height: MediaQuery.of(context).size.height,
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.only(top: 10, right: 8, bottom: 5, left: 8),
      child: Column(
        children: [
          Texto(txt: _titulo, txtC: Colors.white, isBold: true),
          const SizedBox(height: 8),
          _txtBusk(),
          const SizedBox(height: 8),
          if(!widget.isAdmin)
            _pestanias(),
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
                      if(widget.isAdmin) {
                        return _tileContacts(index);
                      }else{
                        return (lst[index].curc.startsWith(_showTypeContacts))
                        ? _tileContacts(index) : const SizedBox();
                      }
                    }
                  );
                }else{

                  if(msg.isEmpty && lst.isEmpty) {
                    return Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt_outlined, size: 100, color: Colors.white.withOpacity(0.1)),
                        const Texto(txt: 'No hay Elementos')
                      ],
                    );
                  }

                  return const Center(
                    child: SizedBox(
                      width: 40, height: 40,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              }
            ),
          )
        ],
      ),
    );
  }

  ///
  Widget _pestanias() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => setState(() {
            _showTypeContacts = 'anetc';
          }),
          child: Texto(
            txt: 'COTIZADORES [$_cantCots]',
            txtC: (_showTypeContacts == 'anetc') ? Colors.green : Colors.grey.withOpacity(0.5),
            isBold: true
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _showTypeContacts = 'anets';
          }),
          child: Texto(
            txt: 'SOLICITANTES [$_cantSols]',
            txtC: (_showTypeContacts == 'anets') ? Colors.green : Colors.grey.withOpacity(0.5),
            isBold: true
          ),
        )
      ],
    );
  }
  
  ///
  Widget _tileContacts(int index) {

    return ListTile(
      onTap: () => widget.onTap(_contacts.value[index], 'hidratarScreen'),
      visualDensity: VisualDensity.compact,
      dense: true,
      contentPadding: const EdgeInsets.all(0),
      leading: IconButton(
        padding: const EdgeInsets.all(0),
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
        onPressed: () async {
          bool? acc = await _isShuredeleteContact();
          acc = (acc == null) ? false : acc;
          if(acc) {
            _deleteContact(_contacts.value[index].id);
          }
        },
      ),
      minLeadingWidth: 25,
      title: Row(
        children: [
          Texto(txt: _contacts.value[index].nombre, isBold: true),
          const Spacer(),
          if(_contacts.value[index].roles.contains('ROLE_ADMIN'))
            const MyToolTip(msg: 'Administrador', child: Icon(Icons.star, size: 15, color: Colors.amber)),
          const SizedBox(width: 5),
          if(_contacts.value[index].roles.contains('ROLE_AVO'))
            const MyToolTip(msg: 'AVO', child: Icon(Icons.note_alt_rounded, size: 15, color: Colors.green)),
          const SizedBox(width: 5),
          if(_contacts.value[index].roles.contains('ROLE_EVAL'))
            const MyToolTip(msg: 'Evaluador', child: Icon(Icons.monetization_on, size: 15, color: Colors.blue))
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
  Widget _txtBusk() {

    return TextField(
      controller: _searchCtrl,
      onChanged: (String? val) async => await _buscarContacto(val),
      onEditingComplete: (){
        if(_searchCtrl.text.contains(':')) {
          List<String> partes = _searchCtrl.text.split(':');
          int? idContact = int.tryParse(partes.last) ?? 0;
          if(idContact == 0) {
            widget.onTap(ContactoEntity(), partes.last.toLowerCase());
            _searchCtrl.text = '';
            return;
          }
          final ctD = _contacts.value.where((element) => element.id == idContact);
          if(ctD.isNotEmpty) {
            widget.onTap(ctD.first, partes.last.toLowerCase());
            _searchCtrl.text = '';
          }
        }
      },
      decoration: DecorationField.get(help: 'Buscar Contacto', iconoPre: Icons.search),
    );
  }

  ///
  Widget _chipId({required String id}) => Texto(
    txt: 'id: $id', sz: 12, isBold: true, txtC: Colors.orange
  );

  ///
  Future<bool?> _isShuredeleteContact() async {

    String msg = 'Estás a punto de eliminar permanentemente los datos del contacto '
    'seleccionado. Ésta acción borrará dicha información de nuestras bases de datos '
    'permanentemente sin poder recuperarla posteriormente.';

    return await showDialog(
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

  }
  
  ///
  Future<void> _deleteContact(int idContac) async {

    String element = (widget.isAdmin) ? 'COLABORADOR' : 'CONTACTO';

    late ContactoEntity contactDel;
    final ctD = _contacts.value.where((element) => element.id == idContac);
    if(ctD.isNotEmpty) {

      final provi = context.read<SocketConn>();
      contactDel = ctD.first;
      if(_makeBackUp) {
        await _contacEm.backupContact(contactDel.toJson());
      }
      
      provi.msgErr = 'ELIMINANDO $element REMOTO';

      if(!_globals.isLocalConn) {
        await _contacEm.deleteContact(idContac, isLocal: false);
        if(_contacEm.result['abort']) {
          provi.msgErr = _contacEm.result['body'];
          debugPrint(_contacEm.result['msg']);
          return;
        }
      }

      provi.msgErr = 'ELIMINANDO $element LOCAL';
      await _contacEm.deleteContact(idContac, isLocal: true);
      if(_contacEm.result['abort']) {
        provi.msgErr = _contacEm.result['body'];
        debugPrint(_contacEm.result['msg']);
        return;
      }

      provi.msgErr = 'EL $element FUÉ ELIMINADO CON ÉXITO';
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

      // -- borrar contacto del historial de logins.
      await GetContentFile.deleteRegOfLogin(contactDel.curc);
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
  Future<void> _getAllContacts() async {

    List<ContactoEntity> losCon = [];
    await _contacEm.getAllContacts(
      tipo: (widget.isAdmin) ? 'anete' : 'noAdmin',
      isLocal: _globals.isLocalConn
    );
    msg =  'RECUPERANDO ${ (widget.isAdmin) ? 'COLABORADORES' : 'CONTACTOS' }';
    provi.msgErr = msg;
    
    _cantCots = 0;
    _cantSols = 0;
    _showTypeContacts = '';
    
    if(!_contacEm.result['abort']) {
      if(_contacEm.result['body'].isNotEmpty) {

        for (var i = 0; i < _contacEm.result['body'].length; i++) {
          final ct = ContactoEntity();
          ct.fromServerWidtEmpresa(_contacEm.result['body'][i]);
          if(_showTypeContacts.isEmpty) {
            if(ct.curc.startsWith('anetc')) {
              _showTypeContacts = 'anetc';
            }
          }

          if(ct.curc.startsWith('anetc')) {
            _cantCots++;
          }
          if(ct.curc.startsWith('anets')) {
            _cantSols++;
          }
          losCon.add(ct);
        }
      }
    }
    if(losCon.isNotEmpty && _showTypeContacts.isEmpty) {
      _showTypeContacts = 'anets';
    }
    _contacts.value = losCon;
    _contactsBack = losCon;
    losCon = [];
    provi.msgErr = 'Lista Recuperada...';
    Future.delayed(const Duration(milliseconds: 1000), () {
      provi.msgErr = '';
      msg = '';
    });
    if(mounted) {
      setState(() {});
    }
  }

}