import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/account/presentation/screens/subscription_screen.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/home/presentation/cubit/new_home_cubit.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/subscription_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String? sessionId;
  const PaymentSuccessScreen({super.key, this.sessionId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isRefreshing = true;
  String _status = 'active';
  String? _statusMessage;
  String? _planName;
  String? _amount;
  String? _expiry;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    // Immediately set is_subscribed to 1 on payment success screen
    TokenApi().updateIsSubscribed(1);
    _checkStatusAndRefresh();
  }

  Future<void> _checkStatusAndRefresh() async {
    final sessionId = widget.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      await _checkStatusWithSessionId(sessionId);
    } else {
      await _refreshWithLatestSubscription();
    }
  }

  Future<void> _checkStatusWithSessionId(String sessionId) async {
    try {
      final result = await Api.instance.getSubscriptionStatus(sessionId: sessionId);
      await result.fold(
        (failure) async {
          await _refreshWithLatestSubscription();
        },
        (data) async {
          final resData = (data['data'] is Map) ? data['data'] : data;
          final status = (resData['status']?.toString() ?? 'active').toLowerCase();
          final plan = resData['plan']?.toString();
          final amount = resData['amount']?.toString();
          final expiry = resData['expiry']?.toString();
          final message = resData['message']?.toString();
          final subId = resData['sub_id']?.toString();

          final dynamic subMap = (resData['subscription'] is Map)
              ? resData['subscription']
              : ((data['subscription'] is Map) ? data['subscription'] : null);

          final maxDevicesRaw = resData['max_devices'] ??
              data['max_devices'] ??
              subMap?['max_devices'] ??
              (data['data'] is Map ? data['data']['max_devices'] : null) ??
              resData['maxDevices'] ??
              data['maxDevices'] ??
              subMap?['maxDevices'] ??
              resData['deviceLimit'] ??
              data['deviceLimit'];

          final int? parsedMaxDevices = maxDevicesRaw != null ? int.tryParse(maxDevicesRaw.toString()) : null;

          final latestSub = SubscriptionDetails(
            subId: subId ?? subMap?['sub_id']?.toString() ?? subMap?['stripe_sub_id']?.toString(),
            plan: plan ?? subMap?['plan']?.toString(),
            amount: amount ?? subMap?['amount']?.toString(),
            expiry: expiry ?? subMap?['expiry']?.toString(),
            status: status,
            maxDevices: (parsedMaxDevices != null && parsedMaxDevices > 0)
                ? parsedMaxDevices
                : (TokenApi.maxDevices ?? TokenApi.user?.subscriptionDetails?.maxDevices ?? 3),
            planDurationValue: resData['plan_duration_value'] != null
                ? int.tryParse(resData['plan_duration_value'].toString())
                : (subMap?['plan_duration_value'] != null
                    ? int.tryParse(subMap['plan_duration_value'].toString())
                    : (TokenApi.user?.subscriptionDetails?.planDurationValue ?? 1)),
            planDurationType: resData['plan_duration_type']?.toString() ??
                subMap?['plan_duration_type']?.toString() ??
                (TokenApi.user?.subscriptionDetails?.planDurationType ?? 'month'),
          );

          if (parsedMaxDevices != null && parsedMaxDevices > 0) {
            await TokenApi().updateMaxDevices(parsedMaxDevices);
          }

          // Update subscription details in memory, secure storage, and shared preferences with is_subscribed = 1
          await TokenApi().updateSubscriptionFromStatusResponse(
            subDetails: latestSub,
            isSubscribed: 1,
          );

          if (mounted) {
            setState(() {
              _status = status;
              _planName = plan;
              _amount = amount;
              _expiry = expiry;
              _statusMessage = message;
              _isRefreshing = false;
            });

            try {
              context.read<AccountCubit>().getAccountDetails();
              context.read<NewHomeCubit>().loadHome();
            } catch (_) {}

            // If Stripe says paid but DB webhook is finalizing, retry polling after 2.5s (up to 4 times)
            if (status == 'processing' && _retryCount < 4) {
              _retryCount++;
              Future.delayed(const Duration(milliseconds: 2500), () {
                if (mounted) {
                  _checkStatusWithSessionId(sessionId);
                }
              });
            }
          }
        },
      );
    } catch (_) {
      await _refreshWithLatestSubscription();
    }
  }

  Future<void> _refreshWithLatestSubscription() async {
    try {
      final result = await Api.instance.getLatestSubscription();
      await result.fold(
        (failure) async {},
        (data) async {
          final dynamic subJson = (data['data'] is Map && data['data']['subscription'] != null)
              ? data['data']['subscription']
              : (data['subscription'] ?? data['data']);

          if (data['isSuccess'] == true && subJson is Map) {
            final Map<String, dynamic> subMap = Map<String, dynamic>.from(subJson);
            final maxDevicesRaw = subMap['max_devices'] ??
                data['max_devices'] ??
                (data['data'] is Map ? data['data']['max_devices'] : null) ??
                subMap['maxDevices'] ??
                data['maxDevices'] ??
                subMap['deviceLimit'] ??
                (data['data'] is Map ? data['data']['deviceLimit'] : null);

            if (maxDevicesRaw != null) {
              subMap['max_devices'] = maxDevicesRaw;
            }

            final latestSub = SubscriptionDetails.fromJson(subMap);
            if (latestSub.maxDevices != null && latestSub.maxDevices! > 0) {
              await TokenApi().updateMaxDevices(latestSub.maxDevices!);
            }
            await TokenApi().updateSubscriptionDetails(latestSub);

            if (mounted) {
              setState(() {
                _status = latestSub.status?.toLowerCase() ?? 'active';
                _planName = latestSub.plan;
                _amount = latestSub.amount;
                _expiry = latestSub.expiry;
              });

              try {
                context.read<AccountCubit>().getAccountDetails();
                context.read<NewHomeCubit>().loadHome();
              } catch (_) {}
            }
          }
        },
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _navigateToHome() async {
    await TokenApi().updateIsSubscribed(1);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (builder) => const MyHomePage()),
        (route) => false,
      );
    }
  }

  void _navigateToSubscription() async {
    await TokenApi().updateIsSubscribed(1);
    final user = TokenApi.user;
    if (user != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionScreen(
            userDetails: user.copyWith(isSubscribed: 1),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              if (_isRefreshing)
                const LinearProgressIndicator(minHeight: 2, color: AppColor.primary),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 35.h),

                      // Status Icon with circular border and glow
                      Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          color: _status == 'processing' ? Colors.amber.shade50 : Colors.green.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _status == 'processing' ? Colors.amber.shade400 : Colors.green.shade400,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_status == 'processing' ? Colors.amber : Colors.green).withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _status == 'processing' ? Icons.sync_rounded : Icons.check_circle_rounded,
                            size: 58.sp,
                            color: _status == 'processing' ? Colors.amber.shade700 : Colors.green.shade600,
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Heading
                      Text(
                        _status == 'processing'
                            ? "SETTING UP YOUR ACCOUNT"
                            : (localizations?.paymentSuccessHeading ?? "IT'S A SUCCESS!"),
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: _status == 'processing' ? Colors.amber.shade800 : Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Title
                      Text(
                        _status == 'processing'
                            ? 'Finalizing Subscription...'
                            : (localizations?.paymentSuccessTitle ?? 'Payment Successful'),
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          _statusMessage ??
                              (localizations?.paymentSuccessSubtitle ??
                                  'Your payment has been processed successfully. Your premium membership is now active!'),
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                            height: 1.45,
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // Subscription Status Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18.r),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _planName != null && _planName!.isNotEmpty
                                      ? _planName!
                                      : (localizations?.membershipActive ?? 'Active Membership'),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.text,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: _status == 'processing' ? Colors.amber.shade100 : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _status == 'processing' ? Icons.hourglass_top_rounded : Icons.verified,
                                        size: 14.sp,
                                        color: _status == 'processing' ? Colors.amber.shade900 : Colors.green.shade800,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        _status == 'processing' ? 'PROCESSING' : 'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                          color: _status == 'processing' ? Colors.amber.shade900 : Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_amount != null && _amount!.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'Amount: \$$_amount',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (_expiry != null && _expiry!.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'Renews / Expiry: $_expiry',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            SizedBox(height: 14.h),
                            Divider(color: Colors.grey.shade200, height: 1),
                            SizedBox(height: 14.h),
                            _buildBenefitRow(Icons.check, 'Full access to all modules & workout series'),
                            SizedBox(height: 10.h),
                            _buildBenefitRow(Icons.check, 'HD & 4K video player with quality selector'),
                            SizedBox(height: 10.h),
                            _buildBenefitRow(Icons.check, 'Multi-device synchronized workout tracking'),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthBtn(
                      text: localizations?.continueWatching ?? 'Start Learning',
                      width: double.infinity,
                      bgColor: AppColor.primary,
                      textColor: AppColor.background,
                      onTap: _navigateToHome,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                      child: TextButton(
                        onPressed: _navigateToSubscription,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColor.text,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            side: BorderSide.none,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                        ),
                        child: Text(
                          localizations?.viewSubscription ?? 'View Subscription Details',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12.sp, color: Colors.green.shade800),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
