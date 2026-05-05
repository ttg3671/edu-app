import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:flutter/material.dart';


class CustomDialog{

  static void showLoginDialog({required BuildContext context}){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: const Text('Please login again'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (builder)=>const Login()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

}