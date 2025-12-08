 import 'dart:io';

class ApiConfig {
  static const String baseUrl = 'http://10.251.232.148:8080';  // <— correct

  static String get uploadBaseUrl {
    if (Platform.isAndroid) {
      return "http://10.251.232.148:8080";  // <— use laptop Wi-Fi IP
    } else if (Platform.isWindows) {
      return "http://localhost:8080";
    } else {
      return "http://10.251.232.148:8080";  // <— same for physical phone
    }
  }


  static String resolveImageUrl(String imageUrl) {
    // If your imageUrl contains emulator IP, replace it with Wi-Fi IP
    if (imageUrl.contains("10.0.2.2")) {
      return imageUrl.replaceFirst("10.0.2.2", "10.251.232.148");
    } else {
      return imageUrl;
    }
  }
}
