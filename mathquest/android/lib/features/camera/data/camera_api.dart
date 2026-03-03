import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'camera_models.dart';

class CameraApi {
  CameraApi({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Options get _authOptions => Options(
        headers: {'Authorization': 'Bearer mock-dev-token'},
      );

  Future<SolveResponse> solve(String imageBase64, String mediaType) async {
    final response = await _client.dio.post(
      'camera/solve',
      data: {
        'image_base64': imageBase64,
        'media_type': mediaType,
      },
      options: _authOptions,
    );
    return SolveResponse.fromJson(response.data);
  }

  Future<List<HistoryItem>> getHistory() async {
    final response = await _client.dio.get(
      'camera/history',
      options: _authOptions,
    );
    final historyResponse = HistoryResponse.fromJson(response.data);
    return historyResponse.history;
  }

  Future<HistoryDetailResponse> getHistoryDetail(int id) async {
    final response = await _client.dio.get(
      'camera/history/$id',
      options: _authOptions,
    );
    return HistoryDetailResponse.fromJson(response.data);
  }

  Future<StatusResponse> getStatus() async {
    final response = await _client.dio.get(
      'camera/status',
      options: _authOptions,
    );
    return StatusResponse.fromJson(response.data);
  }
}
