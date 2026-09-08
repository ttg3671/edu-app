import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowWebView extends StatefulWidget {
  final String link;
  const ShowWebView({super.key, required this.link});

  @override
  State<ShowWebView> createState() => _ShowWebViewState();
}

class _ShowWebViewState extends State<ShowWebView> {
  late final WebViewController webViewController;
  
  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            // Intercept specific domain to open in external browser
            if (request.url.startsWith('https://www.edumovimiento.com/')) {
              
              final Uri url = Uri.parse(request.url);
              
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              } catch (e) {
                debugPrint('Error launching external URL: $e');
              }
              
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link));
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
