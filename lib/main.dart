import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_explorer/internet.dart';
import 'package:flutter/services.dart';

import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/explore_map.dart';
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

StreamSubscription _connectionChangeStream;
ConnectionStatusSingleton connectionStatus;

double maxCardHeight = global.phoneHeight * 0.75;
double minCardHeight = global.phoneWidth * 0.2 + 160.0;

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

  bool cardExpanded = false;
  bool exploreLoading = false;
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

  void notifyParent(bool state) {
    cardExpanded = state;
  }

  void getChapData(int pagePos) async {
    if (!await connectionStatus.checkConnection()) {
      print("Login: Not connected!"); //If not connected!
      setState(() {
        exploreLoading = false;
      });
      return;
    }

    final String mapUrl =
        "https://tinypingu.infocommsociety.com/api/exploremap";
    await http.post(mapUrl, headers: {
      "Cookie": global.cookie
    }, body: {
      "courseCode": widget.loginInfo[pagePos]["courseCode"]
    }).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body);
        print("Main: Successly retrieved explore map info!");
        Route route = MaterialPageRoute(
            builder: (context) => ExploreMap(mapInfo: responseMap));
        Navigator.push(context, route);
      } else {
        print("Main: " + response.statusCode.toString());
        print("Main: Error! Subject data not retrieved!");
      }
    });

    setState(() {
      exploreLoading = false;
    });
  }

  Future<bool> _onWillPop() {
    if (cardExpanded) { //Card is expanded!
      listKeys[currentPage]
        .currentState
        .changeCard(global.phoneWidth * 0.2 + 160.0, 0.0, -1);
      return Future<bool>.value(false);
    } else {
      return Future<bool>.value(true);
    }
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
                color: Colors.grey, blurRadius: 2.0, offset: Offset(1.0, 2.0)),
          ],
        ),
        width: global.phoneWidth * 0.55, //Minus the padding of 32.0px on both sides
        height: 48.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                exploreLoading = true;
              });
              this.getChapData(currentPage);
            }, //OnTap
            borderRadius: BorderRadius.circular(24.0),
            child: Center(
              child: Center(
                child: !exploreLoading
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: global.backgroundWhite,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(
                    top: global.statusBarHeight + global.appBarHeight / 2 - 11,
                    left: 28.0), //Minus 11, half of font size
                height: global.appBarHeight + global.statusBarHeight,
                width: global.phoneWidth,
                child: Text("Studious",
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "CarterOne",
                        fontSize: 22.0)),
              ),
              PageView.builder(
                physics: (cardExpanded)
                    ? NeverScrollableScrollPhysics()
                    : ScrollPhysics(),
                onPageChanged: (index) {
                  currentPage = index;
                },
                itemCount: widget.loginInfo.length,
                itemBuilder: (context, i) {
                  listKeys.add(GlobalKey<ExpandableCardState>());
                  return ExpandableCard(
                      key: listKeys[i],
                      index: i,
                      loginInfo: widget.loginInfo[i],
                      currentPage: currentPage,
                      notifyParent: notifyParent,);
                }
              ),
            ]
          ),
        ),
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
  final int currentPage;
  final int index;
  final dynamic loginInfo;
  final Function(bool) notifyParent;

  ExpandableCard({Key key, this.index, this.loginInfo, this.currentPage, this.notifyParent})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ExpandableCardState();
  }
}

class ExpandableCardState extends State<ExpandableCard> with SingleTickerProviderStateMixin {
  bool cardOpen = false;

  double backgroundOpacity = 0.0;
  int duration = 0;

  double cardHeight = minCardHeight;
  double initialCardHeight = minCardHeight;
  double cardMiddle = minCardHeight + (maxCardHeight - minCardHeight) / 2;

  double startPosition;
  double delta;

  ScrollController scrollController;
  AnimationController arrowController;

  int chapLoading = -1;
  bool overscrollStarted = false;
  bool overscrollQuick = false;

  double overscrollStartPos = 0.0;
  double prevOverscrollPos = 0.0;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<String> chapters = [];
  List<String> shownChapters = [];
  static double listTileHeight = 20.0;

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

