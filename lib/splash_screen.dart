import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_explorer/main.dart';
import 'package:smart_explorer/subject_map.dart';
import 'package:smart_explorer/login_page.dart';

const timeout = const Duration(seconds: 5);

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new MyHome()
    );
  }
}

class MyHome extends StatelessWidget {
  var _context;

  MyHome() {
    Timer(timeout, () {
      Route route = MaterialPageRoute(builder: (context) => LoginPage());
      Navigator.pushReplacement(_context, route);
    });
  }

  @override
    Widget build(BuildContext context) {
      _context = context;
      return new Scaffold(
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text("Smart Explorer"),
              new Text("Explore the endless possibilities!"),
              new CircularProgressIndicator()
            ],
          )
        ),
      );
    }
}
