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

class LoginPageState extends State<LoginPage> with TickerProviderStateMixin{
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
    await http.post(url, body: {"username": username, "password": password}).then(
        (dynamic response) async {
      if (response.statusCode == 200) {
        loading = false;
        print("Successful Login");
        global.studentID = username;
        String rawCookie = response.headers['set-cookie'];
        int index = rawCookie.indexOf(';');

        global.cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
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
        _showDialog(context, "Wrong Username or Password");
        print("Wrong Username or Password");
      } else {
        _showDialog(context, ":(");
        print(":(");
      }
    });
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
          prefixIcon: Icon(Icons.person_outline),
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
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: global.blue)),
          border: OutlineInputBorder(),
          labelText: "Username",
          labelStyle: TextStyle(
            fontFamily: "Nunito",
          ),
          errorText: validateUsernameEmpty ? "Username cannot be empty" : null,
        ),
      )
    );

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
              prefixIcon: Icon(Icons.lock_outline),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: global.blue)),
              fillColor: global.blue,
              border: OutlineInputBorder(),
              labelText: "Password",
              labelStyle: TextStyle(
                fontFamily: "Nunito",
              ),
              errorText: validatePasswordEmpty ? "Password cannot be empty" : null,
            )));

//! //////////////////////////// Login Button ////////////////////////////
    final Widget loginButton = Container(
        decoration: BoxDecoration(
          gradient: global.blueButtonGradient,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 4.0, offset: Offset(2.0, 2.0)),
          ],
        ),
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
            borderRadius: BorderRadius.circular(28.0),
            child: Center(
              child: Center(
                child: !loading ? Text(
                  "Login!",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: Colors.white,
                  ),
                ) : CircularProgressIndicator(),
              ),
            ),
          ),
        ));

//! //////////////////////////// return Page ////////////////////////////
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      backgroundColor: global.backgroundWhite,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            logo,
            SizedBox(
              height: 16.0,
            ),
            usernameTextField,
            SizedBox(
              height: 16.0,
            ),
            passwordTextField,
            SizedBox(
              height: 24.0,
            ),
            loginButton,
          ],
        ),
      ),
    );
  }
}

void _showDialog(BuildContext context, String str) {
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
