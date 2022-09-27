import 'package:flutter/material.dart';

class MyNavigatorRail extends StatefulWidget {

  final ValueChanged<String> onSelected;
  const MyNavigatorRail({
    Key? key,
    required this.onSelected
  }) : super(key: key);

  @override
  State<MyNavigatorRail> createState() => MyNavigatorRailState();
}

class MyNavigatorRailState extends State<MyNavigatorRail> {
  
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    
    return SizedBox(
      width: 50,
      child: NavigationRail(
        selectedIndex: _selected,
        onDestinationSelected: (secc) => setState(() {
          _selected = secc;
          switch (_selected) {
            case 0:
              widget.onSelected('marcas');
              break;
            case 1:
              widget.onSelected('modelos');
              break;
            case 2:
              widget.onSelected('piezas');
              break;
            case 3:
              widget.onSelected('tests');
              break;
            default:
          }
        }),
        destinations: _lstDestinos(),
      ),
    );
  }

  ///
  List<NavigationRailDestination> _lstDestinos() {

    return const [
      NavigationRailDestination(
        padding: EdgeInsets.all(0),
        icon: Icon(Icons.car_rental_sharp),
        label: Text('Marcas'),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.all(0),
        icon: Icon(Icons.car_repair),
        label: Text('Modelos'),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.all(0),
        icon: Icon(Icons.extension),
        label: Text('Piezas'),
      ),
      NavigationRailDestination(
        padding: EdgeInsets.all(0),
        icon: Icon(Icons.search),
        label: Text('Tests'),
      ),
    ];
  }
}