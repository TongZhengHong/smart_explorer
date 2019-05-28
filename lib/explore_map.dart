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

List _activities = [];
List _chptPos = [];
List _scores = [];
List _types = [];

Map<int, String> _chapterDesc = {};
List<double> _activityPositions = [];

const _circleDiameter = 48.0;
const _activitySpacing = 200;
const _endMargin = 120.0;
const _extraStarHeight = 24.0; //? For stars on top
const _extraStarWidth = 40.0; //? For stars at the side
double _activitySideMargin = global.phoneWidth * 0.1 + _extraStarWidth;

double _extraVerticalStarHeight = 12.0;

class ExploreMap extends StatefulWidget {
  final dynamic mapInfo;

  ExploreMap({Key key, @required this.mapInfo}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ExploreMapState();
  }
}

class ExploreMapState extends State<ExploreMap> {
  int itemCnt = 0;
  bool _loading = false;

  Random _random = Random(500);

  @override
  void initState() {
    super.initState();

    _activities = [];
    _chptPos = [];
    _scores = [];
    _types = [];

    _chapterDesc = {};
    _activityPositions = [];

    //! Populate information into chptPos and activities arrays
    widget.mapInfo["children"].forEach((chapter) {
      int cnt = 0;
      _chapterDesc[itemCnt * 2] = chapter["dsc"];
      itemCnt += chapter["children"].length;
      chapter["children"].forEach((activity) {
        _activities.add(activity);
        _scores.add(activity["score"] / activity["maxScore"]);
        _types.add(activity["type"]);

        _activities.add(null); //?This is to signify the line b/w 2 points/activity
        _chptPos.add(cnt);
        cnt++;
      });
    });
    itemCnt = itemCnt * 2 - 1; //Account for separators in b/w 2 points
    _activities.removeLast();

    //! Populate left margins for all the activities
    int difference = (global.phoneWidth * 0.2).toInt();
    _activityPositions.add(global.phoneWidth * 0.5 - _circleDiameter / 2);
    for (int i = 1; i < _activities.length; i++) {
      if (_activities[i] != null) {
        if (_chapterDesc.containsKey(i)) {
          _activityPositions.add(global.phoneWidth * 0.5 - _circleDiameter / 2);
          difference = (global.phoneWidth * 0.2).toInt();
        } else {
          int number = _random.nextInt(
              (global.phoneWidth - _circleDiameter - _activitySideMargin)
                  .toInt());

          while (number < _activitySideMargin || (_activityPositions[i - 2] - number).abs() < difference) {
                number = _random.nextInt(
                (global.phoneWidth - _circleDiameter - _activitySideMargin)
                    .toInt());
              }

          _activityPositions.add(number.toDouble());
          difference = (global.phoneWidth * 0.4).toInt();
        }
      } else {
        _activityPositions.add(-1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalHeight = _activitySpacing * (_activityPositions.length ~/ 2) +
        _circleDiameter * ((_activityPositions.length + 1) ~/ 2) +
        _endMargin * 2; //this is for both the last and first items

    Widget painter = CustomPaint(
      size: Size(global.phoneWidth, totalHeight),
      painter: ExplorePainter(),
    );

    List<Widget> exploreMapWidgets = [];
    exploreMapWidgets.add(painter);

    for (int i = 0; i < _activities.length; i++) {
      if (_activities[i] != null) {
        int index = _activities.length - 1 - i; //This is to reverse the list
        Widget checkpoint = Positioned(
          top: index ~/ 2 * (_activitySpacing) +
              (index + 1) ~/ 2 * _circleDiameter +
              _endMargin,
          left: (_chapterDesc.containsKey(i)) //? Start of new chapter
              ? (_types[i ~/ 2] == "information") ?  _activityPositions[i] : _activityPositions[i] - _extraVerticalStarHeight
              : (_activityPositions[i] > global.phoneWidth/2) 
                  ? _activityPositions[i] 
                  : (_types[i ~/ 2] == "information") ?  _activityPositions[i] : _activityPositions[i] - _extraStarWidth,
          child: _drawCircle(_circleDiameter, i, _types[i ~/ 2], _scores[i ~/ 2]),
        );
        exploreMapWidgets.add(checkpoint);
      }
    }

    return Scaffold(
      backgroundColor: global.backgroundWhite,
      body: Stack(children: <Widget>[
        SingleChildScrollView(
          reverse: true,
          child: Stack(children: exploreMapWidgets),
        ),
        Container( //!Appbar here
            width: global.phoneWidth,
            height: global.bottomAppBarHeight + global.statusBarHeight,
            child: Stack(
              children: <Widget>[
                Container(
                  decoration:
                      BoxDecoration(color: global.backgroundWhite, boxShadow: [
                    BoxShadow(
                        blurRadius: 12.0,
                        color: global.backgroundWhite,
                        offset: Offset(0.0, 12.0),
                        spreadRadius: 4.0)
                  ]),
                ),
                Positioned(
                  top: global.statusBarHeight +
                      global.bottomAppBarHeight / 2 -
                      14,
                  left: 64,
                  child: Text(
                    widget.mapInfo["name"],
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "CarterOne",
                        fontSize: 22.0),
                  ),
                ),
                Positioned(
                  top: global.statusBarHeight + 6,
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
            )),
      ]),
    );
  }

  Widget _drawCircle(double diameter, int position, String type, double score) {
    int index = (position + 2) ~/ 2;
    return (_chapterDesc.containsKey(position))
        ? Column(
            children: <Widget>[
              (type == "test" || type == "homework")
                  ? Container(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Icon(
                              (score >= 33)
                                  ? Icons.star
                                  : (score >= 16)
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 24.0,
                            ),
                          ),
                          Icon(
                            (score >= 66)
                                ? Icons.star
                                : (score >= 50)
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 24.0,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Icon(
                              (score == 100)
                                  ? Icons.star
                                  : (score >= 83)
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 24.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: _extraStarHeight,
                    ),
              Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  gradient: (type == "information")
                      ? global.orangeDiagonalGradient
                      : (type == "homework")
                          ? global.pinkDiagonalGradient
                          : global.bluePurpleDiagonalGradient,
                  borderRadius: BorderRadius.circular(diameter / 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 2.0,
                        offset: Offset(1.0, 2.0)),
                  ],
                ),
                child: Material(
                  type: MaterialType.circle,
                  color: Colors.transparent,
                  child: InkWell(
                      splashFactory: global.CustomSplashFactory(),
                      borderRadius: BorderRadius.circular(diameter / 2),
                      onTap: () {
                        _showActivityDialog(position); 
                      },
                      child: Center(
                          child: Container(
                        height: diameter * 0.75,
                        width: diameter * 0.75,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(diameter / 2),
                        ),
                        child: Center(
                          child: Text(
                            "$index",
                            style: TextStyle(
                              fontFamily: "PoppinsSemiBold",
                              color: (type == "information")
                                  ? Colors.black87
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ))),
                ),
              ),
            ],
          )
        : Row(
            children: 
            (_activityPositions[position] > global.phoneWidth / 2)
                ? <Widget>[   //! Activities on the LEFT
                    Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        gradient: (type == "information")
                            ? global.orangeDiagonalGradient
                            : (type == "homework")
                                ? global.pinkDiagonalGradient
                                : global.bluePurpleDiagonalGradient,
                        borderRadius: BorderRadius.circular(diameter / 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey,
                              blurRadius: 2.0,
                              offset: Offset(1.0, 2.0)),
                        ],
                      ),
                      child: Material(
                        type: MaterialType.circle,
                        color: Colors.transparent,
                        child: InkWell(
                            splashFactory: global.CustomSplashFactory(),
                            borderRadius: BorderRadius.circular(diameter / 2),
                            onTap: () {
                              _showActivityDialog(position); 
                            },
                            child: Center(
                                child: Container(
                              height: diameter * 0.75,
                              width: diameter * 0.75,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(diameter / 2),
                              ),
                              child: Center(
                                child: Text(
                                  "$index",
                                  style: TextStyle(
                                    fontFamily: "PoppinsSemiBold",
                                    color: (type == "information")
                                        ? Colors.black87
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ))),
                      ),
                    ), 
                    (type == "test"  || type == "homework")
                    ? Column(   //!Stars for the RIGHT
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(
                            (score == 100)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24.0,
                          ),
                        ),
                        Icon(
                          (score >= 66)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24.0,
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(
                            (score >= 33)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24.0,
                          ),
                        ),
                      ],
                    ) : Container(
                      height: _extraStarHeight + _circleDiameter
                    )
                  ]
                : <Widget>[     //! Activties on the RIGHT
                (type == "test" || type == "homework")
                    ? Column(   //! Stars on the LEFT
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Icon(
                            (score == 100)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24.0,
                          ),
                        ),
                        Icon(
                          (score >= 66)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24.0,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Icon(
                            (score >= 33)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24.0,
                          ),
                        ),
                      ],
                    ) : SizedBox(
                      height: _extraStarHeight + _circleDiameter,
                    ), 
                    Container(
                      width: diameter,
                      height: diameter,
                      decoration: BoxDecoration(
                        gradient: (type == "information")
                            ? global.orangeDiagonalGradient
                            : (type == "homework")
                                ? global.pinkDiagonalGradient
                                : global.bluePurpleDiagonalGradient,
                        borderRadius: BorderRadius.circular(diameter / 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey,
                              blurRadius: 2.0,
                              offset: Offset(1.0, 2.0)),
                        ],
                      ),
                      child: Material(
                        type: MaterialType.circle,
                        color: Colors.transparent,
                        child: InkWell(
                            splashFactory: global.CustomSplashFactory(),
                            borderRadius: BorderRadius.circular(diameter / 2),
                            onTap: () {
                              _showActivityDialog(position); 
                            },
                            child: Center(
                                child: Container(
                              height: diameter * 0.75,
                              width: diameter * 0.75,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(diameter / 2),
                              ),
                              child: Center(
                                child: Text(
                                  "$index",
                                  style: TextStyle(
                                    fontFamily: "PoppinsSemiBold",
                                    color: (type == "information")
                                        ? Colors.black87
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ))),
                      ),
                    )
                    
                  ],
          );
  }

