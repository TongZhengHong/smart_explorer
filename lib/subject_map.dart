import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

double screenWidth;

List<double> positions = [
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
  @override
  State<StatefulWidget> createState() {
    return new SubjectMapState();
  }
}

class SubjectMapState extends State<SubjectMap> {
  ScrollController _scroll = ScrollController();
  int idx = global.subindex;
  bool _loading = true;

  //List data;

  Future<String> getChapData() async {
    print("Request sent!");
    print(global.cookie);
    final String map_url =
        "https://tinypingu.infocommsociety.com/api/exploremap";
    final response =
        await http.get(map_url, headers: {"Cookie": global.cookie});

    if (response.statusCode == 200) {
      print("Response success!");
      final response_arr = json.decode(response.body);
      response_arr.forEach((subject) {
        String name = subject["name"];
        print(name);
        //final sub_children = subject["children"];

        setState(() {
          //var resBody = json.decode(res.body);
          //data = resBody["chapter"];
          _loading = false;
        });
      });
    } else {
      print("Error!");
    }

    //final String url = "https://swapi.co/api/starships";
    //var res = await http.get(Uri.encodeFull(url), headers: {"Accept": "application/json"});

    return "Success!";
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
              itemCount: positions.length,
              itemBuilder: (context, i) {
                double paddingTop = 0.0;
                double paddingBottom = 0.0;

                if (i != 0) {
                  paddingTop = (positions[i - 1] - positions[i]) / 5;
                }
                if (i + 1 != positions.length) {
                  paddingBottom = (positions[i + 1] - positions[i]) / 5;
                }

                return new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildCheckPoint(
                        false, (positions[i] + 2 * paddingTop), paddingTop, i),
                    _buildCheckPoint(
                        false, (positions[i] + paddingTop), paddingTop, i),
                    _buildCheckPoint(true, positions[i], 0.0, i),
                    _buildCheckPoint(false, (positions[i] + paddingBottom),
                        paddingBottom, i),
                    _buildCheckPoint(false, (positions[i] + 2 * paddingBottom),
                        paddingBottom, i),
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
        return RoundedAlertBox();
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
}

class RoundedAlertBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32.0))),
              contentPadding: EdgeInsets.only(top: 10.0),
              content: Container(
                width: 300.0,
                height: 300.0,
                child: Center(
                  child: Text("dlajskfa"),
                ),
              ));
        });
  }
}
