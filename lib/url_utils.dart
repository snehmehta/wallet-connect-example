import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) throw Exception('Wrong format $url');

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  static openUri(Uri uri) async {
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }
}
