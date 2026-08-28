import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/update_provider.dart';
import '../widgets/scrollable_appbar.dart';
import '../widgets/settings_section.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  static final Uri _repoUri =
      Uri.parse('https://github.com/Meteor-Sage/Kikoeru-Flutter');
  late final Future<_AboutData> _aboutFuture;

  @override
  void initState() {
    super.initState();
    _aboutFuture = _loadAboutData();

    // Mark update as notified when entering this screen (hide red dot only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updateService = ref.read(updateServiceProvider);
      updateService.markAsNotified();
      // Only hide red dot, keep the "New Version" badge visible
      ref.read(showUpdateRedDotProvider.notifier).state = false;
    });
  }

  Future<_AboutData> _loadAboutData() async {
    var version = 'Unknown';
    var buildNumber = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      buildNumber = info.buildNumber;
    } catch (error, stackTrace) {
      debugPrint('AboutScreen: failed to load app version: $error');
      debugPrint(stackTrace.toString());
    }

    var licenseText = 'Failed to load LICENSE';
    try {
      final raw = await rootBundle.loadString('LICENSE');
      licenseText = raw.trim().isEmpty ? 'LICENSE is empty' : raw.trim();
    } catch (error, stackTrace) {
      debugPrint('AboutScreen: failed to load license: $error');
      debugPrint(stackTrace.toString());
    }

    return _AboutData(
      version: version,
      buildNumber: buildNumber,
      license: licenseText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScrollableAppBar(
        title: Text(S.of(context).aboutTitle,
            style: const TextStyle(fontSize: 18)),
      ),
      body: FutureBuilder<_AboutData>(
        future: _aboutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied, size: 48),
                    const SizedBox(height: 12),
                    Text(S.of(context).failedToLoadAbout),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _aboutFuture = _loadAboutData();
                        });
                      },
                      child: Text(S.of(context).retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final versionLabel = data.buildNumber.isNotEmpty
              ? '${data.version} (${data.buildNumber})'
              : data.version;

          final primaryColor = Theme.of(context).colorScheme.primary;
          final updateInfo = ref.watch(updateInfoProvider);
          final isCheckingUpdate = ref.watch(isCheckingUpdateProvider);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Update check card - shown at top if update available
              if (updateInfo != null && updateInfo.hasNewVersion)
                SettingsSectionCard(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.system_update,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    title: Text(
                      S.of(context).newVersionFound,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      S.of(context).newVersionAvailable(
                          updateInfo.latestVersion, updateInfo.currentVersion),
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    trailing: Icon(
                      Icons.open_in_new,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    onTap: () => _openUrl(updateInfo.releaseUrl),
                  ),
                ),
              if (updateInfo != null && updateInfo.hasNewVersion)
                const SizedBox(height: 16),

              SettingsSectionCard(
                child: SettingsListTile(
                  icon: Icons.verified,
                  iconColor: primaryColor,
                  title: S.of(context).versionInfo,
                  subtitle: S.of(context).currentVersion(versionLabel),
                  trailing: isCheckingUpdate
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _manualCheckUpdate,
                          child: Text(S.of(context).checkUpdate),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SettingsSectionCard(
                child: SettingsListTile(
                  icon: Icons.person_outline,
                  iconColor: primaryColor,
                  title: S.of(context).author,
                  subtitle: 'Meteor-Sage',
                ),
              ),
              const SizedBox(height: 16),
              SettingsSectionCard(
                child: SettingsListTile(
                  icon: Icons.link,
                  iconColor: primaryColor,
                  title: S.of(context).projectRepo,
                  subtitle: _repoUri.toString(),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openRepository(),
                ),
              ),
              const SizedBox(height: 16),
              SettingsSectionCard(
                child: SettingsListTile(
                  icon: Icons.gavel_outlined,
                  iconColor: primaryColor,
                  title: S.of(context).openSourceLicense,
                  subtitle: 'LICENSE',
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showLicenseDialog(data.license),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openRepository() async {
    await _openUrl(_repoUri.toString());
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).cannotOpenLink)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).openLinkFailed(error.toString()))),
      );
    }
  }

  Future<void> _manualCheckUpdate() async {
    if (ref.read(isCheckingUpdateProvider)) return;

    ref.read(isCheckingUpdateProvider.notifier).state = true;

    try {
      final updateService = ref.read(updateServiceProvider);
      final updateInfo = await updateService.checkForUpdates(force: true);

      if (!mounted) return;

      if (updateInfo != null && updateInfo.hasNewVersion) {
        ref.read(updateInfoProvider.notifier).state = updateInfo;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(S.of(context).foundNewVersion(updateInfo.latestVersion)),
            action: SnackBarAction(
              label: S.of(context).view,
              onPressed: () => _openUrl(updateInfo.releaseUrl),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).alreadyLatestVersion)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).checkUpdateFailed)),
      );
    } finally {
      if (mounted) {
        ref.read(isCheckingUpdateProvider.notifier).state = false;
      }
    }
  }

  void _showLicenseDialog(String license) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).openSourceLicense),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(license),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).close),
            ),
          ],
        );
      },
    );
  }
}

class _AboutData {
  final String version;
  final String buildNumber;
  final String license;

  const _AboutData({
    required this.version,
    required this.buildNumber,
    required this.license,
  });
}
