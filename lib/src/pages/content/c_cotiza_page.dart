import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../widgets/frm_cotiza/lst_piezas_simyls.dart';
import '../widgets/frm_cotiza/ords_en_procs.dart';
import '../widgets/frm_cotiza/lst_piezas_orden.dart';
import '../widgets/frm_cotiza/set_images.dart';

class CCotizaPage extends StatelessWidget {

  const CCotizaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox.expand(
              child: Column(
                children: [
                  const SetImages(),
                  Expanded(
                    child: MultiSplitViewTheme(
                      data: MultiSplitViewThemeData(dividerThickness: 20),
                      child: _multiple(context),
                    )
                  )
                ],
              ),
            ),
          ),
          const OrdsEnProcs()
        ],
      ),
    );
  }

  ///
  Widget _multiple(BuildContext context) {

    return MultiSplitView(
      axis: Axis.horizontal,
      children: [
        MultiSplitView(
          axis: Axis.vertical,
          dividerBuilder: (axis, index, resizable, dragging, highlighted, themeData) {

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.001,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.transparent
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    ),
                    child: const SizedBox(height: 0)
                  )
                ],
              ),
            );
          },
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 26, 26, 26),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                )
              ),
              child: const LstPiezasOrden(),
            ),
            const LstPiezasSimyls()
          ]
      ),
    ]
    );
  }

}