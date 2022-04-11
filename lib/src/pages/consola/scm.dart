import 'package:flutter/material.dart';

class ScmConsola extends StatefulWidget {
  const ScmConsola({ Key? key }) : super(key: key);

  @override
  State<ScmConsola> createState() => _ScmConsolaState();
}

class _ScmConsolaState extends State<ScmConsola> {

  @override
  Widget build(BuildContext context) {
    
    return const SizedBox(
      child: Text('scm', style: TextStyle(color: Colors.white),),
    );
  }
}