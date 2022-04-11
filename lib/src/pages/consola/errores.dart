import 'package:flutter/material.dart';

class ErroresConsola extends StatefulWidget {
  const ErroresConsola({ Key? key }) : super(key: key);

  @override
  State<ErroresConsola> createState() => _ErroresConsolaState();
}

class _ErroresConsolaState extends State<ErroresConsola> {

  @override
  Widget build(BuildContext context) {
    
    return const SizedBox(
      child: Text('errores', style: TextStyle(color: Colors.white),),
    );
  }
}