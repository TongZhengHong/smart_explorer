import 'dart:async';
import 'dart:math' as Math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
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
    return LoginPageState();
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
    if (!await connectionStatus.checkConnection()) {
      //If not connected!
      print("Login: Not connected!");
      _showDialog("Oh no!",
          "Something went wrong! Please check your Internet connection!");
      setState(() {
        loading = false;
      });
      return;
    }

    print("Splash: " + global.cookie);
    String url = 'https://tinypingu.infocommsociety.com/api/studentinfo';
    await http.post(url, headers: {"cookie": global.cookie}).then(
        (dynamic response) async {
      if (response.statusCode == 200) {
        print("Login: Retrieved page info!");
        final reponseArr = json.decode(response.body);

        print("Login: SUCCESS");
        Route route = MaterialPageRoute(
            builder: (context) =>
                MainPage(loginInfo: reponseArr["subjects"]));
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
    if (!await connectionStatus.checkConnection()) {
      //If not connected!
      print("Login: Not connected!");
      _showDialog("Oh no!",
          "Something went wrong! Please check your Internet connection!");
      setState(() {
        loading = false;
      });
      return;
    }

    print("Splash: " + global.cookie);
    String url = 'https://tinypingu.infocommsociety.com/api/login-student';
    await http
        .post(url, body: {"username": username, "password": password}).then(
            (dynamic response) async {
      if (response.statusCode == 200) {
        print("Login: Correct username & password");
        global.studentID = username;
        String rawCookie = response.headers['set-cookie'];
        int index = rawCookie.indexOf(';');

        global.cookie =
            (index == -1) ? rawCookie : rawCookie.substring(0, index);
        final responseMap = json.decode(response.body);
        global.studentName = responseMap["Name"];
        global.studentEmail = responseMap["Email"];


        SharedPreferences prefs = await SharedPreferences.getInstance();
        // await prefs.setStringList("AuthDetails", info);
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
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          style: TextStyle(fontFamily: "Rubik"),
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
              fontFamily: "Rubik",
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: global.blue),
            ),
            focusedErrorBorder: UnderlineInputBorder(),
            errorText: validateUsernameEmpty ? "Can't be empty" : null,
          ),
        ));

//! //////////////////////////// Password Text Field ////////////////////////////
    final Widget passwordTextField = Theme(
        data: ThemeData(
          primaryColor: Colors.black38,
        ),
        child: TextField(
          style: TextStyle(fontFamily: "Rubik"),
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
                fontFamily: "Rubik",
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: global.blue),
              ),
              focusedErrorBorder: UnderlineInputBorder(),
              errorText: validatePasswordEmpty ? "Can't be empty" : null,
            )));

//! //////////////////////////// Login Button ////////////////////////////
    final Widget loginButton = Container(
        decoration: BoxDecoration(
          gradient: global.blueButtonGradient,
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 4.0, offset: Offset(1.0, 2.0)),
          ],
        ),
        width: global.phoneWidth - 64.0, //Minus the padding of 32.0px on both sides
        height: 56.0,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(4.0),
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
                Timer(const Duration(milliseconds: 500), () {
                  login(_usernameControl.text, _passwordControl.text);
                });
              }
            },
            child: Center(
              child: !loading
                  ? Text(
                      "SIGN IN",
                      style: TextStyle(
                        fontSize: 14.0,
                        fontFamily: "PoppinsSemiBold",
                        color: Colors.white,
                      ),
                    )
                  : SizedBox(
                      height: global.phoneHeight * 0.03,
                      width: global.phoneHeight * 0.03,
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(accentColor: Colors.white),
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                        ),
                      ),
                    ),
            ),
          ),
        ));

