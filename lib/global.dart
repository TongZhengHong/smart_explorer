library my_prj.globals;
import 'package:flutter/material.dart';

int subindex = 0;
List<String> subjects = ["Economics", "Math", "Chemistry", "Physics"];
String studentID = "";
String studentName = "";
String studentEmail = "";
List<int> overallProgress = [0,0,0,0];
List<int> totalScore = [0,0,0,0];
String cookie = "";

//! Parameters
double nav_bar_height = 200;

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