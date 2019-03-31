import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

class Post {
  final String name;
  final String email;

  Post({this.name, this.email});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      name: json['Name'],
      email: json['Email'],
    );
  }
}

class LoginPageState extends State<LoginPage> {
  bool validateUsernameEmpty = false;
  bool validatePasswordEmpty = false;

  bool deleteUsername = false;
  bool showPassword = true;
  bool showPasswordIcon = false;

  bool loading = false;

  BuildContext _context;

  final _usernameControl = TextEditingController();
  final _passwordControl = TextEditingController();

  void login(String username, String password) async {
    String url = 'https://tinypingu.infocommsociety.com/api/login2';
    await http
        .post(url, body: {"username": username, "password": password}).then(
            (dynamic response) async {
      if (response.statusCode == 200) {
        loading = false;
        print("Successful Login");
        global.studentID = username;
        String rawCookie = response.headers['set-cookie'];
        int index = rawCookie.indexOf(';');

        global.cookie =
            (index == -1) ? rawCookie : rawCookie.substring(0, index);
        Post temp = new Post.fromJson(json.decode(response.body));
        global.studentName = temp.name;
        global.studentEmail = temp.email;

        List<String> info = [
          global.studentID,
          global.studentName,
          global.studentEmail
        ];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("AuthDetails", info);
        await prefs.setString(global.pref_cookie, global.cookie);

        // Route route = MaterialPageRoute(builder: (context) => MainPage());
        // Navigator.pushReplacement(context, route);
      } else if (response.statusCode == 400) {
        loading = false;
        _showDialog("Wrong Username or Password!");
        print("Wrong Username or Password!");
      } else {
        _showDialog("Unexpected login error. Please check your network");
        print("Unexpected login error");
      }
    });
  }

  void _showDialog(String str) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(str),
          content: Text(""),
          actions: <Widget>[
            FlatButton(
              child: Text("Close"),
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
    final logo = CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 64.0,
      child: Image.asset('images/vs_code.png'),
    );

//! //////////////////////////// Username Text Field ////////////////////////////
    final Widget usernameTextField = Theme(
        data: ThemeData(primaryColor: global.blue),
        child: TextField(
          onChanged: (text) {
            setState(() {
              if (text != "")
                deleteUsername = true;
              else
                deleteUsername = false;
            });
          },
          controller: _usernameControl,
          decoration: InputDecoration(
            // prefixIcon: Icon(Icons.person_outline),
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
            // enabledBorder:
            // OutlineInputBorder(borderSide: BorderSide(color: global.blue)),
            // border: OutlineInputBorder(),
            labelText: "Username",
            labelStyle: TextStyle(
              fontSize: 14.0,
            ),
            errorText:
                validateUsernameEmpty ? "Username cannot be empty" : null,
          ),
        ));

//! //////////////////////////// Password Text Field ////////////////////////////
    final Widget passwordTextField = Theme(
        data: ThemeData(
          primaryColor: global.blue,
        ),
        child: TextField(
            onChanged: (text) {
              setState(() {
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
              // prefixIcon: Icon(Icons.lock_outline),
              // enabledBorder: OutlineInputBorder(
              // borderSide: BorderSide(color: global.blue)),
              //border: OutlineInputBorder(),
              labelText: "Password",
              labelStyle: TextStyle(
                fontSize: 14.0,
              ),
              errorText:
                  validatePasswordEmpty ? "Password cannot be empty" : null,
            )));

//! //////////////////////////// Login Button ////////////////////////////
    final Widget loginButton = Container(
        decoration: BoxDecoration(
          gradient: global.blueGradient,
          borderRadius: BorderRadius.circular(global.phoneHeight * 0.045),
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 4.0, offset: Offset(2.0, 2.0)),
          ],
        ),
        width: global.phoneWidth * 0.6,
        height: global.phoneHeight * 0.09,
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
                //TODO login(_usernameControl.text, _passwordControl.text);
                print("Login clicked!");
              }
            },
            borderRadius: BorderRadius.circular(global.phoneHeight * 0.045),
            child: Center(
              child: Center(
                child: !loading
                    ? Text(
                        "Login",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 18.0,
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
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            Container(
              height: global.phoneHeight,
              width: global.phoneWidth,
            ),
            Container(
                height: global.phoneHeight * 0.5,
                width: global.phoneWidth,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5.0,
                      offset: const Offset(5.0, 0.0),
                      color: Colors.grey,
                    )
                  ],
                  gradient: LinearGradient(
                    colors: [Color(0xFF78B5FA), Color(0xFF9586FD)],
                    end: Alignment.topCenter,
                    begin: Alignment.bottomCenter,
                  ),
                )),
            Positioned(
              top: global.phoneHeight * 0.15,
              height: global.phoneHeight * 0.2,
              width: global.phoneHeight * 0.2,
              child: FlutterLogo(),
            ),
            Positioned(
              top: global.phoneHeight * 0.4,
              child: Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Container(
                    height: global.phoneHeight * 0.45,
                    width: global.phoneWidth * 0.8,
                  ), 
                  SizedBox(
                    width: global.phoneWidth * 0.8,
                    height: global.phoneHeight * 0.405,
                    child: Material(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      color: Theme.of(context).cardColor,
                      elevation: 2.0,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.only(top: 28.0),
                                child: Text("Welcome!", 
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Nunito",
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: usernameTextField,
                            ),
                            Expanded(
                              flex: 4,
                              child: passwordTextField,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    child: loginButton,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}