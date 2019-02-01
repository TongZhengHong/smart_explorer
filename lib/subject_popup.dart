import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/main.dart';

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
      Route route = MaterialPageRoute(builder: (context) => global.cookie == "" ? LoginPage() : MainPage());
      Navigator.pushReplacement(_context, route);
    });
  }

  @override
    Widget build(BuildContext context) {
      _context = context;
      global.phoneHeight = MediaQuery.of(context).size.height;
      global.phoneWidth = MediaQuery.of(context).size.width;

      return Scaffold(
        backgroundColor: global.backgroundWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Studious", 
                style: TextStyle(fontFamily: "Audiowide", fontSize: 36.0,),
                textAlign: TextAlign.center,
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