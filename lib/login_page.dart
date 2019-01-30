import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_explorer/main.dart';
import 'package:smart_explorer/global.dart' as global;
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
//testing
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

    final Widget username = TextField(
      controller: _usernameControl,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide(color: global.blue)),
          labelText: "Student ID",
          labelStyle: TextStyle(fontFamily: "Nunito", color: global.blue),
          ),
    );

    final Widget password = TextField(
      controller: _passwordControl,
      obscureText: true,
      decoration: InputDecoration(
        fillColor: global.blue,
          border: OutlineInputBorder(),
          labelText: "Password",
          labelStyle: new TextStyle(fontFamily: "Nunito", color: global.blue),)
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

    login(String username1, String password1) async {
      if (username1 == "") {
        _showDialog("Username cannot be empty");
        print("Username cannot be empty");
        return;
      }
      String url = 'https://tinypingu.infocommsociety.com/login2';
      await http
          .post(url, body: {"username": username1, "password": password1}).then(
              (dynamic response) {
        if (response.statusCode == 200) {
          //_showDialog("Successful Login");
          print("Successful Login");
          global.studentID = username1;
          String rawCookie = response.headers['set-cookie'];
          int index = rawCookie.indexOf(';');
          global.cookie =
              (index == -1) ? rawCookie : rawCookie.substring(0, index);
          Post temp = new Post.fromJson(json.decode(response.body));
          global.studentName = temp.name;
          global.studentEmail = temp.email;
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

    final Widget button = new Container(
        decoration: BoxDecoration(
          gradient: global.blueButtonGradient,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 4.0, offset: Offset(2.0, 2.0)),
          ],
        ),
        height: 48.0,
        child: Material(
          color: Colors.transparent,
          child: new InkWell(
            onTap: () {
              login(_usernameControl.text, _passwordControl.text);
              print("Login clicked!");
            },
            borderRadius: BorderRadius.circular(24.0),
            child: new Center(
              child: new Center(
                child: new Text(
                  "Login!",
                  style: new TextStyle(
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ));

    return new Scaffold(
      resizeToAvoidBottomPadding: true,
      backgroundColor: Colors.white,
      body: new Center(
        child: new ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          children: <Widget>[
            logo,
            SizedBox(
              height: 16.0,
            ),
            username,
            SizedBox(
              height: 16.0,
            ),
            password,
            SizedBox(
              height: 32.0,
            ),
            button,
          ],
        ),
      ),
    );
  }
}
