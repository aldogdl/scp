import 'package:flutter/material.dart';

class CDataScranet extends StatelessWidget {

  const CDataScranet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Container(
          color: Colors.green,
          child: Row(
            children: const [
              Text('En construcción')
            ],
          ),
        )
      ],
    );
  }
}