import 'package:flutter/material.dart';

double screenWidth;

List<double> positions = [235.0, 162.0, 86.0, 155.0, 115.0, 300.0, 271.0, 30.0, 103.0, 180.0];

class SubjectMap extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SubjectMapState();
  }
}

class SubjectMapState extends State<SubjectMap> {
  ScrollController _scroll = new ScrollController();
  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return new Scaffold(
      body: new ListView.builder(
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
              _buildCheckPoint(false, (positions[i] + 2 * paddingTop), paddingTop, i),
              _buildCheckPoint(false, (positions[i] + paddingTop), paddingTop, i),
              _buildCheckPoint(true, positions[i], 0.0, i),
              _buildCheckPoint(false, (positions[i] + paddingBottom), paddingBottom, i),
              _buildCheckPoint(false, (positions[i] + 2 * paddingBottom), paddingBottom, i),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckPoint(bool mainCheck, double paddingLeft, double check, int position) {
    if (!mainCheck && check == 0) {
      return new Container(
        height: 36.0,
      );
    } else {
      double _checkpointSize = 48.0;
      double _pathDotHeight = 36.0;
      return new Container(
        height: mainCheck ? _checkpointSize : _pathDotHeight,
        child: mainCheck ? _drawCircle(true, _checkpointSize, position) : _drawCircle(false, 4.0, position),
        padding: mainCheck ? EdgeInsets.only(left: paddingLeft) : EdgeInsets.only(left: paddingLeft + _checkpointSize/2, top: 16.0, bottom: 16.0),
      );
    }
  }

  Widget _drawCircle(bool mainCheck, double diameter, int position){
    return new Container(
      height: diameter,
      width: diameter,
      child: new Material(
        borderRadius: BorderRadius.circular(diameter/2),
        color: mainCheck ? Colors.red : Colors.black,
        child: !mainCheck ? null : new InkWell(
          borderRadius: BorderRadius.circular(diameter/2),
          onTap: () {
            _scroll.animateTo(position * 120.0 + 36.0, duration: new Duration(milliseconds: 500), curve: Curves.ease);
            showModalBottomSheet(
              context: context,
              builder: (builder) {
                return new Container(
                  height: 240.0,
                  color: Colors.lightGreenAccent,
                  child: new Center(
                    child: new Text("Hello"),
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }
}
