import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../services/download_path_service.dart';
import '../services/download_service.dart';
import '../services/log_service.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/settings_section.dart';

class DownloadPathSettingsScreen extends ConsumerStatefulWidget {
  const DownloadPathSettingsScreen({super.key});

  @override
  ConsumerState<DownloadPathSettingsScreen> createState() =>
      _DownloadPathSettingsScreenState();
}

class _DownloadPathSettingsScreenState
    extends ConsumerState<DownloadPathSettingsScreen> {
  String? _currentPath;
  bool _isLoading = false;
  bool _isMigrating = false;

  String _getPlatformHint(BuildContext context) {
    final s = S.of(context);
    if (Platform.isAndroid) return s.platformHintAndroid;
    if (Platform.isIOS) return s.platformHintIOS;
    if (Platform.isWindows) return s.platformHintWindows;
    if (Platform.isMacOS) return s.platformHintMacOS;
    if (Platform.isLinux) return s.platformHintLinux;
    return s.platformHintDefault;
  }

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    setState(() => _isLoading = true);

    try {
      final current = await DownloadPathService.getDownloadDirectory();

      if (!mounted) return;
      setState(() {
        _currentPath = current.path;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar(S.of(context).loadPathFailedWithError('$e'),
            isError: true);
      }
    }
  }

  Future<void> _selectCustomPath() async {
    if (!DownloadPathService.isPlatformSupported()) {
      _showSnackBar(S.of(context).platformNotSupportCustomPath, isError: true);
      return;
    }

    // 检查是否有下载任务正在进行
    if (DownloadService.instance.hasActiveDownloads) {
      final count = DownloadService.instance.activeDownloadCount;
      _showSnackBar(S.of(context).activeDownloadsWarning(count), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedPath = await DownloadPathService.pickCustomDirectory();

      if (selectedPath == null) {
        setState(() => _isLoading = false);
        return; // 用户取消选择
      }

      // 显示确认对话框
      if (mounted) {
        final confirmed = await _showMigrationConfirmDialog(selectedPath);
        if (!confirmed) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // 开始迁移
      setState(() {
        _isLoading = false;
        _isMigrating = true;
      });

      final result = await DownloadPathService.setCustomPath(selectedPath);

      if (!mounted) return;
      setState(() => _isMigrating = false);

      if (result.success) {
        await _loadPaths();

        // 触发 DownloadService 重新加载
        await DownloadService.instance.reloadMetadataFromDisk();

        // 触发字幕库刷新（路径已更改）
        ref.read(subtitleLibraryRefreshTriggerProvider.notifier).state++;

        // 延迟显示成功消息
        if (mounted) {
          Future.microtask(() {
            if (mounted) {
              _showSnackBar(result.message);
            }
          });
        }
      } else {
        // 延迟显示错误消息
        if (mounted) {
          Future.microtask(() {
            if (mounted) {
              _showSnackBar(result.message, isError: true);
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isMigrating = false;
      });

      // 延迟显示错误消息
      Future.microtask(() {
        if (mounted) {
          _showSnackBar(S.of(context).setPathFailedWithError('$e'),
              isError: true);
        }
      });
    }
  }

  Future<bool> _showMigrationConfirmDialog(String newPath) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).confirmMigrateFiles),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context).migrateFilesToNewDir),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                newPath,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context).migrationMayTakeTime,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).confirmMigrate),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _resetToDefault() async {
    // 检查是否有下载任务正在进行
    if (DownloadService.instance.hasActiveDownloads) {
      final count = DownloadService.instance.activeDownloadCount;
      _showSnackBar(S.of(context).activeDownloadsWarning(count), isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).restoreDefaultPath),
        content: Text(S.of(context).restoreDefaultPathConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context).confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isMigrating = true);

    try {
      final result = await DownloadPathService.migrateToDefaultPath();

      if (!result.success) {
        if (mounted) {
          _showSnackBar(result.message, isError: true);
        }
        return;
      }

      await _loadPaths();

      // 触发重新加载
      await DownloadService.instance.reloadMetadataFromDisk();

      // 延迟显示成功消息
      if (mounted) {
        final message = result.message.isNotEmpty
            ? result.message
            : S.of(context).defaultPathRestored;
        Future.microtask(() {
          if (mounted) {
            _showSnackBar(message);
          }
        });
      }
    } catch (e) {
      // 延迟显示错误消息
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            _showSnackBar(S.of(context).resetPathFailedWithError('$e'),
                isError: true);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    try {
      if (isError) {
        SnackBarUtil.showError(context, message,
            duration: const Duration(seconds: 4));
      } else {
        SnackBarUtil.showInfo(context, message,
            duration: const Duration(seconds: 2));
      }
    } catch (e) {
      logOutput('[DownloadPathSettings] 无法显示 SnackBar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomPath = DownloadPathService.hasCustomPath();

    return SettingsSubpageScaffold(
      title: S.of(context).downloadPathSettings,
      body: _isMigrating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    S.of(context).migratingFiles,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).doNotCloseApp,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 平台提示
                SettingsInfoCard(
                  icon: Icons.info_outline,
                  child: Text(
                    _getPlatformHint(context),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),

                // 当前路径
                Text(
                  S.of(context).currentDownloadPath,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SettingsSectionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    hasCustomPath
                                        ? Icons.folder_special
                                        : Icons.folder,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    hasCustomPath
                                        ? S.of(context).customPath
                                        : S.of(context).defaultPath,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(
                                  _currentPath ?? S.of(context).loading,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 操作按钮
                if (DownloadPathService.isPlatformSupported()) ...[
                  FilledButton.icon(
                    onPressed:
                        _isLoading || _isMigrating ? null : _selectCustomPath,
                    icon: const Icon(Icons.folder_open),
                    label: Text(hasCustomPath
                        ? S.of(context).changeCustomPath
                        : S.of(context).setCustomPath),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  if (hasCustomPath) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed:
                          _isLoading || _isMigrating ? null : _resetToDefault,
                      icon: const Icon(Icons.restore),
                      label: Text(S.of(context).restoreDefaultPath),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ] else ...[
                  SettingsSectionCard(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        S.of(context).platformNotSupportCustomPath,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 说明文本
                SettingsSectionCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              S.of(context).usageInstructions,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          S.of(context).downloadPathUsageDesc,
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
