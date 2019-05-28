import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/explore_map.dart' as subject_map;
import 'package:smart_explorer/settings.dart';
import 'package:smart_explorer/profile.dart';

import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

class ActivityPage extends StatefulWidget {
  final int actNum;
  final actData;
  final pageData;
  final curData;
  final chptName;

  ActivityPage(this.actNum, this.actData, this.pageData, this.curData, this.chptName);

  @override
  State<StatefulWidget> createState() {
    return new ActivityPageState(actNum, actData, pageData);
  }
}

class ActivityPageState extends State<ActivityPage> {
  final int actNum;
  final actData;
  final pageData;
  final quesNum = [];
  bool loading;

  ActivityPageState(this.actNum, this.actData, this.pageData);

  //var pageInfo;

  int position, qNum;
  int actCnt;
  int score;
  int futurePos;

  List<List> color = [];
  List<bool> _pressed = [];
  //List options = [];
  List<List> borderWidth = [];
  List<List> borderStyle = [];
  String qNumber;
  List<String> question = [];
  List<Map> prevData = [];
  List<Map> data = [];
  //var curData = [];
  bool dataGot = false;
  bool showNext = false;
  Map attemptInfo = {};

  List<int> optCnt = [];
  double _opacity = 0.0;
  double quesOpacity = 1.0;
  bool ignore = true;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List shownOptions = [];
  bool stable = false;

  @override
  void initState() {
    super.initState();
    stable = false;
    actCnt = actData["pages"].length;
    position = 0;
    futurePos = 0;
    score = 0;
    int cnt = 1;

    for (int i = 0; i < pageData.length; i++){
      if (pageData[i]["type"] == "mcq") quesNum.add(cnt++);
      else quesNum.add(0);
    }

    
    //getAttempts();

    //while (!dataGot){}
    
    for (var page in pageData){
      attemptInfo[page["id"]] = {"score": 0, "answer": -1};
    }

    // print(data);

    //sendAttempt();

    for (var ans in widget.curData){
      Map tempInfo = {};
      if (ans["answer"] != -1) score += ans["score"];
      tempInfo["score"] = ans["score"];
      tempInfo["answer"] = ans["answer"];
      attemptInfo[ans["id"]] = tempInfo;
    }

    print("Retrieve Debug!");
    print(attemptInfo);

    for (var page in pageData){
      // attemptInfo[page["id"]] = {"score": 0, "answer": -1};
      Map tempData = {};
      tempData["id"] = page["id"];
      tempData["answer"] = attemptInfo[page["id"]]["answer"];
      tempData["score"] = attemptInfo[page["id"]]["score"];
      data.add(tempData);
    }

    for (int j=0; j<pageData.length; j++){
      optCnt.add(pageData[j]["options"].length);

      List<BorderStyle> tempStyle = [];
      List<double> tempWidth = [];
      List<Color> tempCol = [];
      
      for (var i in pageData[j]["options"]){
        tempCol.add(Colors.transparent);
        tempWidth.add(2.0);
        tempStyle.add(BorderStyle.none);
      }

      borderWidth.add(tempWidth);
      borderStyle.add(tempStyle);
      color.add(tempCol);
      _pressed.add(false);
      qNumber = quesNum[j].toString();
      if (qNumber.length == 1) qNumber = "0" + qNumber;
      String tempQ = "Question " + qNumber + ":";
      question.add(tempQ);
    }

    //! Set the options which the user has already chosen
    for (int i = 0; i < pageData.length; i++){
      if (pageData[i]["type"] != "mcq"){
        _pressed[i] = true;
        continue;
      }
      if (attemptInfo[pageData[i]["id"]]["answer"] == -1) continue;
      _pressed[i] = true;
      int id = pageData[i]["id"];
      var options = pageData[i]["options"];
      for (int j = 0; j < options.length; j++){
        if (options[j]["correct"]){
          color[i][j] = Color(0xFF22C8AD);
          borderStyle[i][j] = BorderStyle.solid;
        }
        else if (attemptInfo[id]["answer"] == j) {
          color[i][j] = Colors.red;
          borderStyle[i][j] = BorderStyle.solid;
        }
      }
    }
    
    optCnt.add(0);
    _pressed.add(false);

    //options = pageData[position]["options"];
    _opacity = 0.0;

    _insert();
  }

