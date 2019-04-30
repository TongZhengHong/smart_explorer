import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_explorer/internet.dart';

import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/subject_map.dart' as subject_map;
import 'package:smart_explorer/subject_popup.dart';
import 'package:smart_explorer/settings.dart';
import 'package:smart_explorer/profile.dart';

import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

/*
 * Architeture of main.dart:
 * getChapData --> Prepare data for explore map
 * build --> Main build
 * select --> Popup menu options
 */

//!Run splash screen on load!
void main() {
  ConnectionStatusSingleton connectionStatus = ConnectionStatusSingleton.getInstance();
  connectionStatus.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(Splash());
  });
}

const timeout = const Duration(seconds: 5);

class MainPage extends StatefulWidget {
  final Todo todo;

  MainPage({Key key, @required this.todo}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  
  bool loading = false;

  void getChapData() async {
    final String mapUrl = "https://tinypingu.infocommsociety.com/api/exploremap";
    final response = await http.post(mapUrl, headers: {"Cookie": global.cookie});

    if (response.statusCode == 200) {
      final responseArr = json.decode(response.body);
      responseArr.forEach((subject) {
        subject_map.chapData = subject["children"];
        subject_map.activity_positions = [];

        final random = new Random();
        subject_map.chapData[0]["children"].forEach((activity) {
          int padding = random.nextInt(global.phoneWidth.toInt()-36);
          subject_map.activity_positions.add(padding.toDouble());
        });
      }); //This is to get the first subject which is Econs

      setState(() {
        loading = false;
      });
    } else {
      print("Main: Error! Subject data not retrieved!");
    }
  }

  @override
  Widget build(BuildContext context) {
    Todo todo = widget.todo;
    
    print("Main: Todo");
    print(todo.subjects.length);

//! //////////////////////////// Explore Button ////////////////////////////
    final Widget exploreButton = Container(
      decoration: BoxDecoration(
        gradient: global.blueButtonGradient,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
              color: Colors.grey, blurRadius: 8.0, offset: Offset(2.0, 2.0)),
        ],
      ),
      width: global.phoneWidth * 0.6, //Minus the padding of 32.0px on both sides
      height: 48.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState((){
              loading = true;
            });
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) { 
                return subject_map.SubjectMap();
              }),
            );
          },  //OnTap
          borderRadius: BorderRadius.circular(24.0),
          child: Center(
            child: Center(
              child: !loading
                ? Text(
                    "Explore!",
                    style: TextStyle(
                      fontSize: 16.0,
                      //fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: "CarterOne"
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

    return Scaffold(
      backgroundColor: global.backgroundWhite,
      body: PageView.builder(
        onPageChanged: (index) {
          global.subindex = index;
        },
        itemCount: todo.subjects.length,
        itemBuilder: (context, i) {
          return ExpandableCard(i, todo);
        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: exploreButton,
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
                onSelected: select,
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

  void select(Choice choice) async {
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
}

class ExpandableCard extends StatefulWidget {
  final int index;
  final Todo todo;

  ExpandableCard(this.index, this.todo);

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
  double cardHeight = global.phoneHeight * 0.4;

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
                    fontFamily: "CarterOne",
                    fontSize: 24.0),
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
                setState(() {
                  cardHeight = minCardHeight;
                  backgroundOpacity = 0.0;
                });
              }
            },
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
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
                  setState(() {
                    cardHeight = minCardHeight;
                    backgroundOpacity = 0.0;
                  });
                } else {
                  //TODO: Expand the card!
                  print("Expand card");
                  setState(() {
                    cardHeight = maxCardHeight;
                    backgroundOpacity = 0.6;
                  });
                }
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
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
                    widget.todo.subjects[index],
                    style: TextStyle(fontSize: 20.0),
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