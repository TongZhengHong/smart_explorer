import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_explorer/login_page.dart';

const timeout = const Duration(seconds: 5);

//!Run splash screen on load!
void main() => runApp(new Splash());

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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Smart Explorer"),
              Padding(padding: EdgeInsets.all(12.0),),
              Text("Explore the endless possibilities!"),
              Padding(padding: EdgeInsets.all(12.0),),
              CircularProgressIndicator()
            ],
          )
        ),
      );
    }
}