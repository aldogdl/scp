import 'package:flutter/material.dart';
import 'package:scp/src/pages/widgets/texto.dart';

// import 'package:mime/mime.dart';
// import 'package:http_parser/http_parser.dart' show MediaType;

class OrdsEnProcs extends StatelessWidget {

  const OrdsEnProcs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.only(left: 10),
      width: MediaQuery.of(context).size.width * 0.22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.black.withOpacity(0.5),
              border: Border.all(color: const Color.fromARGB(255, 78, 78, 78))
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    Texto(
                      txt: 'MODELO VEHÍCULO', txtC: Colors.amber,
                    ),
                    Spacer(),
                    Texto(
                      txt: '2022', txtC: Colors.white, isBold: true,
                    )
                  ],
                ),
                Row(
                  children: const [
                    Texto(
                      txt: 'MARCA AUTO', sz: 12,
                    ),
                    SizedBox(width: 10),
                    Texto(
                      txt: 'NACIONAL', sz: 12,
                    )
                  ],
                ),
                const SizedBox(height: 3),
                const Divider(height: 5, color: Color.fromARGB(255, 50, 114, 52)),
                const SizedBox(height: 3),
                Row(
                  children: const [
                    Texto(
                      txt: 'ID. Ord: 0', sz: 11,
                    ),
                    SizedBox(width: 7),
                    Texto(
                      txt: 'Cant. Pzas: 0', sz: 11,
                    ),
                    SizedBox(width: 10),
                    Texto(
                      txt: 'Cant. Ftos: 0', sz: 11,
                    ),
                    Spacer(),
                    Icon(Icons.extension, color: Colors.blue, size: 15),
                    SizedBox(width: 8),
                    Texto(
                      txt: 'GEN', sz: 11, txtC: Colors.orange, isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Divider(height: 5, color: Colors.green),
                const SizedBox(height: 5),
                Row(
                  children: const [
                    Icon(Icons.settings, color: Colors.green, size: 15),
                    SizedBox(width: 8),
                    Texto(
                      txt: 'Próximamente...', sz: 11, txtC: Color.fromARGB(255, 241, 241, 158)
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      )
    );
  }

  ///
  Future<void> _upAllImages() async {
    
    // for (var i = 0; i < result.files.length; i++) {
      
      // final filePath = result.files[i].path;
      // if(filePath != null) {
      //   final mimeType = lookupMimeType(filePath);
      //   final contentType = mimeType != null ? MediaType.parse(mimeType) : null;

      //   final fileReadStream = result.files[i].readStream;
      //   if (fileReadStream == null) {
      //     return;
      //   }
      // }

      // final stream = http.ByteStream(fileReadStream);

      // final uri = Uri.https('siasky.net', '/skynet/skyfile');
      // final request = http.MultipartRequest('POST', uri);
      // final multipartFile = http.MultipartFile(
      //   'file',
      //   stream,
      //   file.size,
      //   filename: file.name,
      //   contentType: contentType,
      // );
      // request.files.add(multipartFile);

      // final httpClient = http.Client();
      // final response = await httpClient.send(request);

      // if (response.statusCode != 200) {
      //   throw Exception('HTTP ${response.statusCode}');
      // }

      // final body = await response.stream.transform(utf8.decoder).join();
    // }
  }

}