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

int score = 0;

class ActivityPage extends StatefulWidget {
  final int actNum;
  final actData;
  final pageData;

  ActivityPage(this.actNum, this.actData, this.pageData);

  @override
  State<StatefulWidget> createState() {
    return new ActivityPageState(actNum, actData, pageData);
  }
}

class ActivityPageState extends State<ActivityPage> {
  final int actNum;
  final actData;
  final pageData;
  bool loading;

  ActivityPageState(this.actNum, this.actData, this.pageData);

  //var pageInfo;

  @override
  void initState() {
    super.initState();
    //this.getPageData(actData["children"][0]);
  }

  Widget build(BuildContext context) {
    List actPages = actData["children"];
    int actCnt = actPages.length;
    print(actPages);
    return Scaffold(
      //appBar: AppBar(
      //  title: Text(actData["name"]),
      //),
      body: PageView.builder(
        itemBuilder: (context, position) {
          if (pageData[position]["type"] == "mcq") {
            return McqPage(position, pageData);
          } else if (pageData[position]["type"] == "info") {
            return infoPage(position);
          } else if (pageData[position]["type"] == "pic") {
            return picPage(position);
          } else {
            return saqPage(position);
          }
        },
        itemCount: actCnt,
      ),
    );
  }

  Widget infoPage(int position) {
    return Container(
      child: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Container(
                width: global.phoneWidth * 0.9,
                child: Html(
                  data: pageData[position]["text"],
                  defaultTextStyle: TextStyle(
                    //fontFamily: 'Nunito',
                    fontSize: 16.0,
                  ),
                )
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget picPage(int position) {
    return Container(
        child: Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Container(
                width: global.phoneWidth * 0.9,
                child: Html(
                  data: pageData[position]["text"],
                  defaultTextStyle: TextStyle(
                    //fontFamily: 'Nunito',
                    fontSize: 16.0,
                  ),
                )),
          ),
        ),
      ],
    ));
  }

  Widget saqPage(int position) {
    return Container(
        child: Column(
      children: <Widget>[
        Center(
          child: Container(
              decoration: BoxDecoration(gradient: global.redGradient),
              height: 60.0,
              child: Center(
                  heightFactor: 1.5,
                  widthFactor: 1.5,
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0))),
                    child: Html(
                      data: pageData[position]["text"],
                      defaultTextStyle: TextStyle(
                        //fontFamily: 'Nunito',
                        fontSize: 16.0,
                      ),
                    ),
                  ))),
        ),
      ],
    ));
  }
}

class McqPage extends StatefulWidget {
  final int position;
  final pageData;

  McqPage(this.position, this.pageData);

  @override
  McqPageState createState() => McqPageState(position, pageData);
}

class McqPageState extends State<McqPage> with AutomaticKeepAliveClientMixin<McqPage>{
  List<Color> color = [];
  bool _pressed;
  List options = [];
  List<double> borderWidth = [];
  List<BorderStyle> borderStyle = [];
  final int position;
  final pageData;

  McqPageState(this.position, this.pageData);

  int optCnt;

  void initState() {
    super.initState();
    optCnt = pageData[position]["options"].length;
    for (var i in pageData[position]["options"]){
      color.add(Colors.transparent);
      borderWidth.add(2.0);
      borderStyle.add(BorderStyle.none);
      _pressed = false;
    }
    options = pageData[position]["options"];
  }

  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          //////////////////////////////The Question!//////////////////////////////
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFFEB4956), Color(0xFFF48149)]
                )
              ),
              height: global.phoneHeight * 0.45,
              width: global.phoneWidth,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(global.phoneWidth * 0.1, global.phoneWidth * 0.1, global.phoneWidth * 0.1, global.phoneWidth * 0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Container(
                            height: global.phoneHeight * 0.07,
                            width: global.phoneHeight * 0.07,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0)
                            ),
                            child: Material(
                              borderRadius: BorderRadius.circular(10.0),
                              elevation: 2.0,
                              color: Color(0xff8585ad),
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
                                            //fontFamily: "Nunito",
                                            fontSize: 10.0,
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
                            height: global.phoneHeight * 0.07,
                            width: global.phoneHeight * 0.07,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0)
                            ),
                            child: Material(
                              borderRadius: BorderRadius.circular(10.0),
                              elevation: 2.0,
                              color: Color(0xff8585ad),
                              child: InkWell(
                                onTap: (){
                                  Navigator.pop(context);
                                },
                                child: Center(
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        "",
                                        style: TextStyle(
                                          //fontFamily: "Nunito",
                                          fontSize: 8.0,
                                          color: Colors.white,
                                        )
                                      ),
                                      Text(
                                        "hi",
                                        style: TextStyle(
                                          //fontFamily: "Nunito",
                                          fontSize: 8.0,
                                          color: Colors.white,
                                        )
                                      ),
                                    ],
                                  )
                                )
                              )
                            )
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            height: global.phoneHeight * 0.07,
                            width: global.phoneHeight * 0.07,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0)
                            ),
                            child: Material(
                              borderRadius: BorderRadius.circular(10.0),
                              elevation: 2.0,
                              color: Color(0xff8585ad),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 2.0),
                                  child: Column(
                                    children: <Widget>[
                                      Text(
                                        "score",
                                        style: TextStyle(
                                          //fontFamily: "Nunito",
                                          fontSize: 10.0,
                                          color: Colors.white,
                                        )
                                      ),
                                      Text(
                                        score.toString(),
                                        style: TextStyle(
                                          //fontFamily: "Nunito",
                                          fontSize: 14.0,
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
                    ),
                    Container(
                      height: global.phoneHeight * 0.24,
                      width: global.phoneWidth * 0.8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          new BoxShadow(
                            color: Colors.grey[400],
                            blurRadius: 1.0,
                            spreadRadius: -10.0,
                            offset: Offset(2.0, 18.0),
                          ),
                        ],
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(20.0),
                        elevation: 2.0,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 16.0),
                          child: Html(
                            data: pageData[position]["text"],
                            defaultTextStyle: TextStyle(
                              //fontFamily: 'Nunito',
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ),
                    )
                  ]
                )
              )
            ),
          ),
          //////////////////////////////The Answers!//////////////////////////////
          Container(
            height: global.phoneHeight * 0.55,
            width: global.phoneWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                stops: [0.1, 0.9],
                colors: [
                  Colors.grey[200],
                  Colors.grey[100],
                ],
              ),
            ),
            child: ListView.builder(
              itemCount: optCnt,
              itemBuilder: (context, pos) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 10.0),
                  child: Material(
                    borderRadius: BorderRadius.circular(12.0),
                    elevation: 2.0,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      height: global.phoneHeight * 0.09,
                      width: global.phoneWidth * 0.75,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: new Border.all(
                          color: color[pos],
                          width: borderWidth[pos],
                          style: borderStyle[pos],
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (!_pressed){
                            setState(() {
                              _pressed = true;
                              for (int i = 0; i < optCnt; i++){
                                if (options[i]["correct"] == true){
                                  color[i] = Colors.green;
                                  borderWidth[i] = 2.0;
                                  borderStyle[i] = BorderStyle.solid;
                                }
                              }
                              if (options[pos]["correct"] == false){
                                color[pos] = Colors.red;
                                borderWidth[pos] = 2.0;
                                borderStyle[pos] = BorderStyle.solid;
                              }
                              else {
                                score += pageData[position]["maxScore"];
                              }
                            });
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            pageData[position]["options"][pos]["text"],
                            style: TextStyle(
                              //fontFamily: 'Nunito',
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ),
                    )
                  ),
                );
              },
            )
          ),
        ],
      )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
