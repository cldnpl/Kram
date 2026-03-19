import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';

class DioClient {
  DioClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          if (token != null) {
            opts.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(opts);
      },
      onError: (err, handler) async {
        final req = err.requestOptions;
        final status = err.response?.statusCode ?? 0;
        final method = req.method.toUpperCase();
        final retryCount = (req.extra['retry_count'] as int?) ?? 0;
        final shouldRetry =
            method == 'GET' &&
            (status == 502 || status == 503 || status == 504) &&
            retryCount < 3;

        if (!shouldRetry) {
          handler.next(err);
          return;
        }

        req.extra['retry_count'] = retryCount + 1;
        final backoffMs = 400 * (retryCount + 1);
        await Future<void>.delayed(Duration(milliseconds: backoffMs));

        try {
          final response = await _dio.fetch(req);
          handler.resolve(response);
        } catch (e) {
          if (e is DioException) {
            handler.next(e);
          } else {
            handler.next(err);
          }
        }
      },
    ));
  }

  late final Dio _dio;
  Dio get dio => _dio;
}
