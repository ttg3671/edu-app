import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShowWebView extends StatefulWidget {
  final String link;
  const ShowWebView({super.key, required this.link});

  @override
  State<ShowWebView> createState() => _ShowWebViewState();
}

class _ShowWebViewState extends State<ShowWebView> {
  WebViewController webViewController= WebViewController();
  
  @override
  void initState() {
    webViewController.loadRequest(Uri.parse(widget.link));
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('',
          style: TextStyle(
            color: Colors.white,
            fontFamily: GoogleFonts.poppins(fontWeight: FontWeight.bold).fontFamily,
            fontSize: 20.sp
        ),),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WebViewWidget(controller: webViewController),
      ),
    );
  }
}
