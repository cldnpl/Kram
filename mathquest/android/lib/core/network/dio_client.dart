import 'package:dio/dio.dart';
import 'api_config.dart';

class DioClient {
  DioClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) {
        // TODO: add Authorization: Bearer <token>
        handler.next(opts);
      },
    ));
  }

  late final Dio _dio;
  Dio get dio => _dio;
}
