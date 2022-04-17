import 'package:flutter/material.dart';

class AlertasConsola extends StatefulWidget {
  const AlertasConsola({ Key? key }) : super(key: key);

  @override
  State<AlertasConsola> createState() => _AlertasConsolaState();
}

class _AlertasConsolaState extends State<AlertasConsola> {

  @override
  Widget build(BuildContext context) {
    
    return const SizedBox(
      child: Text('alertas', style: TextStyle(color: Colors.white)),
    );
  }
}