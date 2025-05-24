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
  static String roomScore(int roomId) => '$apiBase/scores/room/$roomId';
  static String roomParticipants(int roomId) =>
      '$apiBase/room/$roomId/participants';

  // Device
  static String deviceList(int roomId) =>
      '$baseUrl/thinq/devices/$roomId?deviceId=$roomId';
  static String devicePower(int deviceId) => '$baseUrl/thinq/power/$deviceId';
  static const String deviceListAll = '$apiBase/device/list';
  static const String deviceControl = '$apiBase/device/control';

  // Sensor
  static const String sensorList = '$baseUrl/sensors';
  static const String sensorCreate = '$baseUrl/sensor';
  static const String sensorDelete = '$baseUrl/sensor';
  static String sensorScore(String serial) => '$apiBase/scores/sensor/$serial';

  // Stats/Reports
  static String dailyReport(String serial) => '$apiBase/reports/daily/$serial';
  static String weeklyReport(String serial) =>
      '$apiBase/reports/weekly/$serial';

  // Score
  static const String todayScore = '$apiBase/score/today';
}
