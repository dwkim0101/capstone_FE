class ApiConstants {
  static const String baseUrl = 'https://smartair.site';
  static const String apiBase = '$baseUrl/api';

  // Auth
  static const String login = '$baseUrl/login';
  static const String reissue = '$baseUrl/reissue';
  static const String userInfo = '$baseUrl/userinfo';

  // Room
  static const String roomList = '$apiBase/room/rooms';
  static const String roomCreate = '$apiBase/room';
  static String roomDetail(int roomId) => '$apiBase/admin/rooms/$roomId';
  static String roomUpdate(int roomId) => '$apiBase/admin/rooms/$roomId';
  static String roomDelete(int roomId) => '$apiBase/admin/rooms/$roomId';
  static String roomParticipants(int roomId) =>
      '$apiBase/room/$roomId/participants';
  static String roomJoin(int roomId) => '$apiBase/room/$roomId/join';
  static String roomPatPermissionRequest(int roomId) =>
      '$apiBase/room/$roomId/pat-permission-request';
  static String roomScore(int roomId) => '$apiBase/scores/room/$roomId';
  static String roomLatestScore(int roomId) =>
      '$apiBase/scores/room/$roomId/latest';
  static String roomAverageScore(int roomId) =>
      '$apiBase/scores/room/$roomId/average';
  static String roomSensors(int roomId) => '$apiBase/room/$roomId/sensors';

  // Device (Swagger 명세 기준)
  static String thinqDeviceList(int roomId) =>
      '$baseUrl/thinq/devices/all/$roomId';
  static String thinqDeviceRegisteredList(int roomId) =>
      '$baseUrl/thinq/devices/registed/$roomId';
  static String thinqDeviceStatus(int deviceId) =>
      '$baseUrl/thinq/status/$deviceId';
  static String thinqDevicePower(int deviceId) =>
      '$baseUrl/thinq/power/$deviceId';
  static String thinqDeviceUpdate(int deviceId, int roomId) =>
      '$baseUrl/thinq/$deviceId/$roomId';
  static String thinqAuthenticate(int roomId) =>
      '$baseUrl/thinq/authentication/$roomId';

  // PAT
  static const String patSave = '$baseUrl/pat';
  static String patPermissionApprove(int roomParticipantId) =>
      '$apiBase/room/pat-permission-request/$roomParticipantId/approve';
  static String patPermissionReject(int roomParticipantId) =>
      '$apiBase/room/pat-permission-request/$roomParticipantId/reject';

  // Sensor
  static const String sensorCreate = '$baseUrl/sensor';
  static const String sensorDelete = '$baseUrl/sensor';
  static String sensorById(int sensorId) => '$baseUrl/sensor/$sensorId';
  static const String userSensors = '$baseUrl/user/sensors';
  static String sensorAddToRoom = '$baseUrl/sensor/room';
  static String sensorRemoveFromRoom = '$baseUrl/sensor/room';
  static String sensorStatus(String serial) =>
      '$baseUrl/sensor/status?deviceSerialNumber=$serial';
  static String sensorMappingWithRoom = '$baseUrl/sensorMappingWithRoom';

  // Score/통계/스냅샷
  static String sensorScore(String serial) => '$apiBase/scores/sensor/$serial';
  static String sensorLatestScore(String serial) =>
      '$apiBase/scores/sensor/$serial/latest';
  static String sensorAverageScore(String serial) =>
      '$apiBase/scores/sensor/$serial/average';
  static String roomScores(int roomId) => '$apiBase/scores/room/$roomId';
  static String roomLatestScores(int roomId) =>
      '$apiBase/scores/room/$roomId/latest';
  static String roomAverageScores(int roomId) =>
      '$apiBase/scores/room/$roomId/average';
  static String sensorLatestSnapshot(String serial) =>
      '$apiBase/snapshots/latest/$serial';
  static String sensorHourlySnapshot(String serial, String start, String end) =>
      '$apiBase/snapshots/$serial/$start/$end';

  // Reports
  static String dailyReport(String serial) => '$apiBase/reports/daily/$serial';
  static String dailyReportByDate(String serial, String date) =>
      '$apiBase/reports/daily/$serial/$date';
  static String weeklyReport(String serial) =>
      '$apiBase/reports/weekly/$serial';
  static String weeklyReportByYearWeek(String serial, int year, int week) =>
      '$apiBase/reports/weekly/$serial/$year/$week';
  static String anomalyReport(String serial, String start, String end) =>
      '$apiBase/reports/anomaly/$serial/$start/$end';

  // User Satisfaction
  static String userSatisfaction(int roomId) =>
      '$baseUrl/userSatisfaction/$roomId';
  static String updateUserSatisfaction(
    int satisfactionId,
    double newSatisfaction,
  ) =>
      '$baseUrl/userSatisfaction/$satisfactionId?newSatisfaction=$newSatisfaction';
  static String deleteUserSatisfaction(int satisfactionId) =>
      '$baseUrl/userSatisfaction/$satisfactionId';
  static String setUserSatisfaction(int roomId, double satisfaction) =>
      '$baseUrl/userSatisfaction/$roomId?satisfaction=$satisfaction';

  // 예측 공기질
  static String predictedAirQuality(String serial) =>
      '$baseUrl/predictedAirQuality?sensorSerialNumber=$serial';
  static const String setPredictedAirQuality = '$baseUrl/predictedAirQuality';

  // FCM
  static String setFcmToken(String fcmToken) =>
      '$baseUrl/login/fcmToken?fcmToken=$fcmToken';

  // 카카오 로그인
  static const String kakaoLoginPage = '$baseUrl/login/page';
  static const String kakaoLoginCallback = '$baseUrl/login/oauth2/kakao';

  // OpenWeatherMap (외부 공기질)
  static const String openWeatherMapBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  // ⚠️ 아래 API 키는 절대 깃에 커밋하지 마세요! (환경변수/비밀관리 권장)
  static const String openWeatherMapApiKey = '3e1c030af5ee6a0521d3dcdc4e215f56';
  static String openWeatherAirPollution(double lat, double lon) =>
      '$openWeatherMapBaseUrl/air_pollution?lat=$lat&lon=$lon&appid=$openWeatherMapApiKey';
}
