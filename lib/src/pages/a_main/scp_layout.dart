import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

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

class _ScpLayoutState extends State<ScpLayout> {

  final Globals globals = getSngOf<Globals>();

  bool _isInit = false;
  bool _isLoad = false;
  late WindowCnfProvider winCnf;
  late AudioPlayer player;

  @override
  void initState() {

    player = AudioPlayer();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      
      if(!_isLoad) {
        _isLoad = true;
        if(kReleaseMode){
          await AudioPlayer.clearAssetCache();
          const assetPath = 'assets/audio/cotizaciones.mp3';
          await player.setVolume(1.0);
          player.setAudioSource(
            AudioSource.uri(Uri.parse('asset:///$assetPath')),
            initialPosition: Duration.zero, preload: true
          );
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
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
              StatusBarr(player: player)
            ],
          )
        ),
      )
    );
  }
}