//! //////////////////////////// return Page ////////////////////////////
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: global.backgroundWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: ScrollConfiguration(
          behavior: MyBehavior(),
          child: SingleChildScrollView(
            child: Container(
              width: global.phoneWidth,
              height: global.phoneHeight,
              child: Stack(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      CustomPaint(
                        size: Size(global.phoneWidth, global.phoneHeight * 0.45),
                        painter: LoginPainter(),
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: usernameTextField,
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: passwordTextField,
                      ),
                      Expanded(
                        flex: 5,
                        child: Container(),
                      ),
                      Container(
                        height: global.phoneHeight * 0.1 + 56.0,
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: global.phoneHeight*0.1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: loginButton,
                    ),
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
}

class LoginPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    //! Add the ORANGE gradient
    Rect rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height * 0.4);
    Gradient gradient = LinearGradient(
        begin: FractionalOffset.topCenter,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFFFAD87B), Color(0xFFF28752)]);
    Paint paint = Paint()..shader = gradient.createShader(rect);
    final path1 = drawPathMid(size.width * 0.8, size.height * 0.3);
    canvas.drawShadow(path1, Colors.black, 2.0, true);
    canvas.drawPath(path1, paint);

    //! Add the RED gradient
    rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height * 0.6);
    gradient = LinearGradient(
        begin: FractionalOffset.topCenter,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFFF48149), Color(0xFFEB4956)]);
    paint = Paint()..shader = gradient.createShader(rect);
    final path2 = drawPathMid(size.width * 1, size.height * 0.55);
    canvas.drawShadow(path2, Colors.black, 2.0, true);
    canvas.drawPath(path2, paint);

    //! Add the GREEN gradient
    rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height * 0.25);
    gradient = LinearGradient(
        begin: FractionalOffset.topCenter,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFF4AE296), Color(0xFF57CDDB)]);
    paint = Paint()..shader = gradient.createShader(rect);
    final path3 = drawPathMid(size.width * 0.4, size.height * 0.1);
    canvas.drawShadow(path3, Colors.black, 2.0, true);
    canvas.drawPath(path3, paint);

    //! Add LEFT side LIGTHT BLUE gradient
    rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height * 0.8);
    gradient = LinearGradient(
        begin: FractionalOffset.center,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFF78B2FA), Color(0xFFCDD6F0)]);
    paint = Paint()..shader = gradient.createShader(rect);
    final path4 = drawPathSide(size.height * 0.55, size.height * 0.01, true);
    canvas.drawShadow(path4, Colors.black, 2.0, true);
    canvas.drawPath(path4, paint);

    //! Add RIGHT side BLUE PURPLE gradient
    rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height * 0.55);
    gradient = LinearGradient(
        begin: FractionalOffset.center,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]);
    paint = Paint()..shader = gradient.createShader(rect);
    final path5 = drawPathSide(size.height * 0.2, size.height * 0.01, false);
    canvas.drawShadow(path5, Colors.black, 2.0, true);
    canvas.drawPath(path5, paint);

    //! Add RIGHT side BLUE circle
    rect = Rect.fromLTRB(0.0, size.height * 0.6, size.width, size.height * 0.8);
    gradient = LinearGradient(
        begin: FractionalOffset.topCenter,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]);
    paint = Paint()..shader = gradient.createShader(rect);
    final path6 = Path();
    path6.addArc(
        Rect.fromCircle(
            center: Offset(size.width, size.height),
            radius: global.phoneWidth * 0.06),
        0,
        2 * Math.pi);
    canvas.drawShadow(path6, Colors.black, 2.0, true);
    canvas.drawPath(path6, paint);

    //! Add LEFT side BLUE circle
    rect = Rect.fromLTRB(0.0, size.height * 0.2, size.width, size.height * 0.4);
    gradient = LinearGradient(
        begin: FractionalOffset.topCenter,
        end: FractionalOffset.bottomCenter,
        colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]);
    paint = Paint()..shader = gradient.createShader(rect);
    final path7 = Path();
    path7.addArc(
        Rect.fromCircle(
            center: Offset(size.width * 0.1, size.height * 0.25),
            radius: global.phoneWidth * 0.03),
        0,
        2 * Math.pi);
    canvas.drawShadow(path7, Colors.black, 2.0, true);
    canvas.drawPath(path7, paint);

    //! Add 4 dark blue circles!
    paint = Paint();
    paint.color = global.darkBlue;
    final path8 = drawQuadCircles(size.width*0.45, size.height*0.5);
    canvas.drawShadow(path8, Colors.black, 2.0, true);
    canvas.drawPath(path8, paint);

    //! Hello there Paragraph!
    var paragraphStyle = ui.ParagraphStyle(
        fontSize: 36.0, textAlign: TextAlign.left, fontWeight: FontWeight.w800);
    var textStyle = ui.TextStyle(color: Colors.black, fontFamily: "PoppinsBold");
    var paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText('Hello there!');
    var paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width * 0.8));
    canvas.drawParagraph(paragraph, Offset(32.0, size.height * 0.85));

    //! Subtitle Paragraph!
    paragraphStyle = ui.ParagraphStyle(
        fontSize: 14.0, textAlign: TextAlign.left, fontWeight: FontWeight.w900);
    textStyle = ui.TextStyle(color: Colors.black38, fontFamily: "PoppinsSemiBold");
    paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText('Explore the endless possibilities . . .');
    paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width * 0.8));
    canvas.drawParagraph(paragraph, Offset(32.0, size.height * 0.85 + 48.0));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  Path drawPathMid(double start, double dy) {
    num degToRad(num deg) => deg * (Math.pi / 180.0);
    double angle = degToRad(30);
    double dx = dy * Math.sin(angle);
    double thick = global.phoneWidth * 0.12;
    double dthick = thick / Math.cos(angle);

    Path path = Path();

    path.moveTo(start, 0);
    path.lineTo(start - dx - dthick * Math.sin(angle) * Math.sin(angle),
        dy + dthick * Math.sin(angle) * Math.cos(angle));
    path.lineTo(start - dx - dthick, dy);
    path.lineTo(start - dthick, 0);
    path.addArc(
        Rect.fromCircle(
            center: Offset(start - dx - dthick + thick / 2 * Math.cos(angle),
                dy + thick / 2 * Math.sin(angle)),
            radius: thick / 2),
        angle,
        degToRad(180));
    path.close();

    return path;
  }

  Path drawPathSide(double start, double dy, bool top) {
    num rad(num deg) => deg * (Math.pi / 180.0);
    double angle = rad(27);
    double dx = dy * Math.tan(angle);

    double thick = global.phoneWidth * 0.12;
    double sthick = thick / Math.sin(angle);
    double cthick = thick / Math.cos(angle);

    Path path = Path();

    if (top) {
      path.moveTo(0, start);
      path.lineTo(dx + cthick * Math.sin(angle) * Math.sin(angle),
          start - dy - cthick * Math.sin(angle) * Math.cos(angle));
      path.lineTo(dx + cthick, start - dy);
      path.lineTo(0, start + sthick);
      path.addArc(
          Rect.fromCircle(
              center: Offset(dx + cthick - thick / 2 * Math.cos(angle),
                  start - dy - thick / 2 * Math.sin(angle)),
              radius: thick / 2),
          angle + Math.pi,
          Math.pi);
      path.close();
    } else {
      path.moveTo(global.phoneWidth, start);
      path.lineTo(
          global.phoneWidth - dx - sthick * Math.cos(angle) * Math.sin(angle),
          start + dy + sthick * Math.cos(angle) * Math.cos(angle));
      path.lineTo(global.phoneWidth - dx, start + dy + sthick);
      path.lineTo(global.phoneWidth, start + sthick);
      path.addArc(
          Rect.fromCircle(
              center: Offset(
                  global.phoneWidth - dx - thick / 2 * Math.cos(angle),
                  start + dy + sthick - thick / 2 * Math.sin(angle)),
              radius: thick / 2),
          angle,
          Math.pi);
      path.close();
    }

    return path;
  }
}

Path drawQuadCircles(double x, double y){
  double thick = global.phoneWidth * 0.06;
  num rad(num deg) => deg * (Math.pi / 180.0);
  double r = global.phoneWidth * 0.015;

  Path path = Path();

  Rect circle = Rect.fromCircle(center: Offset(x, y), radius: r);
  path.addArc(circle, 0, 2*Math.pi);
  circle = Rect.fromCircle(center: Offset(x-Math.sin(rad(30))*thick, y+Math.cos(rad(30))*thick), radius: r);
  path.addArc(circle, 0, 2*Math.pi);
  circle = Rect.fromCircle(center: Offset(x+Math.sin(rad(15))*thick/Math.cos(rad(45)), y+Math.cos(rad(15))*thick/Math.cos(rad(45))), radius: r);
  path.addArc(circle, 0, 2*Math.pi);
  circle = Rect.fromCircle(center: Offset(x+Math.sin(rad(60))*thick, y+Math.cos(rad(60))*thick), radius: r);
  path.addArc(circle, 0, 2*Math.pi);

  return path;
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}