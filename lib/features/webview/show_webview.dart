import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_color.dart';
import '../account/presentation/screens/payment_canceled_screen.dart';
import '../account/presentation/screens/payment_success_screen.dart';

class ShowWebView extends StatefulWidget {
  final String link;
  const ShowWebView({super.key, required this.link});

  @override
  State<ShowWebView> createState() => _ShowWebViewState();
}

class _ShowWebViewState extends State<ShowWebView> {
  late final WebViewController webViewController;
  int _progress = 0;
  bool _hasHandledRedirect = false;

  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final handled = _checkAndHandleUrl(request.url);
            if (handled) {
              return NavigationDecision.prevent;
            }

            // Allow external app schemes like tel, mailto, whatsapp if any
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
              _launchNonWebScheme(uri);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _checkAndHandleUrl(change.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link));
  }

  Future<void> _launchNonWebScheme(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching external scheme: $e');
    }
  }

  bool _checkAndHandleUrl(String urlStr) {
    if (_hasHandledRedirect) return true;

    final uri = Uri.tryParse(urlStr);
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final queryParams = uri.queryParameters;
    final screenParam = (queryParams['screen'] ?? queryParams['target'] ?? '').toLowerCase();
    final statusParam = (queryParams['status'] ?? '').toLowerCase();
    final urlLower = urlStr.toLowerCase();

    // 1. Check for Payment Success
    final isSuccess = (scheme == 'edugarciamovimiento' || scheme == 'edugym') &&
            (screenParam == 'payment-success' ||
                screenParam == 'payment_success' ||
                host == 'payment-success' ||
                host == 'payment_success' ||
                path.contains('payment-success') ||
                path.contains('payment_success')) ||
        path.contains('payment-success') ||
        path.contains('payment_success') ||
        (urlLower.contains('payment') && statusParam == 'success');

    if (isSuccess) {
      _hasHandledRedirect = true;
      final sessionId = queryParams['session_id'] ?? queryParams['sessionId'];

      debugPrint('✅ WebView intercepted payment success! Session ID: $sessionId');

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(sessionId: sessionId),
          ),
        );
      }
      return true;
    }

    // 2. Check for Payment Canceled / Cancelled
    final isCancel = (scheme == 'edugarciamovimiento' || scheme == 'edugym') &&
            (screenParam == 'payment-canceled' ||
                screenParam == 'payment_canceled' ||
                screenParam == 'payment-cancelled' ||
                screenParam == 'payment_cancelled' ||
                host == 'payment-canceled' ||
                host == 'payment_canceled' ||
                host == 'payment-cancelled' ||
                host == 'payment_cancelled' ||
                path.contains('payment-canceled') ||
                path.contains('payment_canceled') ||
                path.contains('payment-cancelled') ||
                path.contains('payment_cancelled')) ||
        path.contains('payment-canceled') ||
        path.contains('payment_canceled') ||
        path.contains('payment-cancelled') ||
        path.contains('payment_cancelled') ||
        (urlLower.contains('payment') &&
            (statusParam == 'cancel' || statusParam == 'canceled' || statusParam == 'cancelled'));

    if (isCancel) {
      _hasHandledRedirect = true;
      debugPrint('⚠️ WebView intercepted payment cancel!');

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PaymentCanceledScreen(),
          ),
        );
      }
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColor.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColor.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            color: AppColor.text,
            fontFamily: GoogleFonts.poppins(fontWeight: FontWeight.bold).fontFamily,
            fontSize: 18.sp,
          ),
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress / 100.0,
                  backgroundColor: Colors.transparent,
                  color: AppColor.primary,
                  minHeight: 3,
                ),
              )
            : null,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: WebViewWidget(controller: webViewController),
      ),
    );
  }
}
