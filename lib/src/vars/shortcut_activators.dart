import 'package:flutter/material.dart' show LogicalKeySet, Intent;
import 'package:flutter/services.dart' show LogicalKeyboardKey;

final showActionMain = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.keyP,
);
class ShowActionMainIntent extends Intent{}

final searchElement = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.keyB,
);
class SearchElement extends Intent{}

final downElement = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.keyD,
);
class DownElement extends Intent{}

final sigFoto = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.arrowRight
);
class SigFoto extends Intent{}

final backFoto = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.arrowLeft
);
class BackFoto extends Intent{}

final zoomFoto = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.arrowUp
);
class ZoomFoto extends Intent{}

final dismFoto = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.arrowDown
);
class DismFoto extends Intent{}

final editPza = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.keyE
);
class EditPza extends Intent{}

final prevPza = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.arrowUp
);
class PrevPza extends Intent{}

final nextPza = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.arrowDown
);
class NextPza extends Intent{}

final bskOrd = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.keyB
);
class BskOrd extends Intent{}

final salirPop = LogicalKeySet(
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.keyO
);
class SalirPop extends Intent{}
