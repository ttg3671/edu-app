import 'package:edu_gym/api/token_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../api/api.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../modal/user_details.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/pages/login.dart';
import '../../../auth/presentation/pages/starting_screen.dart';
import '../../../home/presentation/cubit/new_home_cubit.dart';
import '../cubit/account_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'connected_devices_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserDetails userDetails;
  const SettingsScreen({super.key, required this.userDetails});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _errorMessage;
  int _connectedDevicesCount = 0;
  int? _deviceLimit;
  bool _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    final result = await Api.instance.getConnectedDevices();
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _loadingDevices = false;
          });
        }
      },
      (data) {
        if (mounted) {
          setState(() {
            final devices = (data['data'] != null && data['data']['result'] != null && data['data']['result'] is List)
                ? data['data']['result'] as List
                : [];
            if (data['data'] != null && data['data']['deviceLimit'] != null) {
              _deviceLimit = data['data']['deviceLimit'] is int
                  ? data['data']['deviceLimit']
                  : int.tryParse(data['data']['deviceLimit'].toString());
            }

            final user = TokenApi.user ?? widget.userDetails;
            final subStatus = user.subscriptionDetails?.status?.toLowerCase();
            final bool isCancelledOrExpired = subStatus == 'expired' || subStatus == 'canceled';
            final bool isSubscribed = user.isSubscribed == 1 && !isCancelledOrExpired;
            if (!isSubscribed && user.isReviewer != 1) {
              _deviceLimit = 1;
            }

            _connectedDevicesCount = devices.length;
            _loadingDevices = false;
          });
        }
      },
    );
  }

  String _getDeviceCountString() {
    final user = TokenApi.user ?? widget.userDetails;
    final bool isReviewer = user.isReviewer == 1;
    final subStatus = user.subscriptionDetails?.status?.toLowerCase();
    final bool isCancelledOrExpired = subStatus == 'expired' || subStatus == 'canceled';
    final bool isSubscribed = user.isSubscribed == 1 && !isCancelledOrExpired;

    final int maxDevices = isReviewer
        ? (_deviceLimit != null && _deviceLimit! > 0 ? _deviceLimit! : 10)
        : (!isSubscribed
            ? 1
            : (TokenApi.maxDevices ??
                (user.subscriptionDetails?.maxDevices != null && user.subscriptionDetails!.maxDevices! > 0
                    ? user.subscriptionDetails!.maxDevices!
                    : (_deviceLimit != null && _deviceLimit! > 0 ? _deviceLimit! : 1))));

    return '$_connectedDevicesCount / $maxDevices';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.translate('settings') ?? 'Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red, width: 1.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (TokenApi.user?.isReviewer != 1) ...[
              _buildSettingTile(
                context,
                icon: Icons.devices,
                title: localizations?.translate('connected_devices') ?? 'Connected Devices',
                trailing: _loadingDevices
                    ? SizedBox(
                        height: 12.h,
                        width: 12.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColor.primary),
                      )
                    : Text(
                        _getDeviceCountString(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (builder) => const ConnectedDevicesScreen()));
                  _fetchDevices(); // Refresh count when returning
                },
              ),
              _buildSettingTile(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'PREMIUM',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (builder) => SubscriptionScreen(userDetails: widget.userDetails)));
                },
              ),
            ],
            SizedBox(height: 12.h),
            _buildSettingTile(
              context,
              icon: Icons.delete_forever,
              title: localizations?.deleteAccount ?? 'Delete Account',
              isDestructive: true,
              onTap: () => _confirmDeleteAccount(context, localizations),
            ),
            SizedBox(height: 32.h),
            _buildSettingTile(
              context,
              icon: Icons.logout,
              title: localizations?.logout ?? 'LogOut',
              isLogout: true,
              onTap: () async {
                // Show loading indicator while logging out
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Call logout API
                await Api.instance.logout();

                // Close loading indicator
                if (mounted) {
                  Navigator.pop(context);
                  try {
                    context.read<AccountCubit>().reset();
                    context.read<NewHomeCubit>().loadHome();
                  } catch (_) {}
                  // Navigate to the first screen of the app (StartingScreen)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => const StartingScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
    bool isLogout = false,
  }) {
    Color tileColor = Colors.grey.withOpacity(0.05);
    Color borderColor = Colors.transparent;
    Color iconColor = AppColor.primary;
    Color textColor = AppColor.text;

    if (isDestructive) {
      tileColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.1);
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (isLogout) {
      tileColor = Colors.green.withOpacity(0.05);
      borderColor = Colors.green;
      iconColor = Colors.green;
      textColor = Colors.green;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: borderColor,
          width: isLogout ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: (isDestructive || isLogout) ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) ...[
              trailing,
              SizedBox(width: 8.w),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AppLocalizations? localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations?.translate('delete_account_title') ?? 'Delete Account'),
        content: Text(
          localizations?.translate('delete_account_message') ?? 'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localizations?.cancel ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations?.delete ?? 'Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _errorMessage = null;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await Api.instance.deleteAccount();

      if (mounted) {
        Navigator.pop(context);
        result.fold(
          (failure) {
            setState(() {
              _errorMessage = failure.message;
            });
          },
          (success) {
            try {
              context.read<AccountCubit>().reset();
              context.read<NewHomeCubit>().loadHome();
            } catch (_) {}
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (builder) => const StartingScreen()),
              (route) => false,
            );
          },
        );
      }
    }
  }
}
