import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_explorer/main.dart';

const timeout = const Duration(seconds: 3);

class Splash extends StatelessWidget {
  var _context;

  Splash() {
    Timer(timeout, () {
      Navigator.of(_context).push(new MaterialPageRoute(builder: (context) {
        return new MyApp();
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return new Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Image.network(
              "https://cdn1.iconfinder.com/data/icons/app-5/48/85-512.png"),
          new Text("Smart Explorer"),
          new Text("Explore the endless possibilies"),
        ],
      ),
    );
  }
}
