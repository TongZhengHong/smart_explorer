import 'package:flutter/material.dart';

double screenWidth;

List<double> positions = [235.0, 162.0, 86.0, 155.0, 115.0, 320.0, 271.0, 30.0, 103.0, 124.0];

class SubjectMap extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SubjectMapState();
  }
}

class SubjectMapState extends State<SubjectMap> {
  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return new Scaffold(
      body: new ListView.builder(
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
              _buildCheckPoint(false, (positions[i] + 2 * paddingTop), paddingTop),
              _buildCheckPoint(false, (positions[i] + paddingTop), paddingTop),
              _buildCheckPoint(true, positions[i], 0),
              _buildCheckPoint(false, (positions[i] + paddingBottom), paddingBottom),
              _buildCheckPoint(false, (positions[i] + 2 * paddingBottom), paddingBottom),
              //new Text("dafa")
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckPoint(bool mainCheck, double paddingLeft, double check) {
    if (!mainCheck && check == 0) {
      return new Container();
    } else {
      double _checkpointSize = 48.0;
      double _pathDotHeight = 36.0;
      return new Container(
        height: mainCheck ? _checkpointSize : _pathDotHeight,
        child: mainCheck ? _checkPoint : _pathDot,
        padding: mainCheck ? EdgeInsets.only(left: paddingLeft) : EdgeInsets.only(left: paddingLeft + _checkpointSize/2),
      );
    }
  }

  Widget _checkPoint = new FloatingActionButton(
    onPressed: () {
      print("Checkpoint clicked!");
    },
    backgroundColor: Colors.redAccent,
  );

  Widget _pathDot = new Container(
    padding: EdgeInsets.symmetric(vertical: 36.0),
    width: 4.0,
    height: 4.0,
    decoration: new BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black,
    )
  );
}
