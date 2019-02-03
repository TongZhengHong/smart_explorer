import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const timeout = const Duration(seconds: 3);

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
    Timer(timeout, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      global.cookie = prefs.getString(global.pref_cookie) ?? "";
      List<String> info_list = prefs.getStringList(global.auth_details) ?? [];
      global.studentID = info_list.isEmpty ? "" : info_list[0];

      Route route = MaterialPageRoute(builder: (context) => (global.cookie) == "" ? LoginPage() : MainPage());
      Navigator.push(_context, route);
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