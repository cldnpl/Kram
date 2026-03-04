/// Backend base URL.
/// - Android emulator: 10.0.2.2 is the host machine (your PC's localhost).
/// - Physical device: use your Mac's IP (e.g. 192.168.1.x).
const String kApiBaseUrl = 'http://100.126.55.229:8080/api';

/// Base URL del server senza /api (per diagrammi SVG e altre risorse pubbliche senza auth).
String get kServerBaseUrl =>
    kApiBaseUrl.endsWith('/api') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 4) : kApiBaseUrl;
