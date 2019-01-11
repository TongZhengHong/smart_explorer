import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  static String tag = "login_page_avatar";
  @override
  State<StatefulWidget> createState() {
    return new LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  final _usernameControl = TextEditingController();
  final _passwordControl = TextEditingController();

  final _nunitoTextWhite =
      new TextStyle(color: Colors.white, fontFamily: 'Nunito', fontSize: 16.0);
  final _nunitoTextBlack =
      new TextStyle(color: Colors.black, fontFamily: 'Nunito', fontSize: 16.0);

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
          labelText: "Username",
          labelStyle: new TextStyle(fontFamily: "Nunito", color: Colors.grey),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlueAccent))),
    );

    final Widget password = TextField(
      controller: _passwordControl,
      obscureText: true,
      decoration: InputDecoration(
          labelText: "Password",
          labelStyle: new TextStyle(fontFamily: "Nunito", color: Colors.grey),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.lightBlueAccent))),
    );

    final Widget button = new Container(
        height: 48.0,
        child: new Material(
          borderRadius: BorderRadius.circular(24.0),
          shadowColor: Colors.lightBlueAccent,
          color: Colors.lightBlue,
          elevation: 4.0,
          child: new InkWell(
            onTap: () {
              print("Login clicked!");
            },
            borderRadius: BorderRadius.circular(24.0),
            child: new Center(
              child: new Center(
                child: new Text(
                  "Explore now!",
                  style: new TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 16.0,
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
