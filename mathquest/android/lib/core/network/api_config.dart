/// Backend base URL — deployed server.
const String kApiBaseUrl = 'https://kram.islamov.online/api';

/// Base URL del server senza /api (per diagrammi SVG e altre risorse pubbliche senza auth).
String get kServerBaseUrl =>
    kApiBaseUrl.endsWith('/api') ? kApiBaseUrl.substring(0, kApiBaseUrl.length - 4) : kApiBaseUrl;
