import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;

import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

double screenWidth;

List<double> activity_positions = [
  /*235.0,
  162.0,
  86.0,
  155.0,
  115.0,
  300.0,
  271.0,
  30.0,
  103.0,
  180.0*/
];

class SubjectMap extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SubjectMapState();
  }
}

class SubjectMapState extends State<SubjectMap> {
  ScrollController _scroll = ScrollController();
  int idx = global.subindex;
  bool _loading = true;
  List chapData;

  Future<String> getChapData() async {
    print("Request sent!");
    print(global.cookie);
    final String mapUrl =
        "https://tinypingu.infocommsociety.com/api/exploremap";
    final response =
        await http.post(mapUrl, headers: {"Cookie": global.cookie});

    if (response.statusCode == 200) {
      final responseArr = json.decode(response.body);
      responseArr.forEach((subject) {
        chapData = subject["children"];
        print(chapData);
        activity_positions = [];
        final random = new Random();
        print(chapData[0]["children"].length);
        chapData[0]["children"].forEach((activity) {
          int padding = random.nextInt(global.phoneWidth.toInt()-36);
          activity_positions.add(padding.toDouble());
        });
      }); //This is to get the first subject which is Econs

      setState(() {
        _loading = false;
      });
      return "Success!";
    } else {
      print("Error!");
      return "Error!";
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(global.subjects[idx]),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              controller: _scroll,
              itemCount: activity_positions.length,
              itemBuilder: (context, i) {
                double paddingTop = 0.0;
                double paddingBottom = 0.0;

                if (i != 0) {
                  paddingTop =
                      (activity_positions[i - 1] - activity_positions[i]) / 5;
                }
                if (i + 1 != activity_positions.length) {
                  paddingBottom =
                      (activity_positions[i + 1] - activity_positions[i]) / 5;
                }

                return new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildCheckPoint(
                        false,
                        (activity_positions[i] + 2 * paddingTop),
                        paddingTop,
                        i),
                    _buildCheckPoint(false,
                        (activity_positions[i] + paddingTop), paddingTop, i),
                    _buildCheckPoint(true, activity_positions[i], 0.0, i),
                    _buildCheckPoint(
                        false,
                        (activity_positions[i] + paddingBottom),
                        paddingBottom,
                        i),
                    _buildCheckPoint(
                        false,
                        (activity_positions[i] + 2 * paddingBottom),
                        paddingBottom,
                        i),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCheckPoint(
      bool mainCheck, double paddingLeft, double check, int position) {
    if (!mainCheck && check == 0) {
      return new Container(
        height: 36.0,
      );
    } else {
      double _checkpointSize = 48.0;
      double _pathDotHeight = 36.0;
      return new Container(
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

  @override
  void initState() {
    super.initState();
    this.getChapData();
  }

  Widget _drawCircle(bool mainCheck, double diameter, int position) {
    return new Container(
      height: diameter,
      width: diameter,
      child: new Material(
        borderRadius: BorderRadius.circular(diameter / 2),
        color: mainCheck ? global.blue : Colors.blueGrey,
        child: !mainCheck
            ? null
            : new InkWell(
                borderRadius: BorderRadius.circular(diameter / 2),
                onTap: () {
                  global.chapindex = position;
                  _showActivityInfo();
                },
              ),
      ),
    );
  }

  void _showActivityInfo() {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: Duration(milliseconds: 200), // DURATION FOR ANIMATION
      barrierDismissible: true,
      barrierLabel: 'barrier',
      pageBuilder: (context, animation1, animation2) {
        return _showActivityDialog();
      },
      transitionBuilder: (context, anim1, anim2, widget) {
        return new SlideTransition(
            position: new Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(anim1),
            child: widget);
      },
    );
  }

  Widget _showActivityDialog() {
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
                  child: Text(chapData[global.chapindex]["name"], textAlign: TextAlign.left),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0), 
                child: Container(
                  width: global.phoneWidth * 0.9,
                  child: Text(chapData[global.subindex]["desc"], textAlign: TextAlign.left),
                ),
              ),
              flex: 3,
            ),
            global.createGradientButton(global.blueGradient, 48, global.phoneWidth * 0.60, context, SubjectMap(), "Let's Go!"),
          ],
        ),
      )
    );
  }
}