  void sendAttempt(List<Map> attData) async {
    int actId = actData["id"];
    print(json.encode(attData));
    final String mapUrl = "https://tinypingu.infocommsociety.com/api/submit-activity";
    await http.post(mapUrl,
        headers: {"Cookie": global.cookie, "Content-Type": "application/json"},
        body: json.encode({"activityId": actData["id"], "data": attData})).then((dynamic response) {
      if (response.statusCode == 200) {
        print("Send Attempt: Success!");
      } else {
        print("Send Attempt: Error! Attempt data not retrieved!");
      }
    });
  }

  // void getAttempts() async {
  //   int actId = actData["id"];
  //   final String mapUrl = "https://tinypingu.infocommsociety.com/api/get-activity-attempt";
  //   await http.post(mapUrl,
  //       headers: {"Cookie": global.cookie},
  //       body: {"activityId": actId.toString()}).then((dynamic response) {
  //     if (response.statusCode == 200) {
  //       final responseArr = json.decode(response.body);
  //       int attCnt = responseArr.length;
  //       curData = responseArr[attCnt-1]["data"];
  //       print("Get Attempt: Success!");
  //       print(curData);
  //       //dataGot = true;
  //     } else {
  //       print("Get Attempt: Error! Attempt data not retrieved!");
  //     }
  //   });
  // }
  
  void changePage(int nextOrPrev){
    if (position + nextOrPrev != actCnt){
      setState(() {
        if (!_pressed[position + nextOrPrev]){
          _opacity = 0.0;
        }
        else {
          _opacity = 1.0;
        }
        quesOpacity = 0.0;
        if (position != actCnt){
          _remove();
        }
      });
      Future.delayed(const Duration(milliseconds: 400), (){
        setState(() { 
          position += nextOrPrev;
          quesOpacity = 1.0;
          _insert();
        });
      });
      // Future.delayed(const Duration(milliseconds: 100), (){
      //   setState(() { 
      //     stable = true;
      //   });
      // });
    }
    else {
      // setState(() {
      //  _remove(); 
      // });
      // Future.delayed(const Duration(milliseconds: 300)); 
      setState((){
        position += nextOrPrev;
        stable = true;
      });
    }
  }

