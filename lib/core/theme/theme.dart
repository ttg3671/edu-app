import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

final lightTheme= ThemeData.light().copyWith(
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Colors.white
  ),
  textTheme: TextTheme(
    titleSmall: const TextStyle(
      color: Colors.black,
    ),
    titleLarge: const TextStyle(
      color: Colors.white
    ),
    titleMedium: GoogleFonts.poppins(
      color: Colors.black,
      fontSize: 12.sp,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: GoogleFonts.poppins(
      color: Colors.black54,
      fontSize: 12.sp,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      color: Colors.black,
      fontSize: 15.sp,
      fontWeight: FontWeight.normal,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    unselectedIconTheme: IconThemeData(
      color: Colors.green
    ),
    selectedIconTheme: IconThemeData(
      color: Colors.green
    ),
    showSelectedLabels: false,
    showUnselectedLabels: false,
  )
);