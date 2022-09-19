import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../providers/invirt_provider.dart';
import '../../../../services/get_path_images.dart';

class PortadaImg extends StatefulWidget {

  const PortadaImg({Key? key}) : super(key: key);

  @override
  State<PortadaImg> createState() => _PortadaImgState();
}

class _PortadaImgState extends State<PortadaImg> {

  bool _isInit = false;
  late Future<String> _getPathImg;

  @override
  void initState() {
    _getPathImg = _getImgPath();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {

    if(!_isInit) {
      _isInit = true;
      Future.microtask(() {
        context.read<InvirtProvider>().cleanVars();
      });
    }

    return Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: FutureBuilder<String?>(
        future: _getPathImg,
        builder: (_, AsyncSnapshot snap) {

          if(snap.connectionState == ConnectionState.done) {
            return CachedNetworkImage(
              imageUrl: (snap.hasData) ? snap.data : '0',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const Image(
                image: AssetImage('assets/logo_1024.png'),
              ),
            );
          }

          return const SizedBox.expand(
            child: Center(child: CircularProgressIndicator()),
          );
        },
      )
    );
  }

  ///
  Future<String> _getImgPath() async => await GetPathImages.getPathPortada() ?? '';
}