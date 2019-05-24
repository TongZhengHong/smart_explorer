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
import 'package:smart_explorer/subject_map.dart' as subject_map;
import 'package:smart_explorer/subject_popup.dart';
import 'package:smart_explorer/settings.dart';
import 'package:smart_explorer/profile.dart';

import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

String chptName;

class ActivityPage extends StatefulWidget {
  final int actNum;
  final actData;
  final pageData;
  final chptData;

  ActivityPage(this.actNum, this.actData, this.pageData, this.chptData);

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

  List<List> color = [];
  List<bool> _pressed = [];
  List options = [];
  List<List> borderWidth = [];
  List<List> borderStyle = [];
  String qNumber;
  List<String> question = [];

  List<int> optCnt = [];
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    position = 0;
    global.score = 0;
    int cnt = 1;
    for (int i = 0; i < pageData.length; i++){
      if (pageData[i]["type"] == "mcq") quesNum.add(cnt++);
      else quesNum.add(0);
    }
    chptName = "hi";
    chptName = widget.chptData["name"];
    //this.getPageData(actData["children"][0]);
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
      String tempQ = "Question " + qNumber + ":";
      question.add(tempQ);
    }
    print("ACTIVITY: OPTCNT");
    print(optCnt);
    print(color);

    options = pageData[position]["options"];
    _opacity = 0.0;
  }
  

  Widget build(BuildContext context) {
    List actPages = actData["pages"];
    int actCnt = actPages.length;
    print(actPages);
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      //appBar: AppBar(
      //  title: Text(actData["name"]),
      //),
      // body: PageView.builder(
      //   itemBuilder: (context, position) {
      //     if (pageData[position]["type"] == "mcq") {
      //       return McqPage(position, pageData, quesNum[position]);
      //     }
      //   },
      //   itemCount: actCnt,
      // ),
      body: Container(
        child: Column(
          children: <Widget>[
            ///////////////////// \/////////The Question!//////////////////////////////
            Center(
              child: Container(
                //decoration: BoxDecoration(
                //  gradient: global.bluePurpleDiagonalGradient,
                //),
                height: global.phoneHeight * 0.50,
                width: global.phoneWidth,
                child: Stack(
                  children: <Widget>[
                    CustomPaint(
                      size: Size(global.phoneWidth, global.phoneHeight * 0.50),
                      painter: CurvePainter(),
                    ),
                    Positioned(
                      top: global.phoneHeight * 0.35 + global.phoneWidth * 0.12,
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
                                    Navigator.pop(context);
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
                                  chptName,
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
                            AnimatedContainer(
                              duration: Duration(milliseconds: 500),
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
                                          global.score.toString(),
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
                      top: global.phoneHeight * 0.10 + global.phoneWidth * 0.12,
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
                          child: Material(
                            borderRadius: BorderRadius.circular(8.0),
                            elevation: 2.0,
                            child: SingleChildScrollView(
                              
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.05, 0.0, global.phoneWidth * 0.05, 0.0),
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
                                      child: Text(
                                        question[position],
                                        style: TextStyle(
                                          fontFamily: "PoppinsSemiBold",
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFAAD32),
                                        ),
                                      ),
                                    ),
                                    Html(
                                      data: pageData[position]["text"],
                                      defaultTextStyle: TextStyle(
                                        fontFamily: "PoppinsSemiBold",
                                        fontSize: 14.0,
                                      ),
                                    ),
                                  ]
                                ),
                              ),
                            )
                          ),
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
                child: ListView.builder(
                  shrinkWrap: true,
                  //physics: const NeverScrollableScrollPhysics(),
                  itemCount: optCnt[position]+1,
                  padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                  itemBuilder: (context, pos) {
                    if (pos < optCnt[position]){
                      print(optCnt[position]);
                      return Padding(
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
                                    for (int i = 0; i < optCnt[position]; i++){
                                      if (pageData[position]["options"][i]["correct"] == true){
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
                                      global.score += pageData[position]["maxScore"];
                                    }
                                    // if (position != 2){
                                    //   widget.switchPage(position+1);
                                    // }
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
                                  setState(() {
                                    position -= 1;
                                    _opacity = 1.0;
                                  });
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
                              Text("hi")
                            ],
                          ),
                      );
                    }
                  },
                )
              ),
            )
          ],
        )
      ),
      floatingActionButton: AnimatedOpacity(
        duration: Duration(seconds: 1),
        opacity: _opacity,
        child: Container(
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
                setState((){
                  if (position != actCnt-1){
                    position += 1;
                  }
                  if (!_pressed[position]){
                    _opacity = 0.0;
                  }
                });
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

        // child: FloatingActionButton(
        //   onPressed: (){
        //     setState(() {
        //       if (position != actCnt-1){
        //         position += 1;
        //       }
        //       _opacity = 0.0;
        //     });
        //   },
        //   child: Text("Next")
        //   // label: Text(
        //   //   "Next",
        //   //   style: TextStyle(
        //   //     fontFamily: "PoppinsSemiBold",
        //   //     fontSize: 14.0,
        //   //     fontWeight: FontWeight.bold,
        //   //     color: Colors.white,
        //   //   ),
        //   // ),
        //   // icon: Icon(Icons.chevron_right),
        // ),
      ),
    );
  }

  // 
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

