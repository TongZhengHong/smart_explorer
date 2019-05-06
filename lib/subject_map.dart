import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:smart_explorer/activity.dart';

import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

List<double> activityPositions = [
  235.0,
  162.0,
  86.0,
  155.0,
  115.0,
  300.0,
  271.0,
  30.0,
  103.0,
  180.0
];

class SubjectMap extends StatefulWidget {
  final global.ExploreMapInfo mapInfo;

  SubjectMap({Key key, @required this.mapInfo}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new SubjectMapState();
  }
}

class SubjectMapState extends State<SubjectMap> {
  @override
  void initState() {
    super.initState();
  }

  List actPages = [];
  var act;
  bool _loading = false;

  void getPageData(int position, int id) async {
    final String mapUrl = "https://tinypingu.infocommsociety.com/api/getactivity";
    print("Entered!");
    print("ID:");
    await http.post(mapUrl, headers: {"Cookie": global.cookie}, body: {"id" : id.toString()})
    .then((dynamic response) {
      //print(response.statusCode);
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body);
        actPages = responseArr["pages"];
        act = responseArr;
        print(responseArr);
        print("Activity: Success!");
      } else {
        print("Activity: Error! Page data not retrieved!");
      }
    });
    Route route = MaterialPageRoute(builder: (context) => ActivityPage(chptPos[position], act, actPages));
    Navigator.push(context, route);

    setState(() {
      _loading = false;
    });
  }

  List activities = [];
  List chptPos = [];
  //NOTE: Activities are here!!

  @override
  Widget build(BuildContext context) {
    //NOTE: Initialising all the activities
    int itemCnt = 0;
    //print("DEBUG!!!");
    //print(widget.mapInfo.chapData);
    widget.mapInfo.chapData.forEach((chapter){
      int cnt = 0;
      //print(chapter);
      itemCnt += chapter["children"].length;
      chapter["children"].forEach((activity){
        //getPageData(id);
        activities.add(activity);
        chptPos.add(cnt);
        cnt++;
      });
    });
    print(activities);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(widget.mapInfo.subjectName, style: TextStyle(color: Colors.black),),
        centerTitle: false,
      ),
      body: ListView.builder(
              itemCount: itemCnt,
              itemBuilder: (context, i) {
                double paddingTop = 0.0;
                double paddingBottom = 0.0;

                if (i != 0) {
                  paddingTop =
                      (activityPositions[i - 1] - activityPositions[i]) / 5;
                }
                if (i + 1 != activityPositions.length) {
                  paddingBottom =
                      (activityPositions[i + 1] - activityPositions[i]) / 5;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildCheckPoint(
                        false,
                        (activityPositions[i] + 2 * paddingTop),
                        paddingTop,
                        i),
                    _buildCheckPoint(false,
                        (activityPositions[i] + paddingTop), paddingTop, i),
                    _buildCheckPoint(true, activityPositions[i], 0.0, i),
                    _buildCheckPoint(
                        false,
                        (activityPositions[i] + paddingBottom),
                        paddingBottom,
                        i),
                    _buildCheckPoint(
                        false,
                        (activityPositions[i] + 2 * paddingBottom),
                        paddingBottom,
                        i),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCheckPoint(bool mainCheck, double paddingLeft, double check, int position) {
    if (!mainCheck && check == 0) {
      return Container(
        height: 36.0,
      );
    } else {
      double _checkpointSize = 48.0;
      double _pathDotHeight = 36.0;
      return Container(
        height: mainCheck ? _checkpointSize : _pathDotHeight,
        child: mainCheck
            ? _drawCircle(true, _checkpointSize, position)
            : _drawCircle(false, 4.0, position),
        padding: mainCheck
            ? EdgeInsets.only(left: paddingLeft)
            : EdgeInsets.only(
                left: paddingLeft + _checkpointSize / 2,
                top: 16.0,
                bottom: 16.0),
      );
    }
  }

  Widget _drawCircle(bool mainCheck, double diameter, int position) {
    return Container(
      height: diameter,
      width: diameter,
      child: Material(
        borderRadius: BorderRadius.circular(diameter / 2),
        color: mainCheck ? global.blue : Colors.blueGrey,
        child: !mainCheck
            ? null
            : InkWell(
                borderRadius: BorderRadius.circular(diameter / 2),
                onTap: () {
                  // global.chapindex = position;
                  _showActivityDialog(position); //Pass the position of the tap item to the dialog
                },
              ),
      ),
    );
  }

  void _showActivityDialog(int position) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: Duration(milliseconds: 200), // DURATION FOR ANIMATION
      barrierDismissible: true,
      barrierLabel: 'barrier',
      pageBuilder: (context, animation1, animation2) {
        return activityDialog(position);
      },
      transitionBuilder: (context, anim1, anim2, widget) {
        return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(anim1),
            child: widget);
      },
    );
  }

  Widget activityDialog(int position) {
    LinearGradient gradient = global.blueGradient;
    double height = 48;
    double width = global.phoneWidth * 0.60;
    BuildContext context1 = context;
    Widget route; //NOTE: Navigate to activity page!
    String content = "Let's Go!";

    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
      contentPadding: EdgeInsets.all(32.0),
      content: Container(
        width: global.phoneWidth * 1.0,
        height: global.phoneHeight * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.0), 
                child: Container(
                  width: global.phoneWidth * 0.9,
                  child: Text(activities[position]["name"], textAlign: TextAlign.left),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0), 
                child: Container(
                  width: global.phoneWidth * 0.9,
                  child: Text(activities[position]["dsc"], textAlign: TextAlign.left),
                ),
              ),
              flex: 3,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(height/2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey, blurRadius: 4.0, offset: Offset(2.0, 2.0)),
                ],
              ),
              height: height,
              width: width,
              child: Material(
                borderRadius: BorderRadius.circular(height/2),
                color: Colors.transparent,
                child: InkWell(
                  onTap: () { //NOTE: Changing pages here
                    setState(() {
                      _loading = true;
                    });
                    //print("TESTING TESTING");
                    //print(activities[position]["children"]);
                    this.getPageData(position, activities[position]["id"]);
                  },
                  borderRadius: BorderRadius.circular(24.0),
                  child: Center(
                    child: Center(
                      child: !_loading 
                      ? Text(
                        content,
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 20.0,
                          color: Colors.white,
                        ),
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
              ),
            )//TODO: Yu peng!!! Change the button here
            //global.createGradientButton(global.blueGradient, 48, global.phoneWidth * 0.60, context, ActivityPage(position, widget.mapInfo.chapData[position]["children"][0]), "Let's Go!"),
          ],
        ),
      )
    );
  }
}
