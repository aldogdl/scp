import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'lst_prov_pzas.dart';
import 'metrix_data.dart';
import '../texto.dart';
import '../../../providers/centinela_provider.dart';

class Dashboard extends StatelessWidget {

  final Map<String, dynamic> orden;
  const Dashboard({
    Key? key,
    required this.orden
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final w = MediaQuery.of(context).size.width;
    
    return Container(
      width: w,
      height: MediaQuery.of(context).size.height,
      color: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          _topBarr(context, w, 35),
          const Divider(height: 1, color: Colors.black),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: MetrixData(file: orden['file'])
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: SizedBox.expand(
                    child: Selector<CentinelaProvider, int>(
                      selector: (_, prov) => prov.pestania,
                      builder: (_, inx, __) {

                        final pe = context.read<CentinelaProvider>().pestanias;

                        return Column(
                          children: [
                            _pestanias(context, pe, inx),
                            if(inx == 0)
                              Expanded(
                                flex: 4,
                                child: LstProvPzas(
                                  idOrden: orden['id']
                                )
                              )
                            else
                              ..._comporta()
                          ],
                        );
                      },
                    ),
                  )
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  ///
  List<Widget> _comporta() {

    return const [
      Texto(txt: 'comportamineto')
    ];
  }
  
  ///
  Widget _pestanias(BuildContext context, List<Map<String, String>> pestanias, int select) {
    
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 10),
      child: Row(
        children: pestanias.map(
          (e) => _pestania(
            context,
            e['tit']!,
            isActive: (e['slug'] == pestanias[select]['slug']) ? true : false
          )
        ).toList()
      ),
    );
  }

  ///
  Widget _pestania(BuildContext context, String titulo, {bool isActive = false}) {

    Color colorActiveTxt = Colors.grey;
    Color colorInActiveTxt = Colors.grey.withOpacity(0.5);

    Color colorActive = Colors.black.withOpacity(0.3);
    Color colorInActive = Colors.black.withOpacity(0.1);
    if(titulo == 'Comportamiento') {
      colorActive = const Color(0xff2e2e2e);
      colorActiveTxt = Colors.grey;
    }

    return InkWell(
      onTap: () {
        final p = context.read<CentinelaProvider>();
        p.pestania = (p.pestania == 0) ? 1 : 0;
      },
      child: Container(
        width: 150, height: 35,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: (isActive) ? colorActive : colorInActive,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5)
          )
        ),
        child: Center(
          child: Texto(
            txt: titulo,
            txtC: (isActive) ? colorActiveTxt : colorInActiveTxt,
            isCenter: true,
          ),
        ),
      ),
    );
  }

  ///
  Widget _topBarr(BuildContext context, double w, double h) {

    return Container(
      width: w, height: h,
      color: const Color.fromARGB(255, 96, 161, 98),
      child: Row(
        children: [
          _btnClose(context, h),
          const SizedBox(width: 10),
          const Icon(Icons.android, color: Colors.white),
          const SizedBox(width: 10),
          Texto(txt: '${orden['sol']}, ', txtC: Colors.white,),
          Texto(txt: 'ORDEN ID: ${orden['id']}', txtC: Colors.black, isBold: true),
          const Spacer(),
          const Texto(txt: 'DASHBOARD', sz: 13, txtC: Colors.black),
          const SizedBox(width: 10),
          _btnClose(context, h)
        ],
      ),
    );
  }

  ///
  Widget _btnClose(BuildContext context, double alto) {

    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 38, height: alto,
        color: Colors.red,
        child: const Center( child: Icon(Icons.close) ),
      ),
    );
  }
}