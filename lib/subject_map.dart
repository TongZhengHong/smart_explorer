import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text(widget.mapInfo.subjectName, style: TextStyle(color: Colors.black, fontFamily: "CarterOne"),),
        centerTitle: false,
        iconTheme: IconThemeData(
          color: Colors.grey.shade800, //change your color here
        ),
      ),
      body: ListView.builder(
              itemCount: widget.mapInfo.chapData[0]["children"].length,
              itemBuilder: (context, i) {
                double paddingTop = 0.0;
                double paddingBottom = 0.0;

                if (i != 0) 
                  paddingTop =
                      (activityPositions[i - 1] - activityPositions[i]) / 5;
                      
                if (i + 1 != activityPositions.length) 
                  paddingBottom =
                      (activityPositions[i + 1] - activityPositions[i]) / 5;

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
                  child: Text(widget.mapInfo.chapData[position]["name"], textAlign: TextAlign.left,),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0), 
                child: Container(
                  width: global.phoneWidth * 0.9,
                  child: Text(widget.mapInfo.chapData[position]["desc"], textAlign: TextAlign.left),
                ),
              ),
              flex: 3,
            ),
            //TODO: Yu peng!!! Change the button here
            global.createGradientButton(global.blueGradient, 48, global.phoneWidth * 0.60, context, SubjectMap(), "Let's Go!"),
          ],
        ),
      )
    );
  }
}