// class McqPage extends StatefulWidget {
//   final int position;
//   final pageData;
//   final quesNum;

//   McqPage(this.position, this.pageData, this.quesNum);

//   @override
//   McqPageState createState() => McqPageState(position, pageData);
// }

// class McqPageState extends State<McqPage> with AutomaticKeepAliveClientMixin<McqPage>{
//   List<Color> color = [];
//   bool _pressed;
//   List options = [];
//   List<double> borderWidth = [];
//   List<BorderStyle> borderStyle = [];
//   String qNumber;
//   String question;
//   final int position;
//   final pageData;

//   McqPageState(this.position, this.pageData);

//   int optCnt;
//   double _opacity = 0.0;

//   void initState() {
//     super.initState();
//     optCnt = pageData[position]["options"].length;
//     for (var i in pageData[position]["options"]){
//       color.add(Colors.transparent);
//       borderWidth.add(2.0);
//       borderStyle.add(BorderStyle.none);
//       _pressed = false;
//     }
//     options = pageData[position]["options"];
//     qNumber = widget.quesNum.toString();
//     question = "Question " + qNumber + ":";
//     _opacity = 0.0;
//   }

//   Widget build(BuildContext context) {
//     return Container(
//       child: Column(
//         children: <Widget>[
//           ///////////////////// \/////////The Question!//////////////////////////////
//           Center(
//             child: Container(
//               //decoration: BoxDecoration(
//               //  gradient: global.bluePurpleDiagonalGradient,
//               //),
//               height: global.phoneHeight * 0.50,
//               width: global.phoneWidth,
//               child: Stack(
//                 children: <Widget>[
//                   CustomPaint(
//                     size: Size(global.phoneWidth, global.phoneHeight * 0.50),
//                     painter: CurvePainter(),
//                   ),
//                   Positioned(
//                     top: global.phoneHeight * 0.29,
//                     left: global.phoneWidth * 0.12,
//                     child: Material(
//                       elevation: 2.0,
//                       color: Color(0x75ffffff),
//                       borderRadius: BorderRadius.circular(8.0),
//                       child: Container(
//                         height: global.phoneHeight * 0.15,
//                         width: global.phoneWidth * 0.76,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(8.0),
//                           color: Color(0x75ffffff),
//                         )
//                       ),
//                     )
//                   ),
//                   Positioned(
//                     top: global.phoneHeight * 0.07,
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.07, 0, global.phoneWidth * 0.07, 0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: <Widget>[
//                           Container(
//                             height: global.phoneWidth * 0.13,
//                             width: global.phoneWidth * 0.13,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8.0)
//                             ),
//                             child: Material(
//                               borderRadius: BorderRadius.circular(8.0),
//                               elevation: 0.0,
//                               color: Color(0x25ffffff),
//                               child: InkWell(
//                                 onTap: (){
//                                   Navigator.pop(context);
//                                 },
//                                 child: Padding(
//                                   padding: EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 2.0),
//                                   child: Center(
//                                     child: Column(
//                                       children: <Widget>[
//                                         Icon(
//                                           Icons.close,
//                                           color: Colors.white,
//                                         ),
//                                         Text(
//                                           "exit",
//                                           style: TextStyle(
//                                             fontFamily: "PoppinsSemiBold",
//                                             fontSize: 9.0,
//                                             color: Colors.white,
//                                           )
//                                         )
//                                       ],
//                                     )
//                                   )
//                                 )
//                               )
//                             )
//                           ),
//                           Container(
//                             // color: Colors.black,
//                             width: global.phoneWidth * 0.5,
//                             child: Center(
//                               child: Text(
//                                 chptName,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontFamily: "PoppinsSemiBold",
//                                   fontSize: 16.0,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 )
//                               ),
//                             )
//                           ),
//                           AnimatedContainer(
//                             duration: Duration(milliseconds: 500),
//                             height: global.phoneWidth * 0.13,
//                             width: global.phoneWidth * 0.13
//                             ,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8.0)
//                             ),
//                             child: Material(
//                               borderRadius: BorderRadius.circular(8.0),
//                               elevation: 0.0,
//                               color: Color(0x25ffffff),
//                               child: Center(
//                                 child: Padding(
//                                   padding: EdgeInsets.fromLTRB(0.0, 6.0, 0.0, 2.0),
//                                   child: Column(
//                                     children: <Widget>[
//                                       Text(
//                                         "Score",
//                                         style: TextStyle(
//                                           fontFamily: "PoppinsSemiBold",
//                                           fontSize: 9.0,
//                                           color: Colors.white,
//                                         )
//                                       ),
//                                       Text(
//                                         global.score.toString(),
//                                         style: TextStyle(
//                                           fontFamily: "PoppinsSemiBold",
//                                           fontSize: 14.0,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.white,
//                                         )
//                                       )
//                                     ],
//                                   )
//                                 )
//                               )
//                             )
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: global.phoneHeight * 0.23,
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, global.phoneHeight * 0.05),
//                       child: Container(
//                         height: global.phoneHeight * 0.25,
//                         width: global.phoneWidth * 0.86,
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8.0),
//                           // boxShadow: [
//                           //   new BoxShadow(
//                           //     color: Colors.grey[400],
//                           //     blurRadius: 1.0,
//                           //     spreadRadius: -10.0,
//                           //     offset: Offset(2.0, 18.0),
//                           //   ),
//                           // ],
//                         ),
//                         child: Material(
//                           borderRadius: BorderRadius.circular(8.0),
//                           elevation: 2.0,
//                           child: SingleChildScrollView(
//                                 child: Padding(
//                                 padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.05, 0.0, global.phoneWidth * 0.05, 0.0),
//                                 child: Column(
//                                   children: <Widget>[
//                                     Padding(
//                                       padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
//                                       child: Text(
//                                         question,
//                                         style: TextStyle(
//                                           fontFamily: "PoppinsSemiBold",
//                                           fontSize: 14.0,
//                                           fontWeight: FontWeight.bold,
//                                           color: Color(0xFFFAAD32),
//                                         ),
//                                       ),
//                                     ),
//                                     Html(
//                                       data: pageData[position]["text"],
//                                       defaultTextStyle: TextStyle(
//                                         fontFamily: "PoppinsSemiBold",
//                                         fontSize: 14.0,
//                                       ),
//                                     ),
//                                   ]
//                                 ),
//                               ),
//                           )
//                         ),
//                       )
//                     )
//                   )
//                 ]
//               )
//             ),
//           ),
//           //////////    ////////////////////The Answers!//////////////////////////////
//           //Expanded(
//           Center(
//             child: Text(
//               "Choose the best option!",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontFamily: "PoppinsSemiBold",
//                 color: Color(0x40000000),
//                 fontWeight: FontWeight.bold
//               )
//             )
//           ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: global.backgroundWhite,
//               ),
//               child: ListView.builder(
//                 shrinkWrap: true,
//                 //physics: const NeverScrollableScrollPhysics(),
//                 itemCount: optCnt+1,
//                 itemBuilder: (context, pos) {
//                   if (pos != optCnt){
//                     return Padding(
//                       padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.1, 0.0, global.phoneWidth * 0.1, 10.0),
//                       child: Material(
//                         borderRadius: BorderRadius.circular(8.0),
//                         elevation: 5.0,
//                         child: AnimatedContainer(
//                           duration: Duration(milliseconds: 500),
//                           //height: global.phoneHeight * 0.09,
//                           width: global.phoneWidth * 0.8,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8.0),
//                             border: new Border.all(
//                               color: color[pos],
//                               width: borderWidth[pos],
//                               style: borderStyle[pos],
//                             ),
//                           ),
//                           child: InkWell(
//                             onTap: () {
//                               if (!_pressed){
//                                 setState(() {
//                                   _pressed = true;
//                                   for (int i = 0; i < optCnt; i++){
//                                     if (options[i]["correct"] == true){
//                                       color[i] = Color(0xFF22C8AD);
//                                       borderWidth[i] = 2.0;
//                                       borderStyle[i] = BorderStyle.solid;
//                                     }
//                                   }
//                                   if (options[pos]["correct"] == false){
//                                     color[pos] = Colors.red;
//                                     borderWidth[pos] = 2.0;
//                                     borderStyle[pos] = BorderStyle.solid;
//                                   }
//                                   else {
//                                     global.score += pageData[position]["maxScore"];
//                                   }
//                                   // if (position != 2){
//                                   //   widget.switchPage(position+1);
//                                   // }
//                                 });
//                               }
//                             },
//                             child: Padding(
//                               padding: EdgeInsets.all(10.0),
//                               child: Wrap(
//                                 children: <Widget> [
//                                   Center(
//                                     child: Text(
//                                       pageData[position]["options"][pos]["text"],
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         fontFamily: "PoppinsSemiBold",
//                                         fontSize: 14.0,
//                                       ),
//                                     ),
//                                   )
//                                 ]
//                               ),
//                             ),
//                           ),
//                         )
//                       ),
//                     );
//                   }
//                   else {
//                     return Padding(
//                         padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.08, 0, global.phoneWidth * 0.08, 0),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: <Widget>[
//                             Container(
//                               child: Row(
//                                 children: <Widget>[
//                                   Icon(
//                                     Icons.chevron_left,
//                                     color: Color(0x40000000),
//                                   ),
//                                   Text(
//                                     "Previous",
//                                     style: TextStyle(
//                                       fontFamily: "PoppinsSemiBold",
//                                       fontSize: 14.0,
//                                       fontWeight: FontWeight.bold,
//                                       color: Color(0x40000000),
//                                     ),
//                                   )
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                     );
//                   }
//                 },
//               )
//             ),
//           )
//         ],
//       )
//     );
//   }

