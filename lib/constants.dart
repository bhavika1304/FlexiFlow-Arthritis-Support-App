class ApiConstants {
  static const String _env = "production"; // 👈 switch here

  static const String _localIp = "172.29.20.243";
  static const String _emulatorIp = "10.0.2.2";
  static const String _prodUrl = "https://flexiflow-backend.onrender.com";

  static String get baseUrl {
    switch (_env) {
      case "local":
        return "http://$_localIp:8000";
      case "emulator":
        return "http://$_emulatorIp:8000";
      case "production":
      default:
        return _prodUrl;
    }
  }

  // API Endpoints
  static const String analyticsEndpoint = "/api/analytics";
  static const String recordDownloadEndpoint = "/api/record-download";
  static const String submitRatingEndpoint = "/api/submit-rating";
  static const String submitCommentEndpoint = "/api/submit-comment";
}