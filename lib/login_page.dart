import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_explorer/internet.dart';
import 'package:smart_explorer/main.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  bool validateUsernameEmpty = false;
  bool validatePasswordEmpty = false;

  bool deleteUsername = false;
  bool showPassword = true;
  bool showPasswordIcon = false;

  bool loading = false;
  bool isOffline = false;

  BuildContext _context;

  final _usernameControl = TextEditingController();
  final _passwordControl = TextEditingController();

  ConnectionStatusSingleton connectionStatus;

  @override
  initState() {
    super.initState();
    connectionStatus = ConnectionStatusSingleton.getInstance();
  }

  void getPageInfo() async {
    if (!await connectionStatus.checkConnection()) {      //If not connected!
      print("Login: Not connected!");
      _showDialog("Oh no!", "Something went wrong! Please check your Internet connection!");
      setState(() {
        loading = false;
      });
      return;
    }

    String url = 'https://tinypingu.infocommsociety.com/api/studentinfo';
    await http.post(url, headers: {"cookie": global.cookie}).then(
        (dynamic response) async {
      if (response.statusCode == 200) {
        print("Login: Retrieved page info!");
        final responseMap = json.decode(response.body);
        print(responseMap);
        print("Login: SUCCESS");
        Route route = MaterialPageRoute(builder: (context) => MainPage(loginInfo: global.LoginInfo(responseMap)));
        Navigator.pushReplacement(context, route);

      } else {
        setState(() {
          loading = false;
        });
        print("Login: Error when retrieving page info");
        _showDialog("Error", "Unexpected login error");

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("AuthDetails", []);
        await prefs.setString(global.pref_cookie, global.cookie);

        global.studentID = "";
        global.cookie = "";
      }
    });
  }

  void login(String username, String password) async {
    if (!await connectionStatus.checkConnection()) {      //If not connected!
      print("Login: Not connected!");
      _showDialog("Oh no!", "Something went wrong! Please check your Internet connection!");
      setState(() {
        loading = false;
      });
      return;
    }

    String url = 'https://tinypingu.infocommsociety.com/api/login-student';
    await http.post(url, body: {"username": username, "password": password}).then(
            (dynamic response) async {
      if (response.statusCode == 200) {
        print("Login: Correct username & password");
        global.studentID = username;
        String rawCookie = response.headers['set-cookie'];
        print("Cookie:");
        print(rawCookie);

        print("Login: Cookie Set!");

        int index = rawCookie.indexOf(';');

        global.cookie =
            (index == -1) ? rawCookie : rawCookie.substring(0, index);
        final responseMap = json.decode(response.body);
        print(responseMap);
        global.studentName = responseMap["Name"];
        global.studentEmail = responseMap["Email"];

        print(global.studentName);
        print(global.studentEmail);
        print("Login: Student info retrieved!!!!!");

        List<String> info = [
          global.studentID,
          global.studentName,
          global.studentEmail
        ];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("AuthDetails", info);
        await prefs.setString(global.pref_cookie, global.cookie);
        
        //Request for subject information of the student
        getPageInfo();

      } else if (response.statusCode == 400) {
        setState(() {
          loading = false;
        });
        _showDialog("Did you forget?", "Wrong username or password!");
        print("Login: Wrong Username or Password!");
      } else {
        setState(() {
          loading = false;
        });
        _showDialog("Error", "Unexpected login error.");
        print("Login: Unexpected login error");
      }
    });
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
          content: Text(content),
          actions: <Widget>[
            FlatButton(
              child: Text("OKAY"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameControl.dispose();
    _passwordControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

//! //////////////////////////// Username Text Field ////////////////////////////
    final Widget usernameTextField = Theme(
        data: ThemeData(primaryColor: Colors.black38),
        child: TextField(
          onChanged: (text) {
            setState(() {
              validateUsernameEmpty = false;
              if (text != "")
                deleteUsername = true;
              else
                deleteUsername = false;
            });
          },
          controller: _usernameControl,
          decoration: InputDecoration(
            suffixIcon: deleteUsername
                ? IconButton(
                    onPressed: () {
                      _usernameControl.text = "";
                      setState(() {
                        deleteUsername = false;
                      });
                    },
                    icon: Icon(
                      Icons.backspace,
                    ),
                    color: Colors.grey,
                  )
                : null,
            fillColor: Colors.black26,
            labelText: "Username",
            labelStyle: TextStyle(
              fontSize: 14.0,
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: global.blue),
            ),
            focusedErrorBorder: UnderlineInputBorder(),
            errorText:
                validateUsernameEmpty ? "Can't be empty" : null,
          ),
        ));

//! //////////////////////////// Password Text Field ////////////////////////////
    final Widget passwordTextField = Theme(
        data: ThemeData(
          primaryColor: Colors.black38,
        ),
        child: TextField(
            onChanged: (text) {
              setState(() {
                validatePasswordEmpty = false;
                if (text != "")
                  showPasswordIcon = true;
                else
                  showPasswordIcon = false;
              });
            },
            controller: _passwordControl,
            obscureText: showPassword,
            decoration: InputDecoration(
              suffixIcon: showPasswordIcon
                  ? IconButton(
                      icon: showPassword
                          ? Icon(Icons.visibility_off)
                          : Icon(Icons.visibility),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    )
                  : null,
              fillColor: Colors.black38,
              labelText: "Password",
              labelStyle: TextStyle(
                fontSize: 14.0,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: global.blue),
              ),
              focusedErrorBorder: UnderlineInputBorder(),
              errorText:
                  validatePasswordEmpty ? "Can't be empty" : null,
            )));

//! //////////////////////////// Login Button ////////////////////////////
    final Widget loginButton = Container(
        decoration: BoxDecoration(
          gradient: global.blueButtonGradient,
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 8.0, offset: Offset(2.0, 2.0)),
          ],
        ),
        width: global.phoneWidth - 64.0, //Minus the padding of 32.0px on both sides
        height: 56.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                validateUsernameEmpty =
                    (_usernameControl.text != "") ? false : true;
                validatePasswordEmpty =
                    (_passwordControl.text != "") ? false : true;
              });
              if (_usernameControl.text != "" && _passwordControl.text != "") {
                setState(() {
                  loading = true;
                });
                login(_usernameControl.text, _passwordControl.text);
              }
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Center(
              child: Center(
                child: !loading
                    ? Text(
                        "SIGN IN",
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : SizedBox(
                        height: global.phoneHeight * 0.03,
                        width: global.phoneHeight * 0.03,
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(accentColor: Colors.white),
                          child: CircularProgressIndicator(strokeWidth: 3.0,),
                        ),
                      ),
              ),
            ),
          ),
        )
      );

//! //////////////////////////// return Page ////////////////////////////
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: global.backgroundWhite,
      body: SingleChildScrollView(
        child: Container(
          width: global.phoneWidth,
          height: global.phoneHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              // SizedBox(
              //   height: global.phoneHeight * 0.05,
              // ),
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 32.0),
              //   child: Text("Studious", style: TextStyle(fontFamily: "CarterOne", fontSize: 20.0),),
              // ),
              SizedBox(
                height: global.phoneHeight * 0.3,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text("Hello there!", style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w800)),
              ),
              SizedBox(
                height: 12.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text("Explore the endless possibilities...", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: Colors.black38),),
              ),
              SizedBox(
                height: global.phoneHeight * 0.1,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: usernameTextField,
              ),
              SizedBox(
                height: global.phoneHeight * 0.03,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: passwordTextField,
              ),
              SizedBox(
                height: global.phoneHeight * 0.15,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: loginButton,
              )
            ],
          ),
        )
      ),
    );
  }
}