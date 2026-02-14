import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "e8df01ce6b78b0ef9b5f3b2aac217265"; // your API key

  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
