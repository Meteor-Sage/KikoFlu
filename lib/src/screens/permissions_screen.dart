import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('通知权限已授予'),
              backgroundColor: Colors.green,
            ),
          );
          await _checkPermissions();
        } else if (status.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('通知权限被拒绝'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog('通知权限');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请求通知权限失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestIgnoreBatteryOptimizations() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();

      if (mounted) {
        if (status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('后台运行权限已授予'),
              backgroundColor: Colors.green,
            ),
          );
          await _checkPermissions();
        } else if (status.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('后台运行权限被拒绝'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (status.isPermanentlyDenied) {
          _showOpenSettingsDialog('后台运行权限');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('请求后台运行权限失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOpenSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('需要$permissionName'),
        content: Text('$permissionName已被永久拒绝，请在系统设置中手动开启。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
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
            child: const Text('打开设置'),
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
          title: const Text('权限管理', style: TextStyle(fontSize: 18)),
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
                '权限管理仅在安卓平台可用',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '其他平台不需要手动管理这些权限',
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
        title: const Text('权限管理', style: TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: '刷新权限状态',
          ),
        ],
      ),
      body: _isCheckingPermissions
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 权限说明
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '权限说明',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPermissionExplanation(
                          context,
                          '通知权限',
                          '用于显示媒体播放通知栏，让您可以在锁屏和通知栏中控制播放。',
                        ),
                        const SizedBox(height: 8),
                        _buildPermissionExplanation(
                          context,
                          '后台运行权限',
                          '让应用免受电池优化限制，确保音频在后台持续播放不被系统杀死。',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 通知权限
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: _notificationGranted
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    title: const Text('通知权限'),
                    subtitle: Text(
                      _notificationGranted
                          ? '已授权 - 可以显示播放通知和控制器'
                          : '未授权 - 点击申请权限',
                    ),
                    trailing: _notificationGranted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : FilledButton(
                            onPressed: _requestNotificationPermission,
                            child: const Text('申请'),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // 后台运行权限
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.battery_charging_full,
                      color: _ignoreBatteryOptimizationsGranted
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    title: const Text('后台运行权限'),
                    subtitle: Text(
                      _ignoreBatteryOptimizationsGranted
                          ? '已授权 - 应用可以在后台持续运行'
                          : '未授权 - 点击申请权限',
                    ),
                    trailing: _ignoreBatteryOptimizationsGranted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : FilledButton(
                            onPressed: _requestIgnoreBatteryOptimizations,
                            child: const Text('申请'),
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
