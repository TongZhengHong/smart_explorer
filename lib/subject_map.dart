import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:smart_explorer/activity.dart';
import 'package:path_drawing/path_drawing.dart';

import 'dart:ui' as ui;
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SubjectMap extends StatefulWidget {
  final dynamic mapInfo;

  SubjectMap({Key key, @required this.mapInfo}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SubjectMapState();
  }
}

class SubjectMapState extends State<SubjectMap> {
  int itemCnt = 0;

  bool _loading = false;

  List activities = [];
  List chptPos = [];
  List<double> activityPositions = [];
  Map<int, String> chapterDesc = {};

  Random random = Random(500);
  double circleDiameter = 48.0;
  double activitySideMargin = 40.0;
  double activitySpacing = global.phoneHeight * 0.3;
  double endMargin = 120.0;

  @override
  void initState() {
    super.initState();

    //! Populate information into chptPos and activities arrays
    widget.mapInfo["children"].forEach((chapter) {
      int cnt = 0;
      // chapterDesc[itemCnt] = chapter["dsc"];
      itemCnt += chapter["children"].length;
      chapter["children"].forEach((activity) {
        activities.add(activity);
        activities.add(null); //This is to signify the line b/w 2 points/activity
        chptPos.add(cnt);
        cnt++;
      });
    });
    itemCnt = itemCnt * 2 - 1; //Account for separators in b/w 2 points
    activities.removeLast();

    //! Populate left margins for all the activities
    activityPositions.add(global.phoneWidth * 0.5-circleDiameter/2);
    for (int i = 1; i < activities.length; i++) {      
      if (activities[i] != null) {
        int number = random.nextInt((global.phoneWidth-circleDiameter-activitySideMargin).toInt());
        int difference; 

        //! Second activity
        if (i == 2) difference = (global.phoneWidth * 0.2).toInt();
        else difference = (global.phoneWidth * 0.4).toInt();

        while (number < activitySideMargin || (activityPositions[i-2] - number).abs() < difference)
          number = random.nextInt((global.phoneWidth-circleDiameter-activitySideMargin).toInt());

        activityPositions.add(number.toDouble());
      } else {
        activityPositions.add(-1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalHeight = activitySpacing * (activityPositions.length~/2) 
                       + circleDiameter * ((activityPositions.length + 1)~/2)
                       + endMargin * 2; //this is for both the last and first items

    Widget painter = CustomPaint(
      size: Size(global.phoneWidth, totalHeight),
      painter: ExplorePainter(activityPositions, circleDiameter, activitySpacing, endMargin), 
    );
    
    List<Widget> exploreMapWidgets = [];
    exploreMapWidgets.add(Positioned(
      top: global.phoneHeight,
      left: global.phoneWidth * 0.15, 
      child: SizedBox(
        height: 72.0,
        width: 72.0,
        child: Image.asset("images/econsIcon.png"),
      )
    ));
    exploreMapWidgets.add(painter);
    

    for (int i = 0; i < activities.length; i++) {
      if (activities[i] != null) {
        int index = activities.length - 1 - i; //This is to reverse the list
        Widget checkpoint = Positioned(
          top: index~/2 * (activitySpacing) + (index+1)~/2 * circleDiameter + endMargin,
          right: activityPositions[i] - 12.0, //TODO: Change this to variable
          child: _drawCircle(circleDiameter, i),
        );
        exploreMapWidgets.add(checkpoint);
      }
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            reverse: true,
            child: Stack(
              children: exploreMapWidgets
            ),
          ),
          Container(
            width: global.phoneWidth,
            height: global.bottomAppBarHeight + global.statusBarHeight,
            color: Colors.transparent,
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    color: global.backgroundWhite,
                    boxShadow: [ 
                      BoxShadow(
                        blurRadius: 12.0,
                        color: global.backgroundWhite,
                        offset: Offset(0.0, 12.0),
                        spreadRadius: 4.0
                      )
                    ]
                  ),
                ),
                Positioned(
                  top: global.statusBarHeight + global.bottomAppBarHeight/2 - 14,
                  left: 64,
                  child: Text(
                    widget.mapInfo["name"],
                    style: TextStyle(color: Colors.black, fontFamily: "CarterOne", fontSize: 22.0),
                  ),
                ),
                Positioned(
                  top: global.statusBarHeight+6,
                  child: Container(
                    margin: EdgeInsets.only(left: 5.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashFactory: global.CustomSplashFactory(),
                        borderRadius: BorderRadius.circular(2.0),
                        child: BackButton(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ),
        ]
      ),
    );
  }

  Widget _drawCircle(double diameter, int position) {
    int index = (position+2)~/2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.star_border, color: Colors.amber, size: 24.0,),
                  ),
                  Icon(Icons.star_border, color: Colors.amber, size: 24.0,),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.star_border, color: Colors.amber, size: 24.0,),
                  ),
                ],
              ),
            ),
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                gradient: global.bluePurpleDiagonalGradient,
                borderRadius: BorderRadius.circular(diameter/2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey, blurRadius: 2.0, offset: Offset(1.0, 2.0)),
                ],
              ),
              child: Material(
                type: MaterialType.circle, 
                color: Colors.transparent, 
                child: InkWell(
                  splashFactory: global.CustomSplashFactory(),
                    borderRadius: BorderRadius.circular(diameter / 2),
                    onTap: () {
                      _showActivityDialog(
                          position); //Pass the position of the tap item to the dialog
                    },
                    child: Center(
                      child: Container(
                        height: diameter * 0.75,
                        width: diameter * 0.75,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(diameter/2),
                        ),
                        child: Center(
                          child: Text("$index", style: TextStyle(fontFamily: "PoppinsSemiBold"),),
                        ),
                      )
                    )
                  ),
              ),
            ),
          ],
        ),
      ],
    );
    
  }

  void _showActivityDialog(int position) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: 'barrier',
      pageBuilder: (context, animation1, animation2) {
        return ActivityDialog(
          position: position,
          activities: activities,
          posInChap: chptPos,
        );
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
}