  void _remove() async {
    for (int i = 0; i < optCnt[position]+1; i++){
      if (optCnt[position] == 0) break;
      await Future.delayed(const Duration(milliseconds: 70), () => "1");
      if (shownOptions.isEmpty) break;
      shownOptions.removeAt(shownOptions.length-1);
      _listKey.currentState.removeItem(
        optCnt[position] - i,
        (BuildContext context, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: Container(
              color: Colors.transparent,
            )
          );
        },
        duration: Duration(milliseconds: 500),
      );
    }
  }

  void _insert() async{
    for (int i = 0; i < optCnt[position]+1; i++) {
      // if (!stable) break;
      await Future.delayed(const Duration(milliseconds: 70), () => "1");
      if (i > optCnt[position]) break;
      shownOptions.add(i);
      _listKey.currentState
          .insertItem(i, duration: Duration(milliseconds: 500));
    }
    stable = true;
  }

  Future<bool> _onWillPop() {
    return Future<bool>.value(stable);
  }

  Widget build(BuildContext context) {
    if (position < actCnt){
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: global.backgroundWhite,
          body: Container(
            child: Column(
              children: <Widget>[
                ///////////////////// \/////////The Question!//////////////////////////////
                Center(
                  child: Container(
                    height: global.phoneHeight * 0.50,
                    width: global.phoneWidth,
                    child: Stack(
                      children: <Widget>[
                        CustomPaint(
                          size: Size(global.phoneWidth, global.phoneHeight * 0.50),
                          painter: CurvePainter(),
                        ),
                        Positioned(
                          top: global.phoneHeight * 0.35 + global.phoneWidth * 0.12 + 6.0,
                          left: global.phoneWidth * 0.12,
                          child: Material(
                            elevation: 2.0,
                            color: Color(0x75ffffff),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8.0),
                              bottomRight: Radius.circular(8.0),
                            ),
                            child: Container(
                              height: 10.0,
                              width: global.phoneWidth * 0.76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8.0),
                                  bottomRight: Radius.circular(8.0),
                                ),
                                color: Color(0x75ffffff),
                              )
                            ),
                          )
                        ),
                        Positioned(
                          top: global.phoneHeight * 0.07,
                          left: global.phoneWidth * 0.07,
                          child: Container(
                            width: global.phoneWidth * 0.86,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Container(
                                  height: global.phoneWidth * 0.12,
                                  width: global.phoneWidth * 0.12,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0)
                                  ),
                                  child: Material(
                                    borderRadius: BorderRadius.circular(8.0),
                                    elevation: 0.0,
                                    color: Color(0x25ffffff),
                                    child: InkWell(
                                      onTap: (){
                                        if (stable) Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 2.0),
                                        child: Center(
                                          child: Column(
                                            children: <Widget>[
                                              Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                              Text(
                                                "exit",
                                                style: TextStyle(
                                                  fontFamily: "PoppinsSemiBold",
                                                  fontSize: 9.0,
                                                  color: Colors.white,
                                                )
                                              )
                                            ],
                                          )
                                        )
                                      )
                                    )
                                  )
                                ),
                                Container(
                                  // color: Colors.black,
                                  width: global.phoneWidth * 0.5,
                                  child: Center(
                                    child: Text(
                                      widget.chptName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "PoppinsSemiBold",
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 0.9,
                                      )
                                    ),
                                  )
                                ),
                                Container(
                                  //duration: Duration(milliseconds: 500),
                                  height: global.phoneWidth * 0.12,
                                  width: global.phoneWidth * 0.12,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0)
                                  ),
                                  child: Material(
                                    borderRadius: BorderRadius.circular(8.0),
                                    elevation: 0.0,
                                    color: Color(0x25ffffff),
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(0.0, 6.0, 0.0, 2.0),
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              "Score",
                                              style: TextStyle(
                                                fontFamily: "PoppinsSemiBold",
                                                fontSize: 9.0,
                                                color: Colors.white,
                                              )
                                            ),
                                            Text(
                                              score.toString(),
                                              style: TextStyle(
                                                fontFamily: "PoppinsSemiBold",
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              )
                                            )
                                          ],
                                        )
                                      )
                                    )
                                  )
                                ),
                              ],
                            ),
                          )
                        ),
                        Positioned(
                          top: global.phoneHeight * 0.10 + global.phoneWidth * 0.12 + 6.0,
                          left: global.phoneWidth * 0.07,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, global.phoneHeight * 0.05),
                            child: Container(
                              height: global.phoneHeight * 0.25,
                              width: global.phoneWidth * 0.86,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                                // boxShadow: [
                                //   new BoxShadow(
                                //     color: Colors.grey[400],
                                //     blurRadius: 1.0,
                                //     spreadRadius: -10.0,
                                //     offset: Offset(2.0, 18.0),
                                //   ),
                                // ],
                              ),
                              child: AnimatedOpacity(
                                duration: Duration(milliseconds: 300),
                                opacity: quesOpacity,
                                child: Material(
                                  borderRadius: BorderRadius.circular(8.0),
                                  elevation: 2.0,
                                  child: Stack(
                                    children: <Widget> [
                                      Positioned(
                                        top: 30.0,
                                        child: Container(
                                          height: global.phoneHeight * 0.25 - 30.0,
                                          width: global.phoneWidth * 0.86,
                                          child: ScrollConfiguration(
                                            behavior: MyBehavior(),
                                            child: ListView(   
                                              shrinkWrap: true,
                                              padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                                              children: <Widget> [
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.05, 0.0, global.phoneWidth * 0.05, 0.0),
                                                  child: Html(
                                                    data: pageData[position]["text"],
                                                    defaultTextStyle: TextStyle(
                                                      fontFamily: "PoppinsSemiBold",
                                                      fontSize: 14.0,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            )
                                          )
                                        )
                                      ),
                                      Positioned(
                                        left: global.phoneWidth * 0.08,
                                        top: global.phoneHeight * 0.25,
                                        child: Container(
                                          height: 6.0,
                                          width: global.phoneWidth * 0.70, 
                                          decoration: BoxDecoration(
                                            color: global.backgroundWhite,
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 6.0,
                                                color: global.backgroundWhite,
                                                offset: Offset(0.0, 2.0),
                                                spreadRadius: 24.0
                                              )
                                            ]
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: global.phoneWidth * 0.06,
                                        top: 20.0,
                                        child: Container(
                                          height: 6.0,
                                          width: global.phoneWidth * 0.74, 
                                          decoration: BoxDecoration(
                                            color: global.backgroundWhite,
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 6.0,
                                                color: global.backgroundWhite,
                                                offset: Offset(0.0, 2.0),
                                                spreadRadius: 12.0
                                              )
                                            ]
                                          ),
                                        ),
                                      ),
                                      Container(
                                        color: Colors.transparent,
                                        height: 32.0,
                                        width: global.phoneWidth * 0.86, 
                                        child: Center(
                                          child: Text(
                                            question[position],
                                            style: TextStyle(
                                              fontFamily: "PoppinsSemiBold",
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFAAD32),
                                            ),
                                            textAlign: TextAlign.center,
                                          )
                                        ),
                                      ),
                                    ]
                                  )
                                ),
                              )
                            )
                          ),
                        )
                      ]
                    )
                  ),
                ),
                //////////    ////////////////////The Answers!//////////////////////////////
                //Expanded(
                Center(
                  child: Text(
                    "Choose the best option!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "PoppinsSemiBold",
                      color: Color(0x40000000),
                      fontWeight: FontWeight.bold
                    )
                  )
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: global.backgroundWhite,
                    ),
                    child: ScrollConfiguration(
                      behavior: MyBehavior(),
                      child: AnimatedList(
                        key: _listKey,
                        shrinkWrap: true,
                        initialItemCount: 0,
                        //physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                        itemBuilder: (BuildContext context, int pos, Animation animation) {
                          if (pos < optCnt[position]){
                            return FadeTransition(
                              opacity: animation,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.1, 0.0, global.phoneWidth * 0.1, 10.0),
                                child: Material(
                                  borderRadius: BorderRadius.circular(8.0),
                                  elevation: 2.0,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    //height: global.phoneHeight * 0.09,
                                    width: global.phoneWidth * 0.8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: new Border.all(
                                        color: color[position][pos],
                                        width: borderWidth[position][pos],
                                        style: borderStyle[position][pos],
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        if (!_pressed[position]){
                                          setState(() {
                                            _pressed[position] = true;
                                            data[position]["answer"] = pos;
                                            for (int i = 0; i < optCnt[position]; i++){
                                              if (pageData[position]["options"][i]["correct"] == true){
                                                if (i == pos){
                                                  data[position]["score"] = pageData[position]["maxScore"];
                                                }
                                                else data[position]["score"] = 0;
                                                color[position][i] = Color(0xFF22C8AD);
                                                borderWidth[position][i] = 2.0;
                                                borderStyle[position][i] = BorderStyle.solid;
                                              }
                                            }
                                            if (pageData[position]["options"][pos]["correct"] == false){
                                              color[position][pos] = Colors.red;
                                              borderWidth[position][pos] = 2.0;
                                              borderStyle[position][pos] = BorderStyle.solid;
                                            }
                                            else {
                                              score += pageData[position]["maxScore"];
                                            }
                                            // if (position != 2){
                                            //   widget.switchPage(position+1);
                                            // }
                                            sendAttempt(data);
                                            _opacity = 1.0;
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Wrap(
                                          children: <Widget> [
                                            Center(
                                              child: Text(
                                                pageData[position]["options"][pos]["text"],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: "PoppinsSemiBold",
                                                  fontSize: 14.0,
                                                ),
                                              ),
                                            )
                                          ]
                                        ),
                                      ),
                                    ),
                                  )
                                ),
                              )
                            );
                          }
                          else if (position != 0){
                            return Padding(
                                padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.08, global.phoneHeight * 0.01, global.phoneWidth * 0.08, global.phoneHeight * 0.01),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    FlatButton(
                                      onPressed: (){
                                        if (stable){
                                          stable = false;
                                          futurePos -= 1;
                                          changePage(-1);
                                        }
                                      },
                                      child: Container(
                                        child: Row(
                                          children: <Widget>[
                                            Icon(
                                              Icons.chevron_left,
                                              color: Color(0x40000000),
                                            ),
                                            Text(
                                              "Previous",
                                              style: TextStyle(
                                                fontFamily: "PoppinsSemiBold",
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0x40000000),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                            );
                          }
                          else {
                            return Padding(
                                padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.08, global.phoneHeight * 0.01, global.phoneWidth * 0.08, global.phoneHeight * 0.01),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("")
                                  ],
                                ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                )
              ],
            )
          ),
          floatingActionButton: AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _pressed[futurePos] ? 1.0 : 0.0,
            child: _pressed[position] || _pressed[futurePos] ? Container(
              margin: EdgeInsets.only(right: global.phoneWidth * 0.05),
              height: global.phoneHeight * 0.07,
              width: global.phoneWidth * 0.25,
              decoration: BoxDecoration(
                gradient: global.blueGradient,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2.0, offset: Offset(0.0, 2.0))],
              ),
              child: Material(
                borderRadius: BorderRadius.circular(8.0),
                elevation: 0.0,
                color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8.0),
                    onTap: (){
                      if (_pressed[position] && stable){
                        stable = false;
                        futurePos += 1;
                        changePage(1);
                      }
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            // color: Colors.red,
                            margin: EdgeInsets.only(left: 6.0),
                            child: Text(
                              "Next",
                              style: TextStyle(
                                fontFamily: "PoppinsSemiBold",
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            //color: Colors.black,
                            child: Icon(Icons.chevron_right, color: Colors.white),
                          )
                        ]
                      )
                    )
                  )
              )
            )
            : Container(height: 0.0, width: 0.0),
          ),
        )
      );
    }
    else {
      return Scaffold(
        floatingActionButton: Container(
          margin:EdgeInsets.only(right: global.phoneWidth * 0.2 + 140),
          height: global.phoneHeight * 0.06,
          width: 140,
          child: FlatButton(
            onPressed: (){
              if (stable){
                stable = false;
                futurePos -= 1;
                changePage(-1);
              }
            },
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.chevron_left,
                    color: Color(0x40000000),
                  ),
                  Text(
                    "Previous",
                    style: TextStyle(
                      fontFamily: "PoppinsSemiBold",
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0x40000000),
                    ),
                  )
                ],
              ),
            )
          )
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text("hello"),
              Container(
                width: global.phoneWidth * 0.80,
                child: Text(
                  "You have reached the end of this activity! Click exit to return!",
                  style: TextStyle(
                    fontSize: 14.0,
                    fontFamily: "PoppinsSemiBold",
                  ),
                  textAlign: TextAlign.center,
                ),
              ), 
            ],
          )
        ),
      );
    }
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size){
    double width = size.width;
    double height = size.height;
    Rect rect = Rect.fromLTWH(0.0, 0.0, width, height * 0.55);
    Gradient gradient = LinearGradient(
        begin: FractionalOffset.bottomCenter,
        end: FractionalOffset.topCenter,
        colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]);
    Paint paint = Paint()..shader = gradient.createShader(rect);
    final path1 = drawCurvedRect(height);
    canvas.drawShadow(path1, Colors.black, 2.0, true);
    canvas.drawPath(path1, paint);
  }

  bool shouldRepaint(CustomPainter oldDelegate){
    return false;
  }
}

Path drawCurvedRect(double dy){
  Path path = Path();
  path.lineTo(0, dy);
  path.quadraticBezierTo(global.phoneWidth * 0.5, dy * 0.9, global.phoneWidth, dy);
  path.lineTo(global.phoneWidth, 0);
  path.close();
  return path;
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}