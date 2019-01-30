import 'dart:async';
import 'package:flutter/material.dart';
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Study Studio", 
                style: TextStyle(fontFamily: "Audiowide", fontSize: 36.0),
              ),
              Padding(padding: EdgeInsets.all(4.0),),
              Text("Explore the endless possibilities!", 
                style: TextStyle(fontFamily: "CarterOne", fontSize: 18.0),
              ),
              Padding(padding: EdgeInsets.all(12.0),),
              CircularProgressIndicator()
            ],
          )
        ),
      );
    }
}