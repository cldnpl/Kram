import 'package:flutter/foundation.dart';

const String _productionApiBaseUrl = 'https://kram.islamov.online/api';
const String _androidEmulatorApiBaseUrl = 'http://10.0.2.2:8080/api';
const String _compileTimeOverrideApiBaseUrl =
    String.fromEnvironment('KRAM_API_BASE_URL', defaultValue: '');

/// Backend base URL.
String get kApiBaseUrl {
  if (_compileTimeOverrideApiBaseUrl.isNotEmpty) {
    return _compileTimeOverrideApiBaseUrl;
  }
  if (kDebugMode) {
    return _androidEmulatorApiBaseUrl;
  }
  return _productionApiBaseUrl;
}

/// Base URL del server senza /api (per immagini/diagrammi e altre risorse pubbliche senza auth).
String get kServerBaseUrl =>
    kApiBaseUrl.endsWith('/api') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 4) : kApiBaseUrl;
