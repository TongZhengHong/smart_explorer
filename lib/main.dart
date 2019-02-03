import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/subject_map.dart';
import 'package:smart_explorer/subject_popup.dart';
import 'package:smart_explorer/settings.dart';
import 'package:smart_explorer/profile.dart';

import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

//!Run splash screen on load!
void main() => runApp(Splash());

const timeout = const Duration(seconds: 5);

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  //var _context;
  double _card_height = global.phoneHeight*0.3;

  void _select(Choice choice) async {
    print(choice.title);
    if (choice.title == "Log out") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      global.studentID = "";
      global.cookie = "";
      await prefs.setStringList(global.auth_details, []);
      await prefs.setString(global.pref_cookie, global.cookie);

      Route route = MaterialPageRoute(builder: (context) => LoginPage());
      Navigator.pushReplacement(context, route);
    } else if (choice.title == "Profile") {
      Route route = MaterialPageRoute(builder: (context) => ProfilePage());
      Navigator.push(context, route);
    } else if (choice.title == "Settings") {
      Route route = MaterialPageRoute(builder: (context) => SettingsPage());
      Navigator.push(context, route);
    }
    return;
  }

  Widget _buildPage({int index}) {
    void update(int index) async {
      String url = 'https://tinypingu.infocommsociety.com/subjectprogress';
      print("Student ID: " + global.studentID);
      print("Cookie: " + global.cookie);
      await http.post(url,
          body: {"ID": global.studentID},
          headers: {"cookie": global.cookie}).then((dynamic response) {
        if (response.statusCode == 200) {
          print("Successful Data Transfer");
          Post temp = Post.fromJson(json.decode(response.body));
          global.overallProgress[index] = temp.overallProgress;
          global.totalScore[index] = temp.tScore;
        } else {
          print(response.statusCode);
          print("hi2");
          print(":(");
          global.studentID = "";
          global.cookie = "";
          Route route = MaterialPageRoute(builder: (context) => LoginPage());
          Navigator.pushReplacement(context, route);
        }
      });
    }

    update(index);
    print("Testing: " + global.overallProgress[index].toString());
    return Container(
        height: double.maxFinite,
        alignment: AlignmentDirectional.center,
        child: Stack(children: <Widget>[
          Positioned(
            child: Align(
                alignment: FractionalOffset.topCenter,
                child: Container(
                  padding: EdgeInsets.only(top: 56.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    radius: 64.0,
                  ),
                )),
          ),
          Positioned(
            child: Align(
              alignment: FractionalOffset.bottomCenter,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  double position = global.phoneHeight - details.globalPosition.dy;
                  // setState(() {
                  //   if (position < global.phoneHeight)
                  //     _card_height = global.phoneHeight;
                  //   else if (position > global.phoneHeight / 2)
                  //     _card_height = global.phoneHeight / 2;
                  //   else
                  //     _card_height = position;
                  // });
                  print(position);
                },
                child: SizedBox(
                  height: _card_height,
                  width: global.phoneWidth * 0.9,
                  child: Material(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.0),
                        topRight: Radius.circular(16.0)),
                    color: Theme.of(context).cardColor,
                    elevation: 2.0,
                    child: InkWell(
                      //onTap: () {},
                      child: Column(children: <Widget>[
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.grey,
                        ),
                        Text(
                          global.subjects[index],
                          style:
                              TextStyle(fontFamily: "Nunito", fontSize: 20.0),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.30,
                              0, global.phoneWidth * 0.30, 0),
                          child: Divider(
                            color: Colors.grey,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Row(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 16.0),
            ),
            Text(
              "Studious",
              style: TextStyle(
                  color: Colors.black, fontFamily: "Audiowide", fontSize: 20.0),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: PageView(
        onPageChanged: (index) {
          global.subindex = index;
        },
        children: [
          _buildPage(index: 0),
          _buildPage(index: 1),
          _buildPage(index: 2),
          _buildPage(index: 3),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: global.createGradientButton(global.blueGradient, 56,
          global.phoneWidth * 0.5, context, SubjectMap(), "Explore!"),
      bottomNavigationBar: BottomAppBar(
        elevation: 10.0,
        color: global.appBarLightBlue,
        child: Container(
          height: global.bottomAppBarHeight,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              PopupMenuButton<Choice>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.blueGrey.shade500,
                ),
                onSelected: _select,
                //offset: Offset(0, -120),
                itemBuilder: (BuildContext context) {
                  return choices.map((Choice choice) {
                    return PopupMenuItem<Choice>(
                      value: choice,
                      child: Text(choice.title),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Post {
  final double overallProgress;
  final int tScore;

  Post({this.overallProgress, this.tScore});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      overallProgress: json['percent'],
      tScore: json['score'],
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Profile', icon: Icons.person),
  const Choice(title: 'Settings', icon: Icons.settings),
  const Choice(title: 'Log out', icon: Icons.power_settings_new),
];
