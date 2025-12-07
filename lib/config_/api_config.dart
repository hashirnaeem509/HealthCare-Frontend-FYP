import 'dart:io';

class ApiConfig {
  static const String baseUrl = 'http://192.168.0.103:8080';

  static String get uploadBaseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080"; // for emulator
    } else if (Platform.isWindows) {
      return "http://localhost:8080"; // for Flutter desktop
    } else {
      return "http://192.168.0.103:8080"; // for physical phone
    }
  }

  /// Fix for images saved using emulator URL but displayed on phone
  static String resolveImageUrl(String imageUrl) {
    if (Platform.isAndroid && imageUrl.contains("10.0.2.2")) {
      return imageUrl; // emulator OK
    } else if (imageUrl.contains("10.0.2.2")) {
      // when running on physical phone or other device
      return imageUrl.replaceFirst("10.0.2.2", "192.168.0.103");
    } else {
      return imageUrl;
    }
  }
}
