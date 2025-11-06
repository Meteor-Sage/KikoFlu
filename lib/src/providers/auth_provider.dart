import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../models/user.dart';
import '../services/kikoeru_api_service.dart';
import '../services/storage_service.dart';

// Kikoeru API Service Provider
final kikoeruApiServiceProvider = Provider<KikoeruApiService>((ref) {
  return KikoeruApiService();
});

// Auth state
class AuthState extends Equatable {
  final User? currentUser;
  final String? token;
  final String? host;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.currentUser,
    this.token,
    this.host,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    User? currentUser,
    String? token,
    String? host,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      token: token ?? this.token,
      host: host ?? this.host,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  @override
  List<Object?> get props =>
      [currentUser, token, host, isLoading, error, isLoggedIn];
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final KikoeruApiService _apiService;

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = StorageService.getString('auth_token');
      final host = StorageService.getString('server_host');
      final userJson = StorageService.getMap('current_user');

      if (token != null && host != null) {
        _apiService.init(token, host);

        User? user;
        if (userJson != null) {
          user = User.fromJson(userJson);
        }

        state = state.copyWith(
          token: token,
          host: host,
          currentUser: user,
          isLoggedIn: true,
        );

        // Validate token by fetching user info
        await _refreshUserInfo();
      }
    } catch (e) {
      print('Failed to load saved auth: $e');
      await logout();
    }
  }

  Future<bool> login(String username, String password, String host) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Initialize API service with empty token first
      _apiService.init('', host);

      // Attempt login
      final response = await _apiService.login(username, password, host);

      final token = response['token'] as String?;
      if (token == null) {
        throw Exception('No token received from server');
      }

      // Normalize host URL to include protocol
      String normalizedHost;
      if (host.startsWith('http://') || host.startsWith('https://')) {
        normalizedHost = host;
      } else {
        // For remote hosts, use HTTPS; for localhost, use HTTP
        if (host.contains('localhost') ||
            host.startsWith('127.0.0.1') ||
            host.startsWith('192.168.')) {
          normalizedHost = 'http://$host';
        } else {
          normalizedHost = 'https://$host';
        }
      }

      // Update API service with real token
      _apiService.init(token, host);

      // Get user info from login response or fetch it separately
      Map<String, dynamic> userInfo;
      if (response['user'] != null) {
        // Use user info from login response
        userInfo = response;
      } else {
        // Fetch user info separately
        userInfo = await _apiService.getUserInfo();
      }

      final user = User.fromJson(userInfo);

      // Only proceed if user is actually logged in
      if (!user.loggedIn) {
        throw Exception('Login failed: User not logged in');
      }

      // Create complete user object with credentials and token (using normalized host)
      final authenticatedUser = user.copyWith(
        password: password,
        host: normalizedHost,
        token: token,
        lastUpdateTime: DateTime.now(),
      );

      // Save to storage (using normalized host)
      await StorageService.setString('auth_token', token);
      await StorageService.setString('server_host', normalizedHost);
      await StorageService.setMap('current_user', authenticatedUser.toJson());

      state = state.copyWith(
        currentUser: authenticatedUser,
        token: token,
        host: normalizedHost,
        isLoading: false,
        isLoggedIn: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> register(String username, String password, String host) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Initialize API service
      _apiService.init('', host);

      // Attempt registration
      final response = await _apiService.register(username, password, host);

      final token = response['token'] as String?;
      if (token == null) {
        throw Exception('No token received from server');
      }

      // Update API service with token
      _apiService.init(token, host);

      // Get user info from registration response or fetch it separately
      Map<String, dynamic> userInfo;
      if (response['user'] != null) {
        // Use user info from registration response
        userInfo = response;
      } else {
        // Fetch user info separately
        userInfo = await _apiService.getUserInfo();
      }

      final user = User.fromJson(userInfo);

      // Only proceed if user is actually logged in
      if (!user.loggedIn) {
        throw Exception('Registration failed: User not logged in');
      }

      // Create complete user object with credentials and token
      final authenticatedUser = user.copyWith(
        password: password,
        host: host,
        token: token,
        lastUpdateTime: DateTime.now(),
      );

      // Save to storage
      await StorageService.setString('auth_token', token);
      await StorageService.setString('server_host', host);
      await StorageService.setMap('current_user', authenticatedUser.toJson());

      state = state.copyWith(
        currentUser: authenticatedUser,
        token: token,
        host: host,
        isLoading: false,
        isLoggedIn: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> _refreshUserInfo() async {
    try {
      final userInfo = await _apiService.getUserInfo();
      final user = User.fromJson(userInfo);

      await StorageService.setMap('current_user', user.toJson());

      state = state.copyWith(currentUser: user);
    } catch (e) {
      print('Failed to refresh user info: $e');
      // If token is invalid, logout
      await logout();
    }
  }

  Future<void> updateHost(String host) async {
    if (state.token != null) {
      _apiService.init(state.token!, host);
      await StorageService.setString('server_host', host);
      state = state.copyWith(host: host);
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.remove('auth_token');
      await StorageService.remove('server_host');
      await StorageService.remove('current_user');
    } catch (e) {
      print('Failed to clear storage: $e');
    }

    state = const AuthState();
  }

  Future<void> switchUser(User user) async {
    final token = user.token;
    final host = user.host;

    if (token != null && host != null) {
      _apiService.init(token, host);
      await StorageService.setString('auth_token', token);
      await StorageService.setString('server_host', host);
      await StorageService.setMap('current_user', user.toJson());

      state = state.copyWith(
        currentUser: user,
        token: token,
        host: host,
        isLoggedIn: true,
      );
    } else {
      throw Exception('Invalid user data: missing token or host');
    }
  }

  Future<List<User>> getSavedUsers() async {
    final userKeys = StorageService.getAllUserKeys();
    final users = <User>[];

    for (final key in userKeys) {
      if (key != 'current_user' &&
          key != 'auth_token' &&
          key != 'server_host') {
        final userData = StorageService.getUser<Map<String, dynamic>>(key);
        if (userData != null) {
          try {
            users.add(User.fromJson(userData));
          } catch (e) {
            // Invalid user data, remove it
            await StorageService.removeUser(key);
          }
        }
      }
    }

    return users;
  }

  Future<void> saveUser(User user) async {
    final key = 'user_${user.name}_${user.host}';
    await StorageService.setUser(key, user.toJson());
  }

  Future<void> removeUser(User user) async {
    final key = 'user_${user.name}_${user.host}';
    await StorageService.removeUser(key);

    // If removing current user, logout
    if (state.currentUser == user) {
      await logout();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(kikoeruApiServiceProvider);
  return AuthNotifier(apiService);
});

// Convenience providers
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).currentUser;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

final serverHostProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).host;
});
