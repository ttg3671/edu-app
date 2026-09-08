import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color.dart';

final lightTheme = ThemeData.light().copyWith(
  primaryColor: AppColor.primary,
  scaffoldBackgroundColor: AppColor.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColor.background,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColor.text),
    titleTextStyle: TextStyle(color: AppColor.text, fontWeight: FontWeight.bold),
  ),
  colorScheme: const ColorScheme.light(
    primary: AppColor.primary,
    secondary: AppColor.secondary,
    surface: AppColor.secondary,
    background: AppColor.background,
    onPrimary: AppColor.background,
    onSecondary: AppColor.text,
    onSurface: AppColor.text,
    onBackground: AppColor.text,
  ),
  textTheme: GoogleFonts.openSansTextTheme(
    TextTheme(
      titleSmall: GoogleFonts.openSans(color: AppColor.text),
      titleLarge: GoogleFonts.openSans(color: AppColor.text, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.openSans(
        color: AppColor.text,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
      bodySmall: GoogleFonts.openSans(
        color: AppColor.text.withValues(alpha: 0.7),
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.openSans(
        color: AppColor.text,
        fontSize: 15.sp,
        fontWeight: FontWeight.normal,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColor.primary,
      foregroundColor: AppColor.background,
      textStyle: GoogleFonts.openSans(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColor.background,
    selectedItemColor: AppColor.primary,
    unselectedItemColor: Colors.grey,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),
);

// Alias darkTheme to lightTheme for now to ensure consistency across the app
final darkTheme = lightTheme;