class ActivityDialog extends StatefulWidget {
  final int position;
  final List activities;
  final List posInChap;

  ActivityDialog(
      {Key key,
      @required this.position,
      @required this.activities,
      @required this.posInChap})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ActivityDialogState();
  }
}

class ActivityDialogState extends State<ActivityDialog> {
  bool _loading = false;

  void getPageData(int position, int id) async {
    final String mapUrl =
        "https://tinypingu.infocommsociety.com/api/getactivity";
    await http.post(mapUrl,
        headers: {"Cookie": global.cookie},
        body: {"id": id.toString()}).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body);
        var actPages = responseArr["pages"];
        var act = responseArr;
        print("Activity: Success!");

        Route route = MaterialPageRoute(
            builder: (context) =>
                ActivityPage(widget.posInChap[widget.position], act, actPages));
        Navigator.pushReplacement(context, route);
      } else {
        print("Activity: Error! Page data not retrieved!");
      }

      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        contentPadding: EdgeInsets.all(16.0),
        content: Container(
          height: global.phoneHeight * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 16.0),
                child: Container(
                  width: global.phoneWidth,
                  child: Text(widget.activities[widget.position]["name"] ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "PoppinsSemiBold",
                        fontSize: 18.0
                      ),
                    )
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: global.phoneWidth,
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    child: Text(
                      widget.activities[widget.position]["dsc"] ?? "",
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  gradient: global.blueGradient,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 4.0,
                        offset: Offset(1.0, 2.0)),
                  ],
                ),
                height: 48.0,
                width: global.phoneWidth * 0.55,
                child: Material(
                  borderRadius: BorderRadius.circular(24.0),
                  color: Colors.transparent,
                  child: InkWell(
                    splashFactory: global.CustomSplashFactory(),
                    borderRadius: BorderRadius.circular(24.0),
                    onTap: () {
                      setState(() {
                        _loading = true;
                      });
                      Timer(Duration(milliseconds: 1000), () {
                        this.getPageData(widget.position,
                            widget.activities[widget.position]["id"]);
                      });
                    },
                    child: Center(
                      child: !_loading
                          ? Text(
                              "Let's Go!",
                              style: TextStyle(
                                fontFamily: "PoppinsSemiBold",
                                fontSize: 16.0,
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
              )
            ],
          ),
        ));
  }
}

class ExplorePainter extends CustomPainter {
  final List<double> activityPositions;
  final double circleDiameter;
  final double activitySpacing;
  final double endMargin;

  ExplorePainter(this.activityPositions, this.circleDiameter, this.activitySpacing, this.endMargin);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();

    paint.color = Colors.blueGrey;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    paint.strokeCap = StrokeCap.round;

    Path path = Path();
    for (int i = 0; i < activityPositions.length; i++) {
      if (activityPositions[i] == -1) { //If activity is null (empty spacing)
        int index = activityPositions.length - 1 - i; //This is to reverse the list

        //Starting point on the top checkpoint
        double startDx = activityPositions[i+1] + circleDiameter/2;
        double startDy = index~/2 * (activitySpacing) + (index+1)~/2 * circleDiameter + endMargin;

        //Ending points at the bottom checkpoint
        double endDx = activityPositions[i-1] + circleDiameter/2;
        double endDy = (index+1)~/2 * (activitySpacing) + (index+1)~/2 * circleDiameter + endMargin;

        startDx = global.phoneWidth - startDx;
        endDx = global.phoneWidth - endDx;

        double intermediateDx = activitySpacing * 0.1;
        double intermediateDy = activitySpacing * 0.1;

        double thresholdTop = 8.0;
        double thresholdBot = 54.0;
        var startPoint = Offset(startDx, startDy + thresholdBot);
        var topIntermediateControl = Offset((rightTurn(i) ? startDx+intermediateDx : startDx-intermediateDx), startDy + thresholdBot + intermediateDy);
        var endTopIntermediate = Offset((rightTurn(i) ? startDx-intermediateDx : startDx+intermediateDx), startDy + thresholdBot + intermediateDy);
        var controlPoint1 = Offset(size.width * 0.1, startDy + activitySpacing * 0.6);
        var controlPoint2 = Offset(size.width * 0.8, endDy - activitySpacing * 0.4);
        var botIntermediateControl = Offset((rightTurn(i) ? startDx-intermediateDx : startDx+intermediateDx), endDy - thresholdTop - intermediateDy);
        var startBotIntermediate = Offset((rightTurn(i) ? startDx+intermediateDx : startDx-intermediateDx), endDy - thresholdTop - intermediateDy);
        var endPoint = Offset(endDx, endDy - thresholdTop);

        path.moveTo(startPoint.dx, startPoint.dy);

        path.cubicTo(controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        endPoint.dx, endPoint.dy);

        canvas.drawPath(
          dashPath(
            path,
            dashArray: CircularIntervalList<double>(<double>[16.0, 10]),
          ),
          paint
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  bool rightTurn(int position){
    return (activityPositions[position+1] < activityPositions[position-1] ? true : false);
  }
}
