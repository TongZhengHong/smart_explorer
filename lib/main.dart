import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_explorer/internet.dart';

import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/subject_map.dart';
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
  ConnectionStatusSingleton connectionStatus =
      ConnectionStatusSingleton.getInstance();
  connectionStatus.initialize();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(Splash());
  });
}

const timeout = const Duration(seconds: 5);

class MainPage extends StatefulWidget {
  final dynamic loginInfo;

  MainPage({Key key, @required this.loginInfo}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  List listKeys = [];
  int currentPage = 0;

  StreamSubscription _connectionChangeStream;
  ConnectionStatusSingleton connectionStatus;

  var backgroundOpacity;
  var duration = 0;

  bool loading = false;
  bool isOffline = false;

  @override
  initState() {
    super.initState();
    connectionStatus = ConnectionStatusSingleton.getInstance();
    _connectionChangeStream =
        connectionStatus.connectionChange.listen(connectionChanged);
  }

  void connectionChanged(dynamic hasConnection) {
    setState(() {
      isOffline = !hasConnection;
    });
  }

  void getChapData() async {
    if (!await connectionStatus.checkConnection()) {
      print("Login: Not connected!"); //If not connected!
      setState(() {
        loading = false;
      });
      return;
    }

    final String mapUrl =
        "https://tinypingu.infocommsociety.com/api/exploremap";
    await http.post(
      mapUrl,
      headers: {"Cookie": global.cookie}, /*body: {"courseCode"}*/
    ).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body)[0];
        // print(responseArr);
        // responseArr.forEach((subject) {
        // subject_map.chapData = subject["children"];
        // subject_map.activity_positions = [];

        // final random = new Random();
        // subject_map.chapData[0]["children"].forEach((activity) {
        //   int padding = random.nextInt(global.phoneWidth.toInt()-36);
        //   subject_map.activity_positions.add(padding.toDouble());
        // });
        // }); //This is to get the first subject which is Econs

        final package = global.ExploreMapInfo(responseArr);
        Route route = MaterialPageRoute(
            builder: (context) => SubjectMap(mapInfo: package));
        Navigator.push(context, route);
      } else {
        print("Main: Error! Subject data not retrieved!");
      }
    });

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
//! //////////////////////////// Explore Button ////////////////////////////
    final Widget exploreButton = Container(
        decoration: BoxDecoration(
          gradient: global.blueButtonGradient,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
                color: Colors.grey, blurRadius: 8.0, offset: Offset(2.0, 2.0)),
          ],
        ),
        width:
            global.phoneWidth * 0.6, //Minus the padding of 32.0px on both sides
        height: 56.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                loading = true;
              });
              this.getChapData();
            }, //OnTap
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
                            fontFamily: "CarterOne"),
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
          ),
        ));

    refreshAppBar(newOpacity, time) {
      setState(() {
        backgroundOpacity = newOpacity;
        duration = time;
      });
    }

    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(
            global.phoneWidth, global.bottomAppBarHeight + statusBarHeight),
        child: Stack(
          children: <Widget>[
            AnimatedOpacity(
              duration: Duration(milliseconds: duration),
              opacity: backgroundOpacity ?? 0.0,
              child: Container(
                height: global.bottomAppBarHeight + statusBarHeight,
                width: global.phoneWidth,
                decoration: BoxDecoration(color: Colors.grey.shade800),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (backgroundOpacity == 0.6)
                  listKeys[currentPage]
                      .currentState
                      .changeCard(global.phoneWidth * 0.2 + 180.0, 0.0, -1);
              },
              child: Container(
                padding: EdgeInsets.only(
                    top: statusBarHeight + global.bottomAppBarHeight / 2 - 11,
                    left: 28.0), //Minus 11, half of font size
                height: global.bottomAppBarHeight + statusBarHeight,
                width: global.phoneWidth,
                child: Text("Studious",
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "CarterOne",
                        fontSize: 24.0)),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: global.backgroundWhite,
      body: PageView.builder(
          physics: backgroundOpacity == 0.0
              ? ScrollPhysics()
              : NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            currentPage = index;
          },
          itemCount: widget.loginInfo.length,
          itemBuilder: (context, i) {
            listKeys.add(new GlobalKey<ExpandableCardState>());
            return ExpandableCard(
                key: listKeys[i],
                index: i,
                loginInfo: widget.loginInfo[i],
                notifyParent: refreshAppBar);
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: exploreButton,
      bottomNavigationBar: BottomAppBar(
        elevation: 10.0,
        color: global.appBarLightBlue,
        child: Container(
          height: 64.0,
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
  final dynamic loginInfo;
  final Function(dynamic, dynamic) notifyParent;

  ExpandableCard({Key key, this.index, this.loginInfo, this.notifyParent})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ExpandableCardState(index);
  }
}

class ExpandableCardState extends State<ExpandableCard> with SingleTickerProviderStateMixin {
  int index;
  ExpandableCardState(this.index);

  bool cardOpen = false;
  double backgroundOpacity = 0.0;
  int duration = 0;

  static double maxCardHeight = global.phoneHeight * 0.75;
  static double minCardHeight = global.phoneWidth* 0.2 + 180.0;

  double cardHeight = minCardHeight;
  double initialCardHeight = minCardHeight;

  double startPosition;
  double delta;

  AnimationController arrowController;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<String> chapters = ["Hello world", "Hi I'm zheng hong", "Bye bye"];
  List<String> shownChapters = [];
  static double listTileHeight = 20.0;

  @override
  void initState() {
    arrowController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        lowerBound: 0.0,
        upperBound: Math.pi);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    arrowController?.dispose();
  }

  void changeCard(height, opacity, arrowTurn) {
    cardOpen = (opacity == 0.0) ? false : true;

    if (!cardOpen) {
      setState(() {
        shownChapters = [];
      });
    }

    setState(() {
      duration = 300;
      cardHeight = height;
      backgroundOpacity = opacity;
      widget.notifyParent(backgroundOpacity, duration);
    });

    if (cardOpen) {
      Timer(Duration(milliseconds: 300), () {
        setState(() {
          shownChapters = chapters;
        });
      });
    }

    if (arrowTurn == 1)
      arrowController.forward(from: 0.0);
    else if (arrowTurn == -1) {
      arrowController.reverse(from: 1.0);
      initialCardHeight = minCardHeight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Positioned(
        child: Align(
            alignment: FractionalOffset.topCenter,
            child: Container(
                padding: EdgeInsets.only(),
                child: Container(
                  height: global.phoneHeight * 0.7 - 224,
                  width: global.phoneHeight * 0.7 - 224,
                  child: CircleAvatar(
                    backgroundImage: AssetImage('images/Econs.png'),
                    backgroundColor: Colors.transparent,
                  ),
                ))),
      ),
      Positioned(
        child: Align(
          alignment: FractionalOffset.bottomCenter,
          child: GestureDetector(
            onTap: () {
              if (cardHeight == maxCardHeight) {
                print("Main: Close card");
                changeCard(minCardHeight, 0.0, -1);
              }
            },
            child: AnimatedOpacity(
              duration: Duration(milliseconds: duration),
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
              double position = global.phoneHeight -
                  details.globalPosition.dy; //? This is to invert the position
              delta = position - startPosition;
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
                duration = 0;
                widget.notifyParent(backgroundOpacity, duration);
              });
              
              // int index = shownChapters.length;
              // shownChapters.add(chapters[index]);
              // _listKey.currentState.insertItem(index, duration: Duration(milliseconds: 500));
            },
            onVerticalDragEnd: (details) {
              double benchmark =
                  minCardHeight + (maxCardHeight - minCardHeight) / 2;
              double velocity = details.velocity.pixelsPerSecond.dy;
              double threshold = 250;

              if (velocity > threshold) {
                print("Main: Minimise card");
                if (cardOpen)
                  changeCard(minCardHeight, 0.0, -1); //Reverse arrow
                else
                  changeCard(minCardHeight, 0.0, 0);
                initialCardHeight = minCardHeight;
              } else if (velocity < -threshold) {
                print("Main: Expand card");
                if (!cardOpen)
                  changeCard(maxCardHeight, 0.6, 1);
                else
                  changeCard(maxCardHeight, 0.6, 0);
                initialCardHeight = maxCardHeight;
              } else {
                if (cardHeight < benchmark) {
                  print("Main: Minimise card");
                  if (cardOpen)
                    changeCard(minCardHeight, 0.0, -1); //Reverse arrow
                  else
                    changeCard(minCardHeight, 0.0, 0);
                  initialCardHeight = minCardHeight;
                } else {
                  print("Main: Expand card");
                  if (!cardOpen)
                    changeCard(maxCardHeight, 0.6, 1);
                  else
                    changeCard(maxCardHeight, 0.6, 0);
                  initialCardHeight = maxCardHeight;
                }
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: duration),
              height: cardHeight,
              width: global.phoneWidth * 0.9,
              child: Material(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0)),
                color: Theme.of(context).cardColor,
                elevation: 2.0,
                child: Column(children: <Widget>[
                  InkWell(
                      borderRadius: BorderRadius.circular(16.0),
                      onTap: () {
                        if (cardOpen) {
                          print("Main: Click minimise card");
                          changeCard(minCardHeight, 0.0, -1);
                          initialCardHeight = minCardHeight;
                        } else {
                          print("Main: Click expand card");
                          changeCard(maxCardHeight, 0.6, 1);
                          initialCardHeight = maxCardHeight;
                        }
                      },
                      child: AnimatedBuilder(
                        animation: arrowController,
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.grey,
                          size: 32.0,
                        ),
                        builder: (BuildContext context, Widget _widget) {
                          return Transform.rotate(
                            angle: arrowController.value,
                            child: _widget,
                          );
                        },
                      )),
                  Text(
                    "H2 Economics" ?? "",
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ), 
                  Padding(
                    padding: EdgeInsets.only(
                      left: global.phoneWidth * 0.3,
                      right: global.phoneWidth * 0.3,
                      bottom: 16.0,
                    ),
                    child: Divider(
                      color: Colors.grey,
                      height: 4.0,
                    ),
                  ),
                  Text(
                    "Level 4: Novice",
                    style: TextStyle(fontSize: 18.0),
                  ),
                  LinearPercentIndicator(
                    backgroundColor: Color(0x40F28752),
                    padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    linearStrokeCap: LinearStrokeCap.roundAll,
                    percent: 0.5,
                    progressColor: Color(0xFFF28752),
                    lineHeight: 6.0,
                  ),
                  // SizedBox(height: 20.0),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        buildInfoBox("#10", "position"),
                        buildInfoBox("50%", "complete"),
                        buildInfoBox("6/10", "tests remaining"),
                      ],
                    ),
                  ),
                  // AnimatedList(
                  //   key: _listKey,
                  //   shrinkWrap: true,
                  //   initialItemCount: 0,
                  //   itemBuilder: (BuildContext context, int index, Animation animation) {
                  //     return FadeTransition(
                  //       opacity: animation,
                  //       child: ListTile(
                  //         title: Text(shownChapters[index]),
                  //       ),
                  //     );
                  //   },
                  // ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0,),
                      child: ListView.builder(
                        shrinkWrap: true,              
                        itemCount: shownChapters.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
                            title: Text(shownChapters[i]),
                            // subtitle: Text("data"),
                            leading: SizedBox(
                              height: 32.0,
                              width: 32.0,
                              child: Material(
                                elevation: 2.0,
                                borderRadius: BorderRadius.circular(16.0),
                                color: Colors.green,
                              ),
                            )
                          );
                        },
                      ),
                    )
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

Widget buildInfoBox(String bigText, String smallText) {
  return Container(
    height: global.phoneWidth * 0.2,
    width: global.phoneWidth * 0.2,
    padding: EdgeInsets.all(4.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4.0),
      gradient: global.bluePurpleDiagonalGradient,
      boxShadow: [
        BoxShadow(
            color: Colors.grey, blurRadius: 2.0, offset: Offset(0.0, 2.0)),
      ],
    ),
    child: Material(
        borderRadius: BorderRadius.circular(2.0),
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(bigText,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            SizedBox(height: 2.0),
            Text(smallText,
              style: TextStyle(
                fontSize: 12.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ))),
  );
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