  void getChapData(int scrollPosition) async {
    if (!await connectionStatus.checkConnection()) {
      print("Main: Not connected!"); //If not connected!
      _showDialog("Oh no!",
          "Something went wrong! Please check your Internet connection!");
      setState(() {
        chapLoading = -1;
      });
      return;
    }

    final String mapUrl = "https://tinypingu.infocommsociety.com/api/exploremap";
    await http.post(mapUrl, headers: {"Cookie": global.cookie}, body: {
      "courseCode": widget.loginInfo["courseCode"]}).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseMap = json.decode(response.body);
        print("Main: Successly retrieved explore map info!");
        Route route = MaterialPageRoute(
            builder: (context) => ExploreMap(mapInfo: responseMap, scrollToPosition: scrollPosition,));
        Navigator.push(context, route);
      } else {
        print("Main: " + response.statusCode.toString());
        print("Main: Error! Subject data not retrieved!");
      }
    });

    setState(() {
      chapLoading = -1;
    });
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

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
      widget.notifyParent(cardOpen);
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
          await Future.delayed(const Duration(milliseconds: 50));
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
              margin: EdgeInsets.only(top: iconPadding + global.statusBarHeight + global.appBarHeight),
              height: iconWidth,
              width: iconWidth,
              child: Image.asset(
                'images/test.png'
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
                height: global.phoneHeight - global.appBarHeight,
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
                backgroundOpacity = (cardHeight - minCardHeight) * 0.6 / (maxCardHeight - minCardHeight);
                duration = 0;
              });
            },
            onVerticalDragEnd: (details) {
              double velocity = details.velocity.pixelsPerSecond.dy;
              double velocityThreshold = 250;

              if (velocity > velocityThreshold) {
                print("Main: Minimise card");
                if (cardOpen)
                  changeCard(minCardHeight, 0.0, -1); //Reverse arrow
                else
                  changeCard(minCardHeight, 0.0, 0);
                initialCardHeight = minCardHeight;
              } else if (velocity < -velocityThreshold) {
                print("Main: Expand card");
                if (!cardOpen)
                  changeCard(maxCardHeight, 0.6, 1);
                else
                  changeCard(maxCardHeight, 0.6, 0);
                initialCardHeight = maxCardHeight;
              } else {
                if (cardHeight < cardMiddle) {
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
                        } else if (!cardOpen){
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
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollEndNotification) {
                          if (overscrollQuick) {
                            print("Main: Minimise card");
                            if (cardOpen)
                              changeCard(minCardHeight, 0.0, -1); //Reverse arrow
                            else
                              changeCard(minCardHeight, 0.0, 0);
                            initialCardHeight = minCardHeight;
                            overscrollQuick = false;
                          } else {
                            if (cardHeight < cardMiddle) {
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
                        } else if (scrollNotification is ScrollUpdateNotification) {
                          overscrollStarted = false;
                        }
                      },
                        child: NotificationListener<OverscrollNotification>(
                        onNotification: (overscrollNotification) {
                            if (overscrollNotification.metrics.pixels <= scrollController.position.minScrollExtent) {
                              if (overscrollNotification.dragDetails.primaryDelta > 4.5) { //* 5 is just a threshold
                                overscrollQuick = true;
                              }

                              if (!overscrollStarted) {
                                overscrollStarted = true;
                                overscrollStartPos = overscrollNotification.dragDetails.globalPosition.dy;
                              }

                              double position = overscrollNotification.dragDetails.globalPosition.dy;
                              double delta = position - overscrollStartPos;
                              double temp = initialCardHeight - delta;

                              setState(() {
                                if (temp < minCardHeight) {
                                  cardHeight = minCardHeight;
                                } else if (temp > maxCardHeight) {
                                  cardHeight = maxCardHeight;
                                } else {
                                  cardHeight = temp;
                                }
                                backgroundOpacity = (cardHeight - minCardHeight) * 0.6 / (maxCardHeight - minCardHeight);
                                duration = 0;
                              });
                            }
                        },
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 100),
                          opacity: (backgroundOpacity == 0.6) ? 1.0 : backgroundOpacity,
                          child: ScrollConfiguration(
                            behavior: MyBehavior(),
                            child: AnimatedList(
                              physics: ClampingScrollPhysics(),
                              controller: scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              key: _listKey,
                              shrinkWrap: true,
                              initialItemCount: 0,
                              itemBuilder: (BuildContext context, int index, Animation animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: buildOverviewBox(
                                    shownChapters[index],
                                    index,
                                    (index == chapters.length - 1) ? true : false,
                                    widget.loginInfo["done"] ?? false,
                                  )
                                );
                              },
                            ),
                          ),
                        ),
                      ),
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

  Widget buildOverviewBox(String chapter, int index, bool last, bool done) {
    if (index == 0) {
      return Padding(
        padding: EdgeInsets.only(bottom: 4.0, top: 8.0, left: 12.0),
          child: Text("Overview",
          style: TextStyle(
            fontFamily: "PoppinsSemiBold"
          )
        ),
      );
    }
    return (chapter != "")
        ? Column(
          children: <Widget>[
            ListTile(
              onTap: () {
                setState(() {
                  chapLoading = index;
                });
                this.getChapData(index ~/ 2);
              },
              dense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
              title: Text(chapter, style: TextStyle(fontSize: 14.0)),
              leading: 
              SizedBox(
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
                      child: (index == chapLoading) 
                        ? SizedBox(
                          height: 12.0,
                          width: 12.0,
                          child: Theme(
                            data: Theme.of(context).copyWith(accentColor: Colors.white),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                          ),
                        )
                      : done
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
              ),
            ),
            Container(
              height: last ? 36.0 : 0.0,
            )
          ],
        )
        : Container( //* Return the divider
            height: 16.0,
            child: Container(
              margin: EdgeInsets.only(
                  left: 29.0, right: global.phoneWidth * 0.9 - 55.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.0),
                color: Color(0x50000000),
              ),
            ),
          );
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

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}