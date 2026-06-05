class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api/v1',
  );

  static const String voiceTokenEndpoint = '$baseUrl/conversations/voice-token';
}

