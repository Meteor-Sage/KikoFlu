import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Triggers when Settings screen should refresh cache-related information.
final settingsCacheRefreshTriggerProvider = StateProvider<int>((ref) => 0);
