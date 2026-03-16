import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/subscription/subscription_access.dart';
import 'camera_models.dart';

class CameraApi {
  CameraApi({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;
  static const _sessionLoggedInKey = 'session_logged_in';

  /// Bearer per Firebase (Apple/Google), X-Username per login con username/password.
  Future<Options> _cameraOptions() async {
    final headers = <String, dynamic>{};
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${currentUser.uid}';
    }
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('profile_username') ?? '';
    final sessionLoggedIn = prefs.getBool(_sessionLoggedInKey) ?? false;
    if (currentUser == null && sessionLoggedIn && username.isNotEmpty) {
      headers['X-Username'] = username;
    }
    headers['X-Subscription-Tier'] = await SubscriptionAccess.currentTierRaw();
    return Options(headers: headers);
  }

  Future<SolveResponse> solve(String imageBase64, String mediaType) async {
    final opts = await _cameraOptions();
    final response = await _client.dio.post(
      'camera/solve',
      data: {
        'image_base64': imageBase64,
        'media_type': mediaType,
      },
      options: opts,
    );
    return SolveResponse.fromJson(response.data);
  }

  Future<SolveResponse> solveText(String problemText) async {
    final opts = await _cameraOptions();
    final response = await _client.dio.post(
      'camera/solve',
      data: {
        'problem_text': problemText,
      },
      options: opts,
    );
    return SolveResponse.fromJson(response.data);
  }

  Future<List<HistoryItem>> getHistory() async {
    final opts = await _cameraOptions();
    final response = await _client.dio.get(
      'camera/history',
      options: opts,
    );
    final historyResponse = HistoryResponse.fromJson(response.data);
    return historyResponse.history;
  }

  Future<HistoryDetailResponse> getHistoryDetail(int id) async {
    final opts = await _cameraOptions();
    final response = await _client.dio.get(
      'camera/history/$id',
      options: opts,
    );
    return HistoryDetailResponse.fromJson(response.data);
  }

  Future<StatusResponse> getStatus() async {
    final opts = await _cameraOptions();
    final response = await _client.dio.get(
      'camera/status',
      options: opts,
    );
    return StatusResponse.fromJson(response.data);
  }
}
