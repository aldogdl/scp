import 'package:flutter/material.dart';
import 'package:scp/src/pages/widgets/scranet/build_data_gral.dart';
import 'package:scp/src/pages/widgets/scranet/dashboard_scranet.dart';
import 'package:scp/src/services/scranet/system_file_scrap.dart';

class BuildScranet extends StatefulWidget {

  const BuildScranet({Key? key}) : super(key: key);

  @override
  State<BuildScranet> createState() => _BuildScranetState();
}

class _BuildScranetState extends State<BuildScranet> {

  bool _isInit = true;

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.green,
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text('Dashboard ScraNet')
            ],
          ),
        ),
        Expanded(
          child: SizedBox.expand(
            child: (_isInit)
              ? _chekSystemInit()
              : const DashboardScranet(),
          )
        )
      ],
    );
  }

  ///
  Widget _chekSystemInit() {

    return StreamBuilder<String>(
      stream: _checkSystem(),
      initialData: 'Checando Sistema',
      builder: (_, AsyncSnapshot val) {

        if(val.hasData) {
          if(val.data.toString().startsWith('Iniciando')) {
            return BuildDataGral(
              onFinish: (_) {
                setState(() {
                  _isInit = false;
                });
              },
            );
          }

          if(val.data == 'ok') {
            return const DashboardScranet();
          }
        }

        return Center(
          child: SizedBox(
            width: 500, height: 100,
            child: Column(
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 15),
                Text(
                  val.data,
                  textScaleFactor: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
  ///
  Stream<String> _checkSystem() async* {

    var res = await SystemFileScrap.chekSystem(craw: 'radec');
    if(res != 'ok') {
      yield res;
      await Future.delayed(const Duration(milliseconds: 2000));
      yield 'Iniciando Builder';
      return;
    }

    res = await SystemFileScrap.chekSystem(craw: 'aldo');
    if(res != 'ok') {
      yield res;
      await Future.delayed(const Duration(milliseconds: 2000));
      yield 'Iniciando Builder';
      return;
    }

    yield 'ok';
  }
}