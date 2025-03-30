import 'package:axion/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class SaveButton extends StatelessWidget {
  String title;
  final void Function()? onTap;

  SaveButton({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(335, 60),
        backgroundColor: mainColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorWhite,
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class OutlineButton extends StatelessWidget {
  String title;
  final void Function()? onTap;

  OutlineButton({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: mainColor, width: 1),
        fixedSize: Size(46, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: "Mulish",
          fontWeight: FontWeight.w600,
          color: mainColor,
        ),
      ),
    );
  }
}
