import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'frm_seach.dart';
import '../texto.dart';
import '../../../entity/radec_entity.dart';
import '../../../repository/radec_repository.dart';

class DialogGenericas extends StatefulWidget {

  const DialogGenericas({Key? key}) : super(key: key);

  @override
  State<DialogGenericas> createState() => _DialogGenericasState();
}

class _DialogGenericasState extends State<DialogGenericas> {

  final _results = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _resultsC = ValueNotifier<int>(0);
  final _resultsW = ValueNotifier<String>('');

  final _ctrScroll = ScrollController();

  Map<String, dynamic> _cacheSearch = {};

  @override
  void dispose() {
    _results.dispose();
    _ctrScroll.dispose();
    _resultsC.dispose();
    _resultsW.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 42,
              padding: const EdgeInsets.only(left: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                border: const Border(
                  top: BorderSide(color: Color.fromARGB(255, 99, 99, 99)),
                  bottom: BorderSide(color: Color.fromARGB(255, 141, 141, 141)),
                )
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Texto(txt: 'Proveedores de Piezas Genéricas'),
                  const Spacer(),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 167, 53, 44),
                      border: Border.all(color: Colors.black, width: 2)
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: _body()
            )
          ],
        ),
      )
    );
  }

  ///
  Widget _body() {

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: FrmSearch(
            cacheSearch: _cacheSearch,
            onSearch: (buscar) async => await _makeSearch(buscar),
          ),
        ),
        Expanded(
          flex: 8,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(),
              const Divider(),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, BoxConstraints constraints) {

                    return ValueListenableBuilder(
                      valueListenable: _results,
                      builder: (_, vals, child) {
                        if(vals.isNotEmpty) {
                          return _buildListResult(vals, constraints);
                        }
                        return const Center(
                          child: Opacity(
                            opacity: 0.4,
                            child: Image(
                              image: AssetImage('assets/logo_dark.png'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                )
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _title() {

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      height: 45,
      decoration: const BoxDecoration(
        color: Colors.green,
      ),
      child: Row(
        children: [
          const Texto(
            txt: 'Lista de Resultados',
            txtC: Colors.black,
            sz: 17, isBold: true,
          ),
          const Spacer(),
          ValueListenableBuilder<int>(
            valueListenable: _resultsC,
            builder: (_, val, __) {
              return Texto(
                txt: 'Encontrados $val',
                txtC: Colors.black,
                sz: 14, isBold: true,
              );
            }
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<String>(
            valueListenable: _resultsW,
            builder: (_, String uri, __) {

              return IconButton(
                icon: Icon(
                  Icons.public,
                  color: (uri.isEmpty)
                    ? const Color.fromARGB(255, 86, 129, 88)
                    : const Color.fromARGB(255, 186, 240, 189)
                ),
                onPressed: () async => await _launchURL(_resultsW.value),
              );
            }
          ),
        ],
      ),
    );
  }

  ///
  Widget _buildListResult(List<Map<String, dynamic>> vals, BoxConstraints constraints) {

    return ListView.builder(
      itemCount: vals.length,
      controller: _ctrScroll,
      padding: const EdgeInsets.only(right: 15),
      itemBuilder: (_, int index) {
        return _tileSearchPza(vals[index], constraints);
      }
    );
  }

  ///
  Widget _tileSearchPza(Map<String, dynamic> data, BoxConstraints constraints) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(
              minHeight: 50, minWidth: 80
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: InkWell(
              onTap: () => _verFotoBig(data['imgB'], constraints),
              child: ('${data['img']}'.endsWith('no_foto.jpg'))
              ? Icon(Icons.no_photography_outlined, size: 50, color: Colors.black.withOpacity(0.5))
              : CachedNetworkImage(
                imageUrl: data['img'],
                errorWidget: (context, url, error) => const Center(
                  child: Image(image: AssetImage('assets/car-icon.png')),
                ),
                placeholder: (context, url) => const Center(
                  child: Image(image: AssetImage('assets/car-icon.png')),
                ),
              ),
            )
          ),
          Container(
            width: constraints.maxWidth * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: constraints.maxWidth * 0.7,
                  child: Text(
                    data['pza'],
                    textScaleFactor: 1,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14
                    ),
                  ),
                ),
                Texto(
                  txt: 'Aplica: ${data['apps']}',
                  txtC: Colors.green, sz: 13,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Texto(txt: '\$ ${data['cost']}')
          )
        ],
      ),
    );
  }

  ///
  Future<void> _makeSearch(Map<String, dynamic> search) async {

    _cacheSearch = search;
    final radecEm = RadecRepository();
    final entity = RadecEntity();
    _resultsW.value = entity.createQuery(search);
    final res = await radecEm.searchAutopartes(_resultsW.value);
    _resultsC.value = res.length;
    if(res.isNotEmpty) {
      _results.value = res;
    }else {
      _results.value = [];
    }
  }

  ///
  void _verFotoBig(String uri, BoxConstraints constraints) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.all(5),
        content: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: CachedNetworkImage(
            imageUrl: uri,
            alignment: Alignment.center,
            placeholder: (_, __) {
              return const Center(
                child: SizedBox(
                  width: 100, height: 100,
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        )
      )
    );
  }

  ///
  Future<void> _launchURL(String url) async {

    if (!await launchUrl(Uri.parse(url))) {
      print('Could not launch $url');
      throw 'Could not launch $url';
    }
  }
}