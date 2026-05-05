import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  bool _isLoading = true;
  List<dynamic> _devices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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
          // The API returns the list in data['data']['result']
          _devices = (data['data'] != null && data['data']['result'] != null) 
              ? data['data']['result'] 
              : [];
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _removeDevice(String deviceId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader()),
    );

    final result = await Api.instance.removeDevice(deviceIdToRemove: deviceId);
    
    if (mounted) Navigator.pop(context); // Close loading

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message ?? 'Failed to remove device')),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Connected Devices', style: TextStyle(fontSize: 20.sp)),
      ),
      body: _isLoading
          ? const Center(child: Loader())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 10.h),
                      ElevatedButton(
                        onPressed: _loadDevices,
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                )
              : _devices.isEmpty
                  ? const Center(child: Text('No connected devices found'))
                  : ListView.separated(
                      padding: EdgeInsets.all(20.w),
                      itemCount: _devices.length,
                      separatorBuilder: (context, index) => SizedBox(height: 15.h),
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        // Field names in API: 'device_id' and 'device_name'
                        final deviceId = device['device_id'] ?? 'Unknown ID';
                        final deviceName = device['device_name'] ?? 'Unknown Device';
                        final seenAt = device['seen_at'] ?? '';
                        
                        return Container(
                          padding: EdgeInsets.all(15.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.devices, size: 30.sp, color: Colors.blue),
                              SizedBox(width: 15.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deviceName,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'ID: $deviceId',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (seenAt.isNotEmpty)
                                      Text(
                                        'Last seen: $seenAt',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
                                            _removeDevice(deviceId);
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
    );
  }
}
