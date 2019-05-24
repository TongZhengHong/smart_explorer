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

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarBrightness: Brightness.light // Light == Black status bar -- for IOS.
  ));
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

  double backgroundOpacity = 0.0;
  int duration = 0;

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

  void getChapData(int subIndex) async {
    if (!await connectionStatus.checkConnection()) {
      print("Login: Not connected!"); //If not connected!
      setState(() {
        loading = false;
      });
      return;
    }

    final String mapUrl =
        "https://tinypingu.infocommsociety.com/api/exploremap";
    await http.post(mapUrl, headers: {
      "Cookie": global.cookie
    }, body: {
      "courseCode": widget.loginInfo[subIndex]["courseCode"]
    }).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body);
        // responseArr.forEach((subject) {
        // subject_map.chapData = subject["children"];
        // subject_map.activity_positions = [];

        // final random = new Random();
        // subject_map.chapData[0]["children"].forEach((activity) {
        //   int padding = random.nextInt(global.phoneWidth.toInt()-36);
        //   subject_map.activity_positions.add(padding.toDouble());
        // });
        // }); //This is to get the first subject which is Econs
        print("Main: Successly retrieved explore map info!");
        Route route = MaterialPageRoute(
            builder: (context) => SubjectMap(mapInfo: responseMap));
        Navigator.push(context, route);
      } else {
        print("Main: " + response.statusCode.toString());
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
                color: Colors.grey, blurRadius: 4.0, offset: Offset(1.0, 2.0)),
          ],
        ),
        width: global.phoneWidth * 0.55, //Minus the padding of 32.0px on both sides
        height: 48.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                loading = true;
              });
              this.getChapData(global.subindex);
            }, //OnTap
            borderRadius: BorderRadius.circular(24.0),
            child: Center(
              child: Center(
                child: !loading
                    ? Text(
                        "Explore!",
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            fontFamily: "PoppinsBold"),
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

    Future<bool> _onWillPop() {
      if (backgroundOpacity == 0.6) { //Card is expanded!
        listKeys[currentPage]
          .currentState
          .changeCard(global.phoneWidth * 0.2 + 160.0, 0.0, -1);
        return Future<bool>.value(false);
      } else {
        return Future<bool>.value(true);
      }
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(
              global.phoneWidth, 
              global.bottomAppBarHeight + global.statusBarHeight
            ),
          child: Stack(
            children: <Widget>[
              AnimatedOpacity(
                duration: Duration(milliseconds: duration),
                opacity: backgroundOpacity ?? 0.0,
                child: Container(
                  height: global.bottomAppBarHeight + global.statusBarHeight,
                  width: global.phoneWidth,
                  decoration: BoxDecoration(color: Colors.grey.shade800),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (backgroundOpacity == 0.6) //Card is Expanded!
                    listKeys[currentPage]
                        .currentState
                        .changeCard(global.phoneWidth * 0.2 + 160.0, 0.0, -1);
                },
                child: Container(
                  padding: EdgeInsets.only(
                      top: global.statusBarHeight + global.bottomAppBarHeight / 2 - 11,
                      left: 28.0), //Minus 11, half of font size
                  height: global.bottomAppBarHeight + global.statusBarHeight,
                  width: global.phoneWidth,
                  child: Text("Studious",
                      style: TextStyle(
                          color: Colors.black,
                          fontFamily: "CarterOne",
                          fontSize: 22.0)),
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
              global.subindex = index;
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
      ),
    );
     
  }

  void select(Choice choice) async {
    if (choice.title == "Log out") {
      print("Main: Log out");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      global.studentID = "";
      global.cookie = "";
      await prefs.setStringList(global.auth_details, []);
      await prefs.setString(global.pref_cookie, global.cookie);

      Route route = MaterialPageRoute(builder: (context) => LoginPage());
      Navigator.pushReplacement(context, route);
    } else if (choice.title == "Profile") {
      print("Main: Profile");
      Route route = MaterialPageRoute(builder: (context) => ProfilePage());
      Navigator.push(context, route);
    } else if (choice.title == "Settings") {
      print("Main: Settings");
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
    return ExpandableCardState();
  }
}

class ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  bool cardOpen = false;
  double backgroundOpacity = 0.0;
  int duration = 0;

  static double maxCardHeight = global.phoneHeight * 0.75;
  static double minCardHeight = global.phoneWidth * 0.2 + 160.0;

  double cardHeight = minCardHeight;
  double initialCardHeight = minCardHeight;

  double startPosition;
  double delta;

  AnimationController arrowController;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<String> chapters = [];
  List<String> shownChapters = [];
  static double listTileHeight = 20.0;

  @override
  void initState() {
    chapters.add("first");
    widget.loginInfo["chapters"].forEach((chap) {
      chapters.add(chap["name"]);
      chapters.add("");
    });
    if (chapters.isNotEmpty) chapters.removeLast();
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
      //* Remove all chapter names from overview list
      for (int i = 0; i < chapters.length; i++) {
        if (shownChapters.isNotEmpty) {
          var chap = shownChapters.removeAt(0);
          _listKey.currentState.removeItem(
            0,
            (BuildContext context, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: buildOverviewBox(chap, i, false, false),
              );
            },
            duration: Duration(milliseconds: 100),
          );
        }
      }
    }

    setState(() {
      duration = 300;
      cardHeight = height;
      backgroundOpacity = opacity;
      widget.notifyParent(backgroundOpacity, duration);
    });

    if (cardOpen) {
      Timer(Duration(milliseconds: 300), () async {
        //* Populate chapter names in overview list
        for (int i = 0; i < chapters.length; i++) {
          int index = shownChapters.length;
          if (index == chapters.length) break;
          shownChapters.add(chapters[index]);
          _listKey.currentState
              .insertItem(index, duration: Duration(milliseconds: 300));
          await new Future.delayed(const Duration(milliseconds: 50));
        }
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
    double iconWidth;
    double iconPadding = 6.0;

    if (global.phoneHeight * 0.7 - 220 > global.phoneWidth * 0.75) {
      iconWidth = global.phoneWidth * 0.75;
      iconPadding = (global.phoneHeight * 0.3 - iconWidth + 160) / 2;
    }
    else iconWidth = global.phoneHeight * 0.7 - 220;

    return Stack(children: <Widget>[
      Positioned(
        child: Align(
            alignment: FractionalOffset.topCenter,
            child: Container(
              margin: EdgeInsets.only(top: iconPadding),
              height: iconWidth,
              width: iconWidth,
              child: CircleAvatar(
                backgroundImage: AssetImage('images/Econs.png'),
                backgroundColor: Colors.transparent, 
              ),
            ) 
          )
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
                elevation: 4.0,
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
                          size: 28.0,
                        ),
                        builder: (BuildContext context, Widget _widget) {
                          return Transform.rotate(
                            angle: arrowController.value,
                            child: _widget,
                          );
                        },
                      )),
                  Text(
                    widget.loginInfo["name"] ?? "",
                    style: TextStyle(
                      fontSize: 22.0,
                      fontFamily: "PoppinsSemiBold",
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: global.phoneWidth * 0.3,
                      right: global.phoneWidth * 0.3,
                      bottom: 12.0,
                    ),
                    child: Divider(
                      color: Colors.grey,
                      height: 4.0,
                    ),
                  ),
                  Text(
                    "Level " + widget.loginInfo["level"]["id"].toString() + ": " + widget.loginInfo["level"]["name"],
                    style: TextStyle(fontSize: 18.0),
                  ),
                  LinearPercentIndicator(
                    backgroundColor: Color(0x40F28752),
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                    linearStrokeCap: LinearStrokeCap.roundAll,
                    percent: widget.loginInfo["xp"] / widget.loginInfo["maxXp"],
                    progressColor: Color(0xFFF28752),
                    lineHeight: 6.0,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        buildInfoBox(widget.loginInfo["left"].toString(),
                            "activities remaining"),
                        buildInfoBox(
                            widget.loginInfo["completed"].toString() + "%",
                            "complete"),
                        buildInfoBox((widget.loginInfo["maxXp"] - widget.loginInfo["xp"]).toString(), "XP to\nlevel up!"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedList(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      key: _listKey,
                      shrinkWrap: true,
                      initialItemCount: 0,
                      itemBuilder: (BuildContext context, int index,
                          Animation animation) {
                        return FadeTransition(
                            opacity: animation,
                            child: buildOverviewBox(
                              shownChapters[index],
                              index,
                              (index == chapters.length - 1) ? true : false,
                              widget.loginInfo["done"] ?? false,
                            ));
                      },
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
            child: Padding(
          padding: EdgeInsets.all(4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(bigText,
                  style:
                      TextStyle(fontSize: 16.0, fontFamily: "PoppinsBold")),
              Text(
                smallText,
                style: TextStyle(
                  fontSize: 12.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ))),
  );
}

Widget buildOverviewBox(String chapter, int index, bool last, bool done) {
  if (index == 0) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.0, top: 8.0),
        child: Text("Overview",
        style: TextStyle(
          fontFamily: "PoppinsSemiBold"
        )
      ),
    );
  }
  return (chapter != "")
      ? ListTile(
        dense: true,
          contentPadding:
              last ? EdgeInsets.only(bottom: 20.0) : EdgeInsets.all(0.0),
          title: Text(chapter, style: TextStyle(fontSize: 14.0)),
          leading: SizedBox(
            height: 36.0,
            width: 36.0,
            child: Material(
              elevation: 2.0,
              color: Colors.transparent,
              type: MaterialType.circle,
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      done ? global.greenDiagonalGradient : global.blueGradient,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Center(
                    child: done
                        ? Icon(
                            Icons.done,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text((index ~/ 2 + 1).toString(),
                            style: TextStyle(
                                color: Colors.white, fontSize: 14.0))),
              ),
            ),
          ))
      : Container(
          height: 16.0,
          child: Container(
            margin: EdgeInsets.only(
                left: 18.0, right: global.phoneWidth * 0.9 - 67.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.0),
              color: Color(0x50000000),
            ),
          ),
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
