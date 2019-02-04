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
    return ExpandableCard(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: global.backgroundWhite,
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

class ExpandableCard extends StatefulWidget {
  final int index;
  ExpandableCard(this.index);

  @override
  State<StatefulWidget> createState() {
    return ExpandableCardState(index);
  }
}

class ExpandableCardState extends State<ExpandableCard> {
  int index;
  ExpandableCardState(this.index);

  double backgroundOpacity = 0.0;

  GlobalKey cardKey = GlobalKey();
  double maxCardHeight = global.phoneHeight * 0.75;
  double minCardHeight = global.phoneHeight * 0.4;
  double cardHeight = global.phoneHeight * 0.3;

  double initialCardHeight = global.phoneHeight * 0.3;
  double startPosition;
  double position;

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Positioned(
        child: Align(
            alignment: FractionalOffset.topCenter,
            child: Container(
              padding: EdgeInsets.only(top: 128.0),
              child: CircleAvatar(
                backgroundColor: Colors.redAccent,
                radius: 72.0,
              ),
            )),
      ),
      Positioned(
        child: AppBar(
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
                    color: Colors.black,
                    fontFamily: "Audiowide",
                    fontSize: 20.0),
              ),
            ],
          ),
          centerTitle: false,
        ),
      ),
      Positioned(
        child: Align(
          alignment: FractionalOffset.bottomCenter,
          child: GestureDetector(
            onTap: () {
              if (cardHeight == maxCardHeight) {
                print("Close card");
              }
            },
            child: Opacity(
              opacity: backgroundOpacity,
              child: SizedBox(
                height: global.phoneHeight - global.bottomAppBarHeight,
                width: global.phoneWidth,
                child: Container(
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        child: Align(
          alignment: FractionalOffset.bottomCenter,
          child: GestureDetector(
            onVerticalDragDown: (details) {
              startPosition = global.phoneHeight - details.globalPosition.dy;
            },
            onVerticalDragUpdate: (details) {
              position = global.phoneHeight -
                  details.globalPosition.dy; //? This is to invert the position
              double delta = position - startPosition;
              double temp = initialCardHeight + delta;
              setState(() {
                if (temp < minCardHeight) {
                  cardHeight = minCardHeight;
                } else if (temp > maxCardHeight) {
                  cardHeight = maxCardHeight;
                } else {
                  cardHeight = temp;
                }
                backgroundOpacity = (cardHeight - minCardHeight) *
                    0.6 /
                    (maxCardHeight - minCardHeight);
              });
            },
            onVerticalDragEnd: (details) {
              RenderBox cardBox = cardKey.currentContext.findRenderObject();
              initialCardHeight = cardBox.size.height;
              double benchmark =
                  minCardHeight + (maxCardHeight - minCardHeight) / 2;

              if (position > maxCardHeight) {
                initialCardHeight = maxCardHeight;
              } else if (position < minCardHeight) {
                initialCardHeight = minCardHeight;
              } else {
                if (cardHeight < benchmark) {
                  //TODO: Minimise the card!
                  print("Minimise card");
                } else {
                  //TODO: Expand the card!
                  print("Expand card");
                }
              }
            },
            child: SizedBox(
              key: cardKey,
              height: cardHeight,
              width: global.phoneWidth * 0.9,
              child: Material(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0)),
                color: Theme.of(context).cardColor,
                elevation: 2.0,
                child: Column(children: <Widget>[
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.grey,
                  ),
                  Text(
                    global.subjects[index],
                    style: TextStyle(fontFamily: "Nunito", fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.30, 0,
                        global.phoneWidth * 0.30, 0),
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
    ]);
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
