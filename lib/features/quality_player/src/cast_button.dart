import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

import '../../../l10n/app_localizations.dart';
import 'cast_error_reporter.dart';

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
        // The stream also reports sessions that are still connecting or
        // already shutting down; only a connected one counts.
        final connectionState = snapshot.data?.connectionState;
        final isConnected =
            connectionState == GoogleCastConnectState.connected;
        final isConnecting =
            connectionState == GoogleCastConnectState.connecting;
        final connectedDevice = isConnected ? snapshot.data?.device : null;
        return InkWell(
          borderRadius: BorderRadius.circular(iconSize),
          onTap: () =>
              _showCastSheet(context, connectedDevice: connectedDevice),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: isConnecting
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : Icon(
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
    GoogleCastDiscoveryManager.instance.startDiscovery().catchError(
        (Object e, StackTrace s) =>
            reportCastError(e, s, 'start discovery failed'));
    // Stopping discovery while a session is still being established drops the
    // route mid-connect, so only stop when the sheet closes without a pick.
    var deviceSelected = false;

    // Log a non-fatal if nothing has been discovered after 15s.
    final discoveryTimer = Timer(const Duration(seconds: 15), () {
      if (GoogleCastDiscoveryManager.instance.devices.isEmpty) {
        reportCastError(
            StateError('No Cast devices discovered after 15 seconds'),
            null,
            'no devices discovered');
      }
    });

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
                        // Also stop the video on the TV: a plain
                        // endSession() leaves it playing there with nothing
                        // in the app able to control it any more.
                        try {
                          await GoogleCastSessionManager.instance
                              .endSessionAndStopCasting();
                        } catch (e, s) {
                          reportCastError(e, s, 'end session failed');
                        }
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
                            deviceSelected = true;
                            Navigator.pop(sheetContext);
                            try {
                              final started = await GoogleCastSessionManager
                                  .instance
                                  .startSessionWithDevice(device);
                              if (!started) {
                                reportCastError(
                                    StateError(
                                        'startSessionWithDevice returned false '
                                        '(${device.modelName ?? 'unknown model'})'),
                                    null,
                                    'connect failed');
                              }
                            } catch (e, s) {
                              reportCastError(e, s, 'connect failed');
                            }
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
      discoveryTimer.cancel();
      if (!deviceSelected) {
        GoogleCastDiscoveryManager.instance.stopDiscovery();
      }
    });
  }
}
