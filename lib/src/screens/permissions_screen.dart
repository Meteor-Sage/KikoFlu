import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../utils/snackbar_util.dart';
import '../widgets/settings_section.dart';

/// 权限管理页面（仅安卓平台）
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationGranted = false;
  bool _ignoreBatteryOptimizationsGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    try {
      // 检查通知权限
      final notificationStatus = await Permission.notification.status;
      _notificationGranted = notificationStatus.isGranted;

      // 检查电池优化豁免权限（后台运行）
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      _ignoreBatteryOptimizationsGranted = batteryStatus.isGranted;
    } catch (e) {
      debugPrint('检查权限失败: $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();

      if (mounted) {
        if (status.isGranted) {
          SnackBarUtil.showSuccess(
              context, S.of(context).notificationPermissionGranted);
          await _checkPermissions();
        } else if (status.isDenied) {
          SnackBarUtil.showWarning(
              context, S.of(context).notificationPermissionDenied);
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog(S.of(context).notificationPermission);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(
            context, S.of(context).requestNotificationFailed(e.toString()));
      }
    }
  }

  Future<void> _requestIgnoreBatteryOptimizations() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();

      if (mounted) {
        if (status.isGranted) {
          SnackBarUtil.showSuccess(
              context, S.of(context).backgroundPermissionGranted);
          await _checkPermissions();
        } else if (status.isDenied) {
          SnackBarUtil.showWarning(
              context, S.of(context).backgroundPermissionDenied);
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog(S.of(context).backgroundRunningPermission);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtil.showError(
            context, S.of(context).requestBackgroundFailed(e.toString()));
      }
    }
  }

  void _showOpenSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).permissionRequired(permissionName)),
        content:
            Text(S.of(context).permissionPermanentlyDenied(permissionName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
              // 用户从设置返回后重新检查权限
              if (mounted) {
                await _checkPermissions();
              }
            },
            child: Text(S.of(context).openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 非安卓平台显示提示信息
    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).permissionManagement,
              style: const TextStyle(fontSize: 18)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).permissionsAndroidOnly,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).permissionsNotNeeded,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).permissionManagement,
            style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: S.of(context).refreshPermissionStatus,
          ),
        ],
      ),
      body: _isCheckingPermissions
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 权限说明
                SettingsInfoCard(
                  icon: Icons.lightbulb_outline,
                  title: S.of(context).permissionExplanation,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPermissionExplanation(
                        context,
                        S.of(context).notificationPermission,
                        S.of(context).notificationPermissionDesc,
                      ),
                      const SizedBox(height: 8),
                      _buildPermissionExplanation(
                        context,
                        S.of(context).backgroundRunningPermission,
                        S.of(context).backgroundRunningPermissionDesc,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 通知权限
                SettingsSectionCard(
                  child: SettingsListTile(
                    icon: Icons.notifications_outlined,
                    iconColor: _notificationGranted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    iconSize: 32,
                    title: S.of(context).notificationPermission,
                    subtitle: _notificationGranted
                        ? S.of(context).notificationGrantedStatus
                        : S.of(context).notificationDeniedStatus,
                    trailing: _notificationGranted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : FilledButton(
                            onPressed: _requestNotificationPermission,
                            child: Text(S.of(context).requestPermission),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // 后台运行权限
                SettingsSectionCard(
                  child: SettingsListTile(
                    icon: Icons.battery_charging_full,
                    iconColor: _ignoreBatteryOptimizationsGranted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    iconSize: 32,
                    title: S.of(context).backgroundRunningPermission,
                    subtitle: _ignoreBatteryOptimizationsGranted
                        ? S.of(context).backgroundGrantedStatus
                        : S.of(context).notificationDeniedStatus,
                    trailing: _ignoreBatteryOptimizationsGranted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : FilledButton(
                            onPressed: _requestIgnoreBatteryOptimizations,
                            child: Text(S.of(context).requestPermission),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionExplanation(
    BuildContext context,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
