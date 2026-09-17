import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../api/api.dart';
import '../../../../api/token_api.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/common/widgets/loader.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../modal/payment_plan.dart';
import 'subscription_screen.dart';

class PlansScreen extends StatefulWidget {
  /// SharedPreferences key the chosen plan's name is stored under, so
  /// SubscriptionScreen can show the user what they picked.
  static const String selectedPlanNameKey = 'planName';

  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<PaymentPlan>? _plans;
  String? _error;
  int? _selectingPlanId;

  @override
  void initState() {
    super.initState();
    // Reviewers already have full access and should never land here, but
    // guard defensively in case this screen is reached from elsewhere.
    if (TokenApi.user?.isReviewer == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _error = null;
    });

    final result = await Api.instance.getPaymentPlans();

    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message ??
              AppLocalizations.of(context)?.translate('failed_to_load_plans') ??
              'Failed to load plans';
        });
      },
      (plans) {
        setState(() {
          _plans = plans.where((p) => p.isActive == 1).toList();
        });
      },
    );
  }

  Future<void> _selectPlan(PaymentPlan plan) async {
    setState(() {
      _selectingPlanId = plan.id;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PlansScreen.selectedPlanNameKey, plan.planName);

    // Selecting a plan just takes the user to the subscription page to
    // complete checkout - it doesn't trigger any email on its own.
    final userDetails = TokenApi.user ?? await TokenApi.getUserDetails();

    if (!mounted) return;
    setState(() {
      _selectingPlanId = null;
    });

    if (userDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SubscriptionScreen(userDetails: userDetails)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations?.translate('choose_your_plan') ?? 'Choose Your Plan',
          style:
              Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16.sp),
        ),
        centerTitle: false,
      ),
      body: SafeArea(child: _buildBody(localizations)),
    );
  }

  Widget _buildBody(AppLocalizations? localizations) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
              SizedBox(height: 16.h),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.sp, color: AppColor.text)),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _loadPlans,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('Retry',
                    style:
                        TextStyle(fontSize: 14.sp, color: AppColor.background)),
              ),
            ],
          ),
        ),
      );
    }

    if (_plans == null) {
      return const Center(child: Loader());
    }

    if (_plans!.isEmpty) {
      return Center(
        child: Text(
          localizations?.translate('no_plans_available') ??
              'No plans available right now',
          style: TextStyle(fontSize: 15.sp, color: AppColor.text),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        Text(
          localizations?.translate('choose_plan_subtitle') ??
              'Subscribe to unlock this and all premium content',
          style: TextStyle(
              fontSize: 14.sp, color: AppColor.text.withValues(alpha: 0.7)),
        ),
        SizedBox(height: 20.h),
        ..._plans!.map((plan) => Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: _PlanCard(
                plan: plan,
                isLoading: _selectingPlanId == plan.id,
                onSelect: () => _selectPlan(plan),
                localizations: localizations,
              ),
            )),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PaymentPlan plan;
  final bool isLoading;
  final VoidCallback onSelect;
  final AppLocalizations? localizations;

  const _PlanCard({
    required this.plan,
    required this.isLoading,
    required this.onSelect,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final isYearly = plan.durationUnit.toLowerCase() == 'year';
    final periodSuffix = isYearly
        ? (localizations?.translate('per_year') ?? '/year')
        : (localizations?.translate('per_month') ?? '/month');

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColor.secondary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.planName.toUpperCase(),
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColor.primary),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${plan.monthlyPrice}',
                style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColor.text),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h, left: 2.w),
                child: Text(
                  periodSuffix,
                  style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColor.text.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.devices,
                  size: 16.sp, color: AppColor.text.withValues(alpha: 0.6)),
              SizedBox(width: 6.w),
              Text(
                localizations?.translate('devices_included',
                        params: {'count': plan.maxScreens.toString()}) ??
                    '${plan.maxScreens} devices included',
                style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColor.text.withValues(alpha: 0.6)),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: isLoading ? null : onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: AppColor.background,
              minimumSize: Size(double.infinity, 46.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                        color: AppColor.background, strokeWidth: 2.5),
                  )
                : Text(
                    localizations?.translate('get_this_plan') ??
                        'Get This Plan',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
