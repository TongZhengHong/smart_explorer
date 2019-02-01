import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:smart_explorer/subject_map.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:smart_explorer/main.dart';

const timeout = const Duration(seconds: 5);

class SubjectPopup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SubjectPopupState();
  }
}
class SubjectPopupState extends State<SubjectPopup> {
  int idx = global.subindex;
  Widget build(BuildContext context) {
    global.phoneHeight = MediaQuery.of(context).size.height;
    global.phoneWidth = MediaQuery.of(context).size.width;
    void _select(Choice choice) {
      // Causes the app to rebuild with the new _selectedChoice.
      print(choice.title);
      if (choice.title == "Log out") {
        global.studentID = "";
        global.cookie = "";
        Route route = MaterialPageRoute(builder: (context) => LoginPage());
        Navigator.pushReplacement(context, route);
      }
      return;
    }
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0.0,
        title: Row(
          children: <Widget>[
            Padding(padding: EdgeInsets.only(left: 16.0),),
       //     Text("Studious", style: TextStyle(color: Colors.black, fontFamily: "Audiowide", fontSize: 24.0),),
          ],
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Hero(
          tag: global.subjects[idx],
          child: SizedBox(
            height: global.phoneHeight*0.7,
            width: global.phoneWidth*0.9,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                child: Column(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color:Colors.grey
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      global.subjects[idx],
                      style: TextStyle(fontFamily: "Nunito", fontSize: 30.0),
                    ),
                    Padding(
                      padding:EdgeInsets.fromLTRB(global.phoneWidth*0.30, 0, global.phoneWidth*0.30, 0),
                      child: Divider(
                        color : Colors.grey,
                      ),
                    ),
                    Padding(
                      padding:EdgeInsets.fromLTRB(global.phoneWidth*0.10, 0, global.phoneWidth*0.10, 0),
                      child: LinearPercentIndicator(
                        width: global.phoneWidth*0.60,
                          lineHeight: 8.0,
                          percent: 0.8,
                        progressColor: Colors.orange,
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: global.createGradientButton(
          global.blueGradient, 48, global.phoneWidth*0.5, context, SubjectMap(), "Explore!"),
      bottomNavigationBar: BottomAppBar(
        color: global.appBarLightBlue,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            PopupMenuButton<Choice>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade700,),
              onSelected: _select,
              offset: Offset(0, -120),
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                    value: choice,
                    child: Text(choice.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
    );
  }
}