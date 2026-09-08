import 'package:edu_gym/api/token_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../api/api.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/cubit_states/data_state.dart';
import '../../../../modal/user_details.dart';
import '../../../../modal/subscription_details.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:edu_gym/features/home/presentation/cubit/new_home_cubit.dart';
import 'payment_canceled_screen.dart';
import '../cubit/account_cubit.dart';

class SubscriptionScreen extends StatefulWidget {
  final UserDetails userDetails;
  const SubscriptionScreen({super.key, required this.userDetails});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isSendingEmail = false;
  bool _isCancelling = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshSubscription();
  }

  Future<void> _sendAccessStepsEmail() async {
    setState(() {
      _isSendingEmail = true;
    });

    final localizations = AppLocalizations.of(context);
    final result = await Api.instance.generateWebLink();

    if (mounted) {
      setState(() {
        _isSendingEmail = false;
      });

      result.fold(
        (failure) {
          final errorMsg = failure.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (errorMsg != null && errorMsg.isNotEmpty)
                    ? errorMsg
                    : (localizations?.failedToSendAccessSteps ?? 'Failed to send access steps email.'),
              ),
              backgroundColor: Colors.red.shade800,
            ),
          );
        },
        (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message.isNotEmpty
                    ? message
                    : (localizations?.emailSentSuccess ?? 'Email sent successfully.'),
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
        },
      );
    }
  }

  Future<void> _cancelSubscription(SubscriptionDetails? sub) async {
    final localizations = AppLocalizations.of(context);
    String? subsId = sub?.subId ?? TokenApi.user?.subscriptionDetails?.subId;
    if (subsId == null || subsId.isEmpty) {
      // Fetch latest subscription to obtain stripe_sub_id
      setState(() => _isCancelling = true);
      final latest = await Api.instance.getLatestSubscription();
      setState(() => _isCancelling = false);

      latest.fold((l) {}, (r) {
        if (r['data']?['subscription'] != null) {
          final s = SubscriptionDetails.fromJson(r['data']['subscription']);
          subsId = s.subId;
        }
      });
    }

    if (subsId == null || subsId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.noActivePremiumId ?? 'No active Premium ID found to cancel.')),
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations?.cancelPremium ?? 'Cancel Premium'),
        content: Text(
          localizations?.cancelPremiumDialogContent ??
              'Are you sure you want to cancel your Premium access? You will lose access to premium workout modules once expired.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(localizations?.keepPremium ?? 'Keep Premium'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations?.yesCancel ?? 'Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCancelling = true;
    });

    final result = await Api.instance.cancelSubscription(subsId: subsId!);

    if (mounted) {
      setState(() {
        _isCancelling = false;
      });

      result.fold(
        (failure) {
          final errorMsg = failure.message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (errorMsg != null && errorMsg.isNotEmpty)
                    ? errorMsg
                    : (localizations?.failedToCancelPremium ?? 'Failed to cancel Premium'),
              ),
              backgroundColor: Colors.red.shade800,
            ),
          );
        },
        (data) async {
          // In memory and shared pref set user.is_subscribed to 0, subscription_details.max_devices = 1, and "status": "expired"
          await TokenApi().updateAfterSubscriptionCancelled();

          if (mounted) {
            try {
              context.read<AccountCubit>().getAccountDetails();
              context.read<NewHomeCubit>().loadHome();
            } catch (_) {}

            final message = data['data']?['message'] ??
                data['message'] ??
                (localizations?.premiumCancelledSuccess ??
                    'Your Premium access has been cancelled successfully.');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.grey.shade800,
              ),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentCanceledScreen(),
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocBuilder<AccountCubit, DataState>(
      builder: (context, state) {
        UserDetails? stateData;
        if (state is DataLoaded<UserDetails>) {
          stateData = state.data;
        }

        final user = TokenApi.user ?? stateData ?? widget.userDetails;

        // Resolve subscription details from state, TokenApi, or widget
        final sub = stateData?.subscriptionDetails ?? 
                    TokenApi.user?.subscriptionDetails ?? 
                    widget.userDetails.subscriptionDetails;

        final subStatus = sub?.status?.toLowerCase();
        final bool isSubActive = subStatus == 'active' || 
                                subStatus == 'trialing' || 
                                subStatus == 'praemium' || 
                                subStatus == 'processing';

        final bool isReviewer = user.isReviewer == 1 || 
                               stateData?.isReviewer == 1 || 
                               widget.userDetails.isReviewer == 1;

        // User is subscribed if reviewer, active sub status, or flagged subscribed anywhere
        final bool isSubscribed = isReviewer || 
                                 isSubActive || 
                                 user.isSubscribed == 1 || 
                                 stateData?.isSubscribed == 1 || 
                                 widget.userDetails.isSubscribed == 1;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              localizations?.premium.toUpperCase() ?? 'PREMIUM',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: _refreshSubscription,
                icon: _isRefreshing
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          body: isSubscribed 
            ? _buildSubscribedView(sub, isReviewer, localizations) 
            : _buildNonSubscribedView(localizations),
        );
      },
    );
  }

  Widget _buildSubscribedView(SubscriptionDetails? sub, bool isReviewer, AppLocalizations? localizations) {
    final plan = sub?.plan;
    final String planName = isReviewer
        ? (localizations?.reviewerAccess ?? 'REVIEWER ACCESS')
        : (plan != null && plan.isNotEmpty
            ? plan.toUpperCase()
            : (localizations?.premiumAccess ?? 'PREMIUM ACCESS'));
    final String expiryDate = isReviewer ? (localizations?.never.toUpperCase() ?? 'NEVER') : (sub?.expiry ?? 'N/A');
    final String status = isReviewer
        ? (localizations?.reviewer.toUpperCase() ?? 'REVIEWER')
        : (sub?.status?.toLowerCase() == 'active'
            ? (localizations?.active.toUpperCase() ?? 'ACTIVE')
            : (sub?.status?.toLowerCase() == 'expired'
                ? (localizations?.expired.toUpperCase() ?? 'EXPIRED')
                : (sub?.status?.toUpperCase() ?? 'ACTIVE')));
    final int? resolvedMaxDevices = (sub?.maxDevices != null && sub!.maxDevices! > 0)
        ? sub.maxDevices
        : (TokenApi.maxDevices != null && TokenApi.maxDevices! > 0
            ? TokenApi.maxDevices
            : (TokenApi.user?.subscriptionDetails?.maxDevices != null && TokenApi.user!.subscriptionDetails!.maxDevices! > 0
                ? TokenApi.user!.subscriptionDetails!.maxDevices
                : null));

    final String devices = isReviewer
        ? (localizations?.unlimited.toUpperCase() ?? 'UNLIMITED')
        : (resolvedMaxDevices?.toString() ?? '1');
    final String price = isReviewer ? (localizations?.free.toUpperCase() ?? 'FREE') : (sub?.amount ?? '0.00');

    final String unitName = sub?.planDurationType != null
        ? (sub!.planDurationType!.toLowerCase() == 'year'
            ? (localizations?.year.toUpperCase() ?? 'YEAR')
            : (localizations?.month.toUpperCase() ?? 'MONTH'))
        : (localizations?.month.toUpperCase() ?? 'MONTH');
    final String duration = isReviewer
        ? (localizations?.lifetime.toUpperCase() ?? 'LIFETIME')
        : "${sub?.planDurationValue ?? '1'} $unitName";

    final bool isExpired = !isReviewer && (sub?.status?.toLowerCase() == 'expired' || sub?.status?.toLowerCase() == 'canceled');

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: isExpired 
                ? const LinearGradient(
                    colors: [Colors.grey, Color(0xFF757575)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [AppColor.primary, Color(0xFF9E7738)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: (isExpired ? Colors.grey : AppColor.primary).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isReviewer
                          ? (localizations?.reviewerMode ?? 'REVIEWER MODE')
                          : (isExpired
                              ? (localizations?.membershipExpired ?? 'MEMBERSHIP EXPIRED')
                              : (localizations?.activeFitnessPass ?? 'ACTIVE FITNESS PASS')),
                      style: TextStyle(
                        color: AppColor.background.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12.sp,
                      ),
                    ),
                    Icon(isExpired ? Icons.history : Icons.verified, color: AppColor.background),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  planName,
                  style: TextStyle(
                    color: AppColor.background,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColor.background, size: 16),
                    SizedBox(width: 8.w),
                    Text(
                      isExpired
                          ? (localizations?.expiredOn(expiryDate) ?? 'Expired on: $expiryDate')
                          : (localizations?.expiresOn(expiryDate) ?? 'Expires on: $expiryDate'),
                      style: TextStyle(
                        color: AppColor.background,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          _buildInfoTile(Icons.info_outline, localizations?.statusLabel ?? 'Status', status),
          _buildInfoTile(Icons.devices, localizations?.devicesAllowedPerAccount ?? 'Devices allowed per account', devices),
          _buildInfoTile(Icons.timer_outlined, localizations?.planDuration ?? 'Plan Duration', duration),
          _buildInfoTile(Icons.payments_outlined, localizations?.price ?? 'Price', price),
          
          SizedBox(height: 30.h),
          
          if (!isReviewer) ...[
            if (!isExpired)
              ElevatedButton(
                onPressed: _isCancelling ? null : () => _cancelSubscription(sub),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        localizations?.cancelPremiumTitle ?? 'CANCEL PREMIUM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                      ),
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _isSendingEmail ? null : _sendAccessStepsEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.background,
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: _isSendingEmail
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: AppColor.background, strokeWidth: 2.5),
                          )
                        : Text(
                            localizations?.emailMeAccessSteps ?? 'Email Me Access Steps',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 16.sp, color: AppColor.primary),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            localizations?.refreshPageToViewStatus ??
                                'Please refresh the page in order to view subscription status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColor.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Future<void> _refreshSubscription() async {
    setState(() {
      _isRefreshing = true;
    });

    final result = await Api.instance.getLatestSubscription();

    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _isRefreshing = false);
          final msg = failure.message;
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (msg != null && msg.isNotEmpty)
                    ? msg
                    : (localizations?.failedToRefreshMembership ?? 'Failed to refresh membership'),
              ),
            ),
          );
        },
        (data) async {
          // The API returns the subscription object inside 'data' -> 'subscription' or directly in 'data'
          final dynamic subJson = (data['data'] is Map && data['data']['subscription'] != null)
              ? data['data']['subscription']
              : (data['subscription'] ?? data['data']);

          if (subJson is Map) {
            final Map<String, dynamic> subMap = Map<String, dynamic>.from(subJson);
            final maxDevicesRaw = subMap['max_devices'] ??
                data['max_devices'] ??
                (data['data'] is Map ? data['data']['max_devices'] : null) ??
                data['raw']?['max_devices'] ??
                (data['raw']?['data'] is Map ? data['raw']['data']['max_devices'] : null) ??
                subMap['maxDevices'] ??
                data['maxDevices'] ??
                subMap['deviceLimit'] ??
                (data['data'] is Map ? data['data']['deviceLimit'] : null);

            if (maxDevicesRaw != null) {
              subMap['max_devices'] = maxDevicesRaw;
            }

            final latestSub = SubscriptionDetails.fromJson(subMap);
            final String? status = latestSub.status?.toLowerCase();
            final bool isActive = status == 'active' || status == 'trialing' || status == 'praemium' || status == 'processing';

            if (latestSub.maxDevices != null && latestSub.maxDevices! > 0) {
              await TokenApi().updateMaxDevices(latestSub.maxDevices!);
            }

            await TokenApi().updateSubscriptionFromStatusResponse(
              subDetails: latestSub,
              isSubscribed: isActive ? 1 : 0,
            );
          }

          if (mounted) {
            setState(() => _isRefreshing = false);
            // Refresh the cubit to update UI
            context.read<AccountCubit>().getAccountDetails();
          }
        },
      );
    }
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColor.primary, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonSubscribedView(AppLocalizations? localizations) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/person.png'), // Fixed casing to match actual file
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        localizations?.unlimitedFitnessAccess ?? 'Unlimited Fitness Access',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        localizations?.getPremiumDesc ??
                            'Get PREMIUM to unlock exclusive workouts and premium training modules.',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: _isSendingEmail ? null : _sendAccessStepsEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.background,
                          minimumSize: Size(double.infinity, 54.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: _isSendingEmail
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: const CircularProgressIndicator(
                                  color: AppColor.background,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                localizations?.emailMeAccessSteps ?? 'Email Me Access Steps',
                                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
                              ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 16.sp, color: AppColor.primary),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                localizations?.refreshPageToViewStatus ??
                                    'Please refresh the page in order to view subscription status',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
