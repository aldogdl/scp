import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';

import '../../config/sng_manager.dart';
import '../../content_side.dart';
import '../../middle_side.dart';
import '../../providers/window_cnf_provider.dart';
import '../../status_barr.dart';
import '../../vars/globals.dart';
import '../../vars/intents/show_action_main.dart';
import '../../vars/shortcut_activators.dart';

class ScpLayout extends StatefulWidget {

  const ScpLayout({Key? key}) : super(key: key);

  @override
  State<ScpLayout> createState() => _ScpLayoutState();
}

class _ScpLayoutState extends State<ScpLayout> with WindowListener {

  final Globals globals = getSngOf<Globals>();

  bool _isInit = false;
  late WindowCnfProvider winCnf;
  late AudioPlayer player;

  @override
  void initState() {
    windowManager.addListener(this);
    player = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await player.setAsset('assets/audio/cotizaciones.mp3');
    });
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    player.dispose();
    super.dispose();
  }
  
  @override
  void onWindowResize() {
    winCnf.contentSize = appWindow.size;
  }
  
  @override
  Widget build(BuildContext context) {
    if(!_isInit) {
      _isInit = true;
      winCnf = context.read<WindowCnfProvider>();
      winCnf.setWindowSize(appWindow.size);
    }

    return Scaffold(
      body: FocusableActionDetector(
        focusNode: globals.focusMain,
        autofocus: true,
        descendantsAreFocusable: true,
        shortcuts: <ShortcutActivator, Intent>{
          showActionMain: ShowActionMainIntent()
        },
        actions: <Type, Action<Intent>>{
          ShowActionMainIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) => ActionShowActionMain.showActionsMain(context)
          )
        },
        child: WindowBorder(
          color: winCnf.borderColor,
          width: 1,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: const [
                    MiddleSide(),
                    Expanded(child: ContentSide())
                  ]
                ),
              ),
              StatusBarr(
                player: player
              )
            ],
          )
        ),
      )
    );
  }
}