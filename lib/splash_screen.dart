import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:smart_explorer/global.dart' as global;
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_explorer/internet.dart';

/* 
 * Check if already logged in
 * If yes: Send PageInfo request and send todo to Main
 *  - If error --> Show error message (change layout) and show provide button to refresh
 * If no: Start timer and Direct to login page
 */

const timeout = const Duration(seconds: 3);

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(home: new MyHome());
  }
}

class MyHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyHomeState();
  }
}

class MyHomeState extends State<MyHome> {
  ConnectionStatusSingleton connectionStatus;
  var _context;

  bool hasLoggedIn = false;
  bool isOffline = false;
  bool offlineLoading = false;

  @override
  initState() {
    super.initState();
    connectionStatus = ConnectionStatusSingleton.getInstance();
  }

  MyHomeState() {
    retrievePreference();
  }

  void retrievePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    global.cookie = prefs.getString(global.pref_cookie) ?? "";
    List<String> infoList = prefs.getStringList(global.auth_details) ?? [];
    global.studentID = infoList.isEmpty ? "" : infoList[0];

    //!Check if already logged into the app
    if ((global.cookie) != "") {
      hasLoggedIn = true;
      //* If logged in previously, send request for page information
      print("Splash: Already logged in, retrieving page info...");
      getPageInfo();
    } else {
      hasLoggedIn = false;
      //* If not logged in, start timer and direct to login page
      print("Splash: Not logged in! Directing to login page...");
      Timer(timeout, () {
        Route route = MaterialPageRoute(builder: (context) => LoginPage());
        Navigator.pushReplacement(_context, route);
      });
    }
  }

  void getPageInfo() async {
    if (!await connectionStatus.checkConnection()) {      //If not connected!
      print("Splash: Not connected!");
      setState(() {
        isOffline = true;
        offlineLoading = false;
      });
      return;
    }

    print("Splash: " + global.cookie);
    String url = 'https://tinypingu.infocommsociety.com/api/studentinfo';
    print("Splash Cookie:");
    print(global.cookie);
    await http.post(url, headers: {"cookie": global.cookie}).then(
        (dynamic response) async {
      if (response.statusCode == 200) {
        print("Splash: Retrieved page info!");
        final responseArr = json.decode(response.body);

        Route route = MaterialPageRoute(
            builder: (context) => MainPage(loginInfo: responseArr));
        Navigator.pushReplacement(context, route);

      } else if (response.statusCode == 401){
        Route route = MaterialPageRoute(builder: (context) => LoginPage());
        Navigator.pushReplacement(context, route);
      }
      
      else {
        print("Splash: Error when retrieving page info");
        setState(() {
          isOffline = true;
          offlineLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    global.phoneHeight = MediaQuery.of(context).size.height;
    global.phoneWidth = MediaQuery.of(context).size.width;

    return hasLoggedIn
        ? (isOffline
            ? Scaffold(
                body: Center(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      child: Text(
                          "Oh no! Something is wrong \nwith your Internet connection!", 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16.0),),
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    RaisedButton(
                      padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                      color: global.blue,
                      child: offlineLoading
                          ? SizedBox(
                              height: global.phoneHeight * 0.03,
                              width: global.phoneHeight * 0.03,
                              child: Theme(
                                data: Theme.of(context)
                                    .copyWith(accentColor: Colors.white),
                                child: CircularProgressIndicator(strokeWidth: 3.0,),
                              ),
                            )
                          : Text("Refresh", style: TextStyle(color: Colors.white),),
                      onPressed: () {
                        setState(() {
                          offlineLoading = true;
                        });
                        Timer(const Duration(milliseconds: 500), () {
                          getPageInfo();
                        });
                      },
                    )
                  ],
                )),
              )
            : NormalSplash())

        //? Not logged in yet, show the normal splash screen before going to login page
        : NormalSplash();
  }
}

class NormalSplash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Studious",
            style: TextStyle(
              fontFamily: "CarterOne",
              fontSize: 36.0,
            ),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.all(4.0),
          ),
          Text(
            "Explore the endless possibilities!",
            style: TextStyle(fontFamily: "CarterOne", fontSize: 18.0),
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
          ),
          CircularProgressIndicator()
        ],
      )),
    );
  }
}
