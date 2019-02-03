library my_prj.globals;
import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_explorer/subject_map.dart';
import 'package:smart_explorer/main.dart';

int subindex = 0;
List<String> subjects = ["H2 Economics", "H2 Math", "H2 Chemistry", "H2 Physics"];
String studentID = "";
String studentName = "";
String studentEmail = "";
List<double> overallProgress = [0,0,0,0];
List<int> totalScore = [0,0,0,0];
String cookie = "";

//! Shared Preferences key values
String pref_cookie = "cookie";
String auth_details = "AuthDetails";

//! Parameters
double phoneHeight = 0.0;
double phoneWidth = 0.0;
double navBarHeight = 200;
double bottomAppBarHeight = 56.0;

//! Colours:
Color blue = const Color(0xFF78B2FA);
Color appBarLightBlue = const Color(0xFFCDD6F0);
Color backgroundWhite = const Color(0xFFF6F8FC);

LinearGradient blueGradient = new LinearGradient(
  colors: [Color(0xFF78B5FA), Color(0xFF7DA2FF)]
);

LinearGradient blueButtonGradient = new LinearGradient(
  colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]
);

LinearGradient redGradient = new LinearGradient(
  colors: [Color(0xFFEB4956), Color(0xFFF48149)]
);

LinearGradient greenGradient = new LinearGradient(
  colors: [Color(0xFF57CDDB), Color(0xFF4AE296)]
);

Widget createGradientButton(LinearGradient gradient, double height, double width, BuildContext context, Widget route, String content){
  return Container(
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) { 
                return route;
              }),
            );
          },
          borderRadius: BorderRadius.circular(24.0),
          child: Center(
              child: Text(
                content,
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    );
}

Widget bottomAppBar(){
  return null;
}