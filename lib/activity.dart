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
          if (pageData[position]["type"] == "mcq"){
            return mcqPage(position);
          }
          else if (pageData[position]["type"] == "info"){
            return infoPage(position);
          }
          else if (pageData[position]["type"] == "pic"){
            return picPage(position);
          }
          else {
            return saqPage(position);
          }
        },
        itemCount: actCnt,
      ),
    );
  }

  Widget mcqPage(int position){
    int optCnt = pageData[position]["options"].length;
    bool _pressed = false;
    return Container(
      child: Column(
        children: <Widget>[
          //The Question!
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [Color(0xFFEB4956), Color(0xFFF48149)]
                )
              ),
              height: global.phoneHeight * 0.36,
              width: global.phoneWidth,
              child: Center(
                child: Container(
                  height: global.phoneHeight * 0.28,
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
                      padding: EdgeInsets.all(12.0),
                      child: Html(
                        data: pageData[position]["text"],
                        defaultTextStyle: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ),
                )
              )
            ),
          ),
          //The Answers!
          Container(
            height: global.phoneHeight * 0.64,
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
              itemBuilder: (context, pos){
                return Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Container(
                    height: global.phoneHeight * 0.1,
                    width: global.phoneWidth * 0.75,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      /*boxShadow: [
                        new BoxShadow(
                          color: Colors.grey,
                          blurRadius: 5.0,
                        ),
                      ]*/
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(12.0),
                      elevation: 2.0,
                      child: InkWell(
                        onTap: (){
                          this.setState((){
                            _pressed = true;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            pageData[position]["options"][pos]["text"],
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  //child: Text("Hello!"),
                );
              },
            )
          ),
        ],
      )
    );
  }

  Widget infoPage(int position){
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
                    fontFamily: 'Nunito',
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

  Widget picPage(int position){
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
                    fontFamily: 'Nunito',
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

  Widget saqPage(int position){
    return Container(
      child: Column(
        children: <Widget>[
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: global.redGradient
              ),
              height: 60.0,
              child: Center(
                heightFactor: 1.5,
                widthFactor: 1.5,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))
                  ),
                  child: Html(
                    data: pageData[position]["text"],
                    defaultTextStyle: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16.0,
                    ),
                  ),
                )
              )
            ),
          ),
          /*Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.0), 
              child: Container(
                width: global.phoneWidth * 0.9,
                child: Html(
                  
                )
              ),
            ),
          ),*/
        ],
      )
    );
  }
}