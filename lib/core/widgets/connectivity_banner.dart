import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/connectivity_manager.dart';
import '../../data/sync/sync_manager.dart';

class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  bool _wasOnline = true;
  bool _showReconnected = false;

  static const _bannerHeight = 36.0;
  static const _animDuration = Duration(milliseconds: 320);
  static const _reconnectedHoldDuration = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    // Detect transition: offline → online
    if (isOnline && !_wasOnline) {
      _wasOnline = true;
      _triggerReconnectedFlow();
    } else if (!isOnline) {
      _wasOnline = false;
      if (_showReconnected) setState(() => _showReconnected = false);
    }

    final showOffline = !isOnline;
    final showReconnected = _showReconnected;
    final visible = showOffline || showReconnected;

    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeInOut,
      height: visible ? _bannerHeight : 0,
      color: showReconnected
          ? const Color(0xFF27AE60)   // success green
          : const Color(0xFFF5A623),  // amber
      child: visible
          ? SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    showReconnected ? Icons.wifi : Icons.wifi_off,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    showReconnected
                        ? 'Kembali online — Menyinkronkan...'
                        : 'Kamu sedang offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _triggerReconnectedFlow() async {
    setState(() => _showReconnected = true);

    // Kick off background sync — don't await so UI stays responsive
    SyncManager.instance.syncAll();

    await Future<void>.delayed(_reconnectedHoldDuration);
    if (mounted) setState(() => _showReconnected = false);
  }
}
