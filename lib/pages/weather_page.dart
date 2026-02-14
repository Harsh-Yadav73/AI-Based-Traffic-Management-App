import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherPage extends StatelessWidget {
  final Map<String, dynamic> weather;

  const WeatherPage({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final description = weather["weather"][0]["description"];
    final temp = weather["main"]["temp"];
    final city = weather["name"];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Current Weather"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/weather_logo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: const Color.fromRGBO(255, 255, 255, 0.8),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_cloudy, size: 70, color: Colors.blue.shade700),
                  const SizedBox(height: 15),
                  Text(
                    "🌍 $city",
                    style: GoogleFonts.lato(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "🌦️ $description",
                    style: GoogleFonts.lato(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "🌡️ ${temp.toString()}°C",
                    style: GoogleFonts.lato(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
