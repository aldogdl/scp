import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'title_seccion.dart';
import '../texto.dart';
import '../../../providers/centinela_provider.dart';

class ChartsTerminal extends StatelessWidget {

  const ChartsTerminal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    double wTer = 0.3;

    return LayoutBuilder(
      builder: (_, cnst) {

        return Container(
          width: cnst.maxWidth, height: cnst.maxHeight,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color.fromARGB(255, 102, 102, 102), width: 1))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: cnst.maxWidth - (cnst.maxWidth * wTer), height: cnst.maxHeight,
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _charProv()
                    ),
                    const SizedBox(width: 50),
                    Expanded(
                      flex: 3,
                      child: _charPzas()
                    ),
                  ],
                ),
              ),
              Container(
                width: cnst.maxWidth * wTer, height: cnst.maxHeight,
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleSeccion(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: const [
                            Icon(Icons.code, color: Colors.white),
                            SizedBox(width: 10),
                            Texto(txt: 'TERMINAL', isBold: true, txtC: Colors.black)
                          ],
                        ),
                      )
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Selector<CentinelaProvider, List<String>>(
                          selector: (_, prov) => prov.tConsole,
                          builder: (_, task, __) => ListView(
                            children: task.map((e) => _tileTask(e)).toList()
                          ),
                        )
                      )
                    )
                  ],
                )
              )
            ],
          ),
        );
      },
    );
  }

  ///
  Widget _charProv() {

    return Selector<CentinelaProvider, Map<String, double>>(
      selector: (_, prov) => prov.dataChartProv,
      builder: (_, data, child) {

        if(data.isEmpty) {
          return child!;
        }
        final d = Map<String, double>.from(data);
        final t = d['total'];
        d.remove('total');

        return Column(
          children: [
            Texto(txt: 'Total Cotizadores: $t'),
            const Divider(),
            const SizedBox(height: 8),
            PieChart(
              dataMap: d,
              totalValue: t,
              colorList: [
                Colors.green,
                Colors.grey.withOpacity(0.5),
              ],
              chartType: ChartType.ring,
            )
          ],
        );
      },
      child: Center(
        child: Container(
          width: 135, height: 135,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(135)
          ),
        ),
      ),
    );
    
  }

  ///
  Widget _charPzas() {

    Map<String, double> dataMap = {
      "Cotz:": 5,
      "No Tng:": 3,
      "No Mnj": 2,
      "Resp": 2,
      "Vistas": 2,
    };
    return PieChart(dataMap: dataMap);
    
  }

  ///
  Widget _tileTask(String task) {

    task = (task.length > 28) ? '${task.substring(0, 28)}...' :  task;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        task,
        textScaleFactor: 1,
        style: GoogleFonts.inconsolata(
          textStyle: TextStyle(
            color: _getColor(task),
            fontSize: 13,
            letterSpacing: 1.1
          )
        ),
      ),
    );
  }

  ///
  Color _getColor(String task) {

    if(task.startsWith('[X]')) {
      return const Color.fromARGB(255, 228, 81, 71);
    }
    if(task.startsWith('[!]')) {
      return const Color.fromARGB(255, 228, 147, 71);
    }
    if(task.startsWith('[√]')) {
      return const Color.fromARGB(255, 71, 108, 228);
    }
    return const Color.fromARGB(255, 139, 152, 172);
  }

}