//   @override
//   bool get wantKeepAlive => true;
// }

  // Widget infoPage(int position) {
  //   return Container(
  //     child: Column(
  //       children: <Widget>[
  //         Expanded(
  //           child: Padding(
  //             padding: EdgeInsets.all(12.0),
  //             child: Container(
  //               width: global.phoneWidth * 0.9,
  //               child: Html(
  //                 data: pageData[position]["text"],
  //                 defaultTextStyle: TextStyle(
  //                   //fontFamily: 'Nunito',
  //                   fontSize: 16.0,
  //                 ),
  //               )
  //             ),
  //           ),
  //         ),
  //       ],
  //     )
  //   );
  // }

  // Widget picPage(int position) {
  //   return Container(
  //       child: Column(
  //     children: <Widget>[
  //       Expanded(
  //         child: Padding(
  //           padding: EdgeInsets.all(12.0),
  //           child: Container(
  //               width: global.phoneWidth * 0.9,
  //               child: Html(
  //                 data: pageData[position]["text"],
  //                 defaultTextStyle: TextStyle(
  //                   //fontFamily: 'Nunito',
  //                   fontSize: 16.0,
  //                 ),
  //               )),
  //         ),
  //       ),
  //     ],
  //   ));
  // }

  // Widget saqPage(int position) {
  //   return Container(
  //       child: Column(
  //     children: <Widget>[
  //       Center(
  //         child: Container(
  //             decoration: BoxDecoration(gradient: global.redGradient),
  //             height: 60.0,
  //             child: Center(
  //                 heightFactor: 1.5,
  //                 widthFactor: 1.5,
  //                 child: Card(
  //                   shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(8.0)),
  //                   child: Html(
  //                     data: pageData[position]["text"],
  //                     defaultTextStyle: TextStyle(
  //                       //fontFamily: 'Nunito',
  //                       fontSize: 16.0,
  //                     ),
  //                   ),
  //                 ))),
  //       ),
  //     ],
  //   ));
  // }