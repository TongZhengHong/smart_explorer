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

        Route route = MaterialPageRoute(builder: (context) => MainPage());
        Navigator.pushReplacement(context, route);
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
              fontSize: 16.0,
              fontWeight: FontWeight.w500
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: global.blue, width: 3.0),
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
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: global.blue, width: 3.0),
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
                print("Login clicked!");
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
                child: Text("Welcome Back!", style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w800)),
              ),
              SizedBox(
                height: 12.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text("There is a lot to learn", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: Colors.black38),),
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