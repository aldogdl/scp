import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TilePzasResult extends StatelessWidget {

  final Map<String, dynamic> pza;
  final String craw;
  final double maxWidth;
  const TilePzasResult({
    Key? key,
    required this.pza,
    required this.craw,
    required this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final Widget wd = SizedBox(
      width: 70, height: 55,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: CachedNetworkImage(
          imageUrl: pza['img'],
          fit: BoxFit.cover,
        ),
      ),
    );

    var p = pza;
    p['craw'] = craw;

    return Container(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _dragable(child: wd, data: p),
          const SizedBox(width: 10),
          SizedBox(
            width: maxWidth,
            child: SelectableText(
              pza['pza'],
              maxLines: 3,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                letterSpacing: 1.1,
                color: Colors.grey
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///
  Widget _dragable({required Widget child, required Map<String, dynamic> data}) {

    return Draggable(
      data: data,
      feedback: Container(
        width: 70, height: 55, color: Colors.grey,
        child: child,
      ),
      child: child,
    );
  }
}