import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

import '../../../l10n/app_localizations.dart';

/// Cast icon that opens a device picker: lists every Chromecast/smart TV
/// currently discoverable on the network and lets the user tap one to
/// connect. Shows a filled icon plus the connected device (with a
/// disconnect option) once a session is active.
class CastButton extends StatelessWidget {
  final double iconSize;

  const CastButton({super.key, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GoogleCastSession?>(
      stream: GoogleCastSessionManager.instance.currentSessionStream,
      initialData: GoogleCastSessionManager.instance.currentSession,
      builder: (context, snapshot) {
        final connectedDevice = snapshot.data?.device;
        final isConnected = connectedDevice != null;
        return InkWell(
          borderRadius: BorderRadius.circular(iconSize),
          onTap: () =>
              _showCastSheet(context, connectedDevice: connectedDevice),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isConnected ? Icons.cast_connected : Icons.cast,
              color: isConnected ? Colors.lightBlueAccent : Colors.white,
              size: iconSize,
            ),
          ),
        );
      },
    );
  }

  void _showCastSheet(BuildContext context,
      {GoogleCastDevice? connectedDevice}) {
    final localizations = AppLocalizations.of(context);
    GoogleCastDiscoveryManager.instance.startDiscovery();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            // Leaves room for the bottom safe-area/gesture-nav inset so the
            // sheet's content never gets clipped/overflowed at the bottom.
            bottom: 20 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cast, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      localizations?.translate('cast_to_device') ??
                          'Cast to device',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (connectedDevice != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.tv, color: Colors.lightBlueAccent),
                    title: Text(connectedDevice.friendlyName,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      localizations?.translate('connected') ?? 'Connected',
                      style: const TextStyle(
                          color: Colors.lightBlueAccent, fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        await GoogleCastSessionManager.instance.endSession();
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      child: Text(
                        localizations?.translate('disconnect') ?? 'Disconnect',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                ],
                StreamBuilder<List<GoogleCastDevice>>(
                  stream: GoogleCastDiscoveryManager.instance.devicesStream,
                  initialData: GoogleCastDiscoveryManager.instance.devices,
                  builder: (context, snapshot) {
                    final devices = (snapshot.data ?? [])
                        .where((d) => d.deviceID != connectedDevice?.deviceID)
                        .toList();

                    if (devices.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations
                                        ?.translate('searching_for_devices') ??
                                    'Searching for devices...',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: devices.map((device) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.tv, color: Colors.white70),
                          title: Text(device.friendlyName,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: device.modelName != null
                              ? Text(device.modelName!,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12))
                              : null,
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await GoogleCastSessionManager.instance
                                .startSessionWithDevice(device);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      GoogleCastDiscoveryManager.instance.stopDiscovery();
    });
  }
}
