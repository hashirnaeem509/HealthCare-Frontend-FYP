 import 'dart:io';

class ApiConfig {
  static const String baseUrl = 'http://192.168.0.108:8080';  // <— correct

  static String get uploadBaseUrl {
    if (Platform.isAndroid) {
      return "http://192.168.0.108:8080";  
    } else if (Platform.isWindows) {
      return "http://localhost:8080";
    } else {
      return "http://192.168.0.108:8080";  
    }
  }


  static String resolveImageUrl(String imageUrl) {
    
    if (imageUrl.contains("10.0.2.2")) {
      return imageUrl.replaceFirst("10.0.2.2", "192.168.0.108");
    } else {
      return imageUrl;
    }
  }
}
