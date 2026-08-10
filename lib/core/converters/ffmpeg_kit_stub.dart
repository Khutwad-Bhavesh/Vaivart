class FFmpegKit {
  static Future<dynamic> execute(String command) async {
    throw UnimplementedError('FFmpegKit is Android only');
  }
}

class ReturnCode {
  static bool isSuccess(dynamic rc) => false;
}
