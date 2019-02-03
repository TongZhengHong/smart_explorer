import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_explorer/main.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  static String tag = "login_page_avatar";
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
  final _usernameControl = TextEditingController();
  final _passwordControl = TextEditingController();

  @override
  void dispose() {
    _usernameControl.dispose();
    _passwordControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: "hero",
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 64.0,
        child: Image.asset('images/vs_code.png'),
      ),
    );

    final Widget usernameTextField = Theme(
        data: ThemeData(primaryColor: global.blue),
        child: TextField(
          controller: _usernameControl,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: global.blue)),
            border: OutlineInputBorder(),
            labelText: "Student ID",
            labelStyle: TextStyle(fontFamily: "Nunito",),
          ),
        ));

    final Widget passwordTextField = Theme(
      data: ThemeData(primaryColor: global.blue,),
      child: TextField(
        controller: _passwordControl,
        obscureText: true,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: global.blue)),
          fillColor: global.blue,
          border: OutlineInputBorder(),
          labelText: "Password",
          labelStyle: new TextStyle(fontFamily: "Nunito",),
        )
      )
    );

    void _showDialog(String str) {
      // flutter defined function
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: new Text(str),
            content: new Text(""),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new FlatButton(
                child: new Text("Close"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    login(String username, String password) async {
      if (username == "") {
        _showDialog("Username cannot be empty");
        print("Username cannot be empty");
        return;
      }
      String url = 'https://tinypingu.infocommsociety.com/login2';
      await http
          .post(url, body: {"username": username, "password": password}).then(
              (dynamic response) async {
        if (response.statusCode == 200) {
          //_showDialog("Successful Login");
          print("Successful Login");
          global.studentID = username;
          String rawCookie = response.headers['set-cookie'];
          int index = rawCookie.indexOf(';');

         global.cookie =
              (index == -1) ? rawCookie : rawCookie.substring(0, index);
          Post temp = new Post.fromJson(json.decode(response.body));
          global.studentName = temp.name;
          global.studentEmail = temp.email;

         List<String> info = [global.studentID, global.studentName, global.studentEmail];
         SharedPreferences prefs = await SharedPreferences.getInstance();
         await prefs.setStringList("AuthDetails", info);
         await prefs.setString(global.pref_cookie, global.cookie);

          Route route = MaterialPageRoute(builder: (context) => MainPage());
          Navigator.pushReplacement(context, route);
        } else if (response.statusCode == 400) {
          _showDialog("Wrong Username or Password");
          print("Wrong Username or Password");
        } else {
          _showDialog(":(");
          print(":(");
        }
      });
    }

    final Widget button = Container(
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
        child: new InkWell(
          onTap: () {
            login(_usernameControl.text, _passwordControl.text);
            print("Login clicked!");
          },
          borderRadius: BorderRadius.circular(28.0),
          child: new Center(
            child: new Center(
              child: new Text(
                "Login!",
                style: new TextStyle(
                  fontFamily: "Nunito",
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      )
    );

    return new Scaffold(
      resizeToAvoidBottomPadding: true,
      backgroundColor: global.backgroundWhite,
      body: new Center(
        child: new ListView(
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
            button,
          ],
        ),
      ),
    );
  }
}