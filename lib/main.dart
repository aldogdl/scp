import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/pages/a_main/scp_layout.dart';
import 'src/config/sng_manager.dart';
import 'src/pages/login/login_page.dart';
import 'src/providers/centinela_file_provider.dart';
import 'src/providers/items_selects_glob.dart';
import 'src/providers/pages_provider.dart';
import 'src/providers/socket_conn.dart';
import 'src/providers/window_cnf_provider.dart';
import 'src/vars/scroll_config.dart';


void main() async {

  sngManager();
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  doWhenWindowReady(() {
    appWindow.minSize = const Size(830.0, 760.0);
    appWindow.alignment = Alignment.topLeft;
    appWindow.maximize();
    appWindow.show();
  });

  runApp(const ProvidersConfig());
}


class ProvidersConfig extends StatelessWidget {
  
  const ProvidersConfig({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WindowCnfProvider()),
        ChangeNotifierProvider(create: (_) => PageProvider()),
        ChangeNotifierProvider(create: (_) => SocketConn()),
        ChangeNotifierProvider(create: (_) => ItemSelectGlobProvider()),
        ChangeNotifierProvider(create: (_) => CentinelaFileProvider()),
      ],
      child: MaterialApp(
        scrollBehavior: MyCustomScrollBehavior(),
        title: 'SCP::Sistema de Cotización y Procesamiento',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.black.withOpacity(0.5)),
            trackBorderColor: MaterialStateProperty.all(Colors.black.withOpacity(0))
          )
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        navigatorKey: navigatorKey,
        home: const BuildContextGral(),
      )
    );
  }
}


class BuildContextGral extends StatelessWidget {
  
  const BuildContextGral({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (cotxTwo) => (cotxTwo.watch<SocketConn>().isLoged)
            ? const ScpLayout()
            : const LoginPage()
        )
      ]
    );
  }
}
