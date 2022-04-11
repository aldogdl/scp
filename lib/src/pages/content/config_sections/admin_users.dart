import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../entity/contacto_entity.dart';
import '../../../providers/socket_conn.dart';
import '../../widgets/texto.dart';
import 'widgets/lst_contactos.dart';

class AdminUsers extends StatefulWidget {

  const AdminUsers({Key? key}) : super(key: key);

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {

  final GlobalKey<FormState> _frmKey = GlobalKey<FormState>();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _userFcs = FocusNode();
  final FocusNode _passFcs = FocusNode();

  ContactoEntity? _contact;
  bool _isAbsorbing = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _userFcs.dispose();
    _passFcs.dispose();
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
                    //_frm(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        
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
        LstContactos(
          refresh: true,
          isAdmin: true,
          onTap: (contac, acc) {
            switch (acc) {
              case 'hidratarScreen':
                _contact = contac;
                break;
              default:
            }
          },
        )
      ],
    );
  }

  ///
  Future<void> _saveData() async {

  }
}