  void _showActivityDialog(int position) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: 'barrier',
      pageBuilder: (context, animation1, animation2) {
        return ActivityDialog(
          position: position,
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

  ActivityDialog(
      {Key key, @required this.position,})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ActivityDialogState();
  }
}

class ActivityDialogState extends State<ActivityDialog> {
  bool _loading = false;
  var curData;

  void getPageData(int position, int id, String title) async {
    final String url = "https://tinypingu.infocommsociety.com/api/get-activity-attempt";
    print("$id");
    await http.post(url,
        headers: {"Cookie": global.cookie, "Content-Type": "application/json"},
        body: json.encode({"activityId": id})).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body);
        int attCnt = responseArr.length;
        curData = responseArr[attCnt-1]["data"];
        print("Get Attempt: Success!");
        print(curData);
        //dataGot = true;
      } else {
        print("Get Attempt: Error! Attempt data not retrieved!");
      }
    });
    final String mapUrl =
        "https://tinypingu.infocommsociety.com/api/getactivity";
    await http.post(mapUrl,
        headers: {"Cookie": global.cookie},
        body: {"id": id.toString()}).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body);
        var actPages = responseArr["pages"];
        var act = responseArr;
        print("Explore Map: Success!");

        print(widget.position);
        Route route = MaterialPageRoute(
            builder: (context) => ActivityPage(_chptPos[widget.position~/2], act, actPages, curData, title));
        Navigator.pushReplacement(context, route);
      } else {
        print("Explore Map: Error! Page data not retrieved!");
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
                    child: Text(
                      _activities[widget.position]["name"] ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: "PoppinsSemiBold", fontSize: 18.0),
                    )),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: global.phoneWidth,
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                    child: Text(
                      _activities[widget.position]["dsc"] ?? "",
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
                        this.getPageData(
                            widget.position,
                            _activities[widget.position]["id"],
                            _activities[widget.position]["name"] ?? "");
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

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = Colors.blueGrey;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.0;
    paint.strokeCap = StrokeCap.round;

    Path path = Path();
    for (int i = 0; i < _activityPositions.length; i++) {
      if (_activityPositions[i] == -1 && !_chapterDesc.containsKey(i + 1)) {
        //If activity is null (empty spacing)
        int index = _activityPositions.length - 1 - i; //This is to reverse the list

        //Starting point on the top checkpoint
        double startDx = _activityPositions[i + 1] + _circleDiameter / 2;
        double startDy = index ~/ 2 * (_activitySpacing) +
            (index + 1) ~/ 2 * _circleDiameter +
            _endMargin;

        //Ending points at the bottom checkpoint
        double endDx = _activityPositions[i - 1] + _circleDiameter / 2;
        double endDy = (index + 1) ~/ 2 * (_activitySpacing) +
            (index + 1) ~/ 2 * _circleDiameter +
            _endMargin;

        double thresholdTop = 8.0;
        double thresholdBot = 36.0;
        var startPoint = Offset(startDx, startDy + thresholdBot);
        var controlPoint1 =
            Offset(size.width * 0.1, startDy + _activitySpacing * 0.6);
        var controlPoint2 =
            Offset(size.width * 0.8, endDy - _activitySpacing * 0.4);
        var endPoint = Offset(endDx, endDy - thresholdTop);

        path.moveTo(startPoint.dx, startPoint.dy);

        path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
            controlPoint2.dy, endPoint.dx, endPoint.dy);

        canvas.drawPath(
            dashPath(
              path,
              dashArray: CircularIntervalList<double>(<double>[16.0, 10]),
            ),
            paint);

        //! Draw activity name beside activity button!
        double _textActivitySpace = 12.0;
        var paragraphStyle = ui.ParagraphStyle(
            fontSize: 14.0,
            textAlign: (_activityPositions[i+1] < size.width/2) ? TextAlign.left : TextAlign.right,
            fontWeight: FontWeight.w800);
        var textStyle = ui.TextStyle(
            color: Colors.black54, fontFamily: "PoppinsBold");
        var paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
          ..pushStyle(textStyle)
          ..addText(_activities[i+1]["name"]);
        var paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: (_activityPositions[i+1] < size.width/2) 
                                      ? size.width - _activityPositions[i+1] - _activitySideMargin - _circleDiameter
                                      : _activityPositions[i+1] - _activitySideMargin - _textActivitySpace));

        double textDy = index ~/ 2 * (_activitySpacing) +
              (index) ~/ 2 * _circleDiameter +
              _endMargin +
              (_circleDiameter/2 + 12.0 - paragraph.height/2); //* Value of 12 is the height diff b/w para & activity

        canvas.drawParagraph(paragraph, Offset(
          (_activityPositions[i+1] < size.width/2) ? _activityPositions[i+1] + _circleDiameter + _textActivitySpace : _activitySideMargin, 
          textDy
        ));
      } else {
        //activityPositions[i] != -1 --> Acivity circle
        //! Draw Chapter description beside new chapter!
        if (_chapterDesc.containsKey(i)) {
          int index = _activityPositions.length - 1 - i; //This is to reverse the list
          double textOffset = _circleDiameter + 40.0;
          double textDy = index ~/ 2 * (_activitySpacing) +
              (index) ~/ 2 * _circleDiameter +
              _endMargin +
              textOffset;

          var paragraphStyle = ui.ParagraphStyle(
              fontSize: 18.0,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w800);
          var textStyle = ui.TextStyle(
              color: Colors.black54, fontFamily: "PoppinsSemiBold");
          var paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
            ..pushStyle(textStyle)
            ..addText(_chapterDesc[i]);
          var paragraph = paragraphBuilder.build()
            ..layout(ui.ParagraphConstraints(width: size.width * 0.7));

          canvas.drawParagraph(paragraph, Offset(size.width * 0.15, textDy));
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}