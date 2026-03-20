import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = true, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(AuthState(isLoading: true)) {
    initialize();
  }

  Future<void> initialize() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      state = state.copyWith(isLoading: true);
      try {
        final profileRes = await _api.dio.get(ApiEndpoints.profile);
        final user = UserModel.fromJson(profileRes.data);
        state = state.copyWith(user: user, isLoading: false);
      } catch (e) {
        await logout();
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.post(ApiEndpoints.login, data: {
        'phone_number': username, // SimpleJWT requires the USERNAME_FIELD key, which is phone_number
        'password': password,
      });
      
      final access = response.data['access'];
      final refresh = response.data['refresh'];
      
      await _storage.write(key: 'accessToken', value: access);
      await _storage.write(key: 'refreshToken', value: refresh);
      
      // Fetch profile
      final profileRes = await _api.dio.get(ApiEndpoints.profile);
      final user = UserModel.fromJson(profileRes.data);
      
      state = state.copyWith(user: user, isLoading: false);
    } on DioException catch (e) {
      String errorMessage = 'Login failed. Please check your credentials.';
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage = 'Network Error: Unreachable server. Check if the backend is running and your IP is correct.';
      } else if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else {
          for (var key in data.keys) {
            final val = data[key];
            if (val is List && val.isNotEmpty) {
              errorMessage = "${key.toUpperCase()}: ${val[0].toString()}";
              break;
            } else if (val is String) {
              errorMessage = "${key.toUpperCase()}: $val";
              break;
            }
          }
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred during login.');
    }
  }

  Future<void> register({
    required String name,
    required String username,
    required String phone,
    required String email,
    required String password,
    String? dob,
    String? gender,
    String role = 'PASSENGER',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.dio.post(ApiEndpoints.register, data: {
        'full_name': name,
        'username': username,
        'phone_number': phone,
        'email': email,
        'password': password,
        'role': role,
        'dob': dob,
        'gender': gender,
      });
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      String errorMessage = 'Registration failed.';
      if (e.response?.data != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        // Extract the first error message from any field and prefix with the field name
        for (var key in data.keys) {
          final val = data[key];
          if (val is List && val.isNotEmpty) {
            errorMessage = "${key.toUpperCase()}: ${val[0].toString()}";
            break;
          } else if (val is String) {
            errorMessage = "${key.toUpperCase()}: $val";
            break;
          }
        }
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = AuthState(isLoading: false);
  }
}
