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

  // Device (최신 명세)
  static String deviceList(int roomId) => '$apiBase/room/$roomId/devices';
  static String devicePower(int deviceId) => '$baseUrl/thinq/power/$deviceId';
  static const String deviceListAll = '$apiBase/device/list';
  static const String deviceControl = '$apiBase/device/control';

  // Sensor
  static const String sensorList = '$baseUrl/sensors';
  static const String sensorCreate = '$baseUrl/sensor';
  static const String sensorDelete = '$baseUrl/sensor';
  static String sensorScore(String serial) => '$apiBase/scores/sensor/$serial';
  // 센서 실시간 데이터 (최신 스냅샷)
  static String sensorLatestSnapshot(String serial) =>
      '$apiBase/snapshots/latest/$serial';
  // 센서 시간별 스냅샷 (hour: 'YYYY-MM-DDTHH:00:00' 형식)
  static String sensorHourlySnapshot(String serial, String hour) =>
      '$apiBase/snapshots/$serial/$hour';

  // Stats/Reports
  static String dailyReport(String serial) => '$apiBase/reports/daily/$serial';
  static String weeklyReport(String serial) =>
      '$apiBase/reports/weekly/$serial';

  // Score
  static const String todayScore = '$apiBase/score/today';
}
