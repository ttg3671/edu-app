import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/utils/device_util.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  bool _isLoading = true;
  List<dynamic> _devices = [];
  String? _error;
  String? _errorMessage;
  String? _currentDeviceId;
  int? _reasonCode;
  int? _deviceLimit;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _reasonCode = await TokenApi.getReasonCode();
    await _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorMessage = null;
    });

    _currentDeviceId = await DeviceUtil.getDeviceId();

    final result = await Api.instance.getConnectedDevices();
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (data) {
        setState(() {
          if (data['data'] != null) {
            _devices = (data['data']['result'] != null && data['data']['result'] is List)
                ? (data['data']['result'] as List)
                : [];
            final maxDevRaw = data['data']['max_devices'] ??
                data['data']['maxDevices'] ??
                data['data']['deviceLimit'] ??
                data['max_devices'];
            if (maxDevRaw != null) {
              final parsed = int.tryParse(maxDevRaw.toString());
              if (parsed != null && parsed > 0) {
                _deviceLimit = parsed;
                TokenApi().updateMaxDevices(parsed);
              }
            } else if (data['data']['deviceLimit'] != null) {
              _deviceLimit = data['data']['deviceLimit'] is int
                  ? data['data']['deviceLimit']
                  : int.tryParse(data['data']['deviceLimit'].toString());
            }
            if (data['data']['reasonCode'] != null) {
              _reasonCode = data['data']['reasonCode'] is int
                  ? data['data']['reasonCode']
                  : int.tryParse(data['data']['reasonCode'].toString());
            }

            // If user is not subscribed or subscription is cancelled/expired, max_screen limit is strictly 1
            final user = TokenApi.user;
            final subStatus = user?.subscriptionDetails?.status?.toLowerCase();
            final bool isCancelledOrExpired = subStatus == 'expired' || subStatus == 'canceled';
            final bool isSubscribed = user != null && user.isSubscribed == 1 && !isCancelledOrExpired;
            if (!isSubscribed && user?.isReviewer != 1) {
              _deviceLimit = 1;
            }
          } else {
            _devices = [];
          }
          _isLoading = false;
        });
      },
    );
  }

  int _getMaxDevices() {
    final user = TokenApi.user;
    final bool isReviewer = user?.isReviewer == 1;
    if (isReviewer) {
      return _deviceLimit != null && _deviceLimit! > 0 ? _deviceLimit! : 10;
    }

    final subStatus = user?.subscriptionDetails?.status?.toLowerCase();
    final bool isCancelledOrExpired = subStatus == 'expired' || subStatus == 'canceled';
    final bool isSubscribed = user != null && user.isSubscribed == 1 && !isCancelledOrExpired;

    // When subscription is cancelled or expired, max_screen limit is strictly 1
    if (!isSubscribed) {
      return 1;
    }

    // Prioritize max_devices from subscription details / TokenApi / SharedPreferences
    final storedMax = TokenApi.maxDevices;
    if (storedMax != null && storedMax > 0) {
      return storedMax;
    }

    if (user.subscriptionDetails?.maxDevices != null && user.subscriptionDetails!.maxDevices! > 0) {
      return user.subscriptionDetails!.maxDevices!;
    }

    if (_deviceLimit != null && _deviceLimit! > 0) {
      return _deviceLimit!;
    }

    return 1;
  }

  String _getDeviceCountString() {
    final int maxDevices = _getMaxDevices();
    return '${_devices.length} / $maxDevices';
  }

  Future<void> _removeDevice(String deviceId) async {
    setState(() {
      _errorMessage = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader()),
    );

    final result = await Api.instance.removeDevice(deviceIdToRemove: deviceId);
    
    if (mounted) Navigator.pop(context); // Close loading

    result.fold(
      (failure) {
        setState(() {
          _errorMessage = failure.message;
        });
      },
      (data) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device removed successfully')),
        );
        _loadDevices(); // Reload the list
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int maxDevices = _getMaxDevices();
    final int devicesToRemove = _devices.length - maxDevices;
    final bool exceedsLimit = devicesToRemove > 0;

    String? reasonMessage;
    if (exceedsLimit) {
      reasonMessage = 'You have exceeded your device limit by $devicesToRemove. Please remove at least $devicesToRemove device${devicesToRemove > 1 ? 's' : ''} to continue using the app.';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Devices', style: TextStyle(fontSize: 20.sp)),
      ),
      body: _isLoading
          ? const Center(child: Loader())
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (reasonMessage != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange, width: 1.5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          reasonMessage,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
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
                  
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Devices',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            _getDeviceCountString(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _error != null
                      ? SizedBox(
                          height: 0.6.sh,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, style: const TextStyle(color: Colors.red)),
                                SizedBox(height: 10.h),
                                ElevatedButton(
                                  onPressed: _loadDevices,
                                  child: const Text('Retry'),
                                )
                              ],
                            ),
                          ),
                        )
                      : _devices.isEmpty
                          ? SizedBox(
                              height: 0.6.sh,
                              child: const Center(child: Text('No connected devices found')),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(20.w),
                              itemCount: _devices.length,
                              separatorBuilder: (context, index) => SizedBox(height: 15.h),
                              itemBuilder: (context, index) {
                                final device = _devices[index];
                                // Field names from API: 'device_fingerprint', 'device_id', 'device_type', 'seen_at', 'is_connected'
                                final bool isConnected = device['is_connected'] == true ||
                                    device['is_connected'] == 1 ||
                                    device['is_connected']?.toString().toLowerCase() == 'true';
                                final deviceIdentifier = (device['device_fingerprint'] ?? device['device_id'] ?? '').toString();
                                final deviceType = (device['device_type'] ?? 'Unknown Device').toString();
                                final seenAt = (device['seen_at'] ?? '').toString();

                                // If is_connected is true, it is your current device that you cannot delete
                                final bool isCurrentDevice = isConnected ||
                                    (_currentDeviceId != null && _currentDeviceId!.isNotEmpty && deviceIdentifier == _currentDeviceId);
                                
                                return Container(
                                  padding: EdgeInsets.all(15.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: isCurrentDevice ? Colors.green.shade300 : Colors.grey.shade300,
                                      width: isCurrentDevice ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.devices, 
                                        size: 30.sp, 
                                        color: isCurrentDevice ? Colors.green : Colors.blue,
                                      ),
                                      SizedBox(width: 15.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  deviceType,
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (isCurrentDevice) ...[
                                                  SizedBox(width: 8.w),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade100,
                                                      borderRadius: BorderRadius.circular(4.r),
                                                    ),
                                                    child: Text(
                                                      'THIS DEVICE',
                                                      style: TextStyle(
                                                        fontSize: 10.sp,
                                                        color: Colors.green.shade700,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (seenAt.isNotEmpty)
                                              Text(
                                                'Last seen: $seenAt',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!isCurrentDevice)
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Remove Device'),
                                                content: const Text('Are you sure you want to log out from this device?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _removeDevice(deviceIdentifier);
                                                    },
                                                    child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                    ],
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
    );
  }
}
