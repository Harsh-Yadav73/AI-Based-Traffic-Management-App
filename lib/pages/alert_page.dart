import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final TextEditingController _cityController = TextEditingController(text: "Delhi");
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];

  // 🔹 Replace with your WeatherAPI key
  final String apiKey = "dce2f37dd78f41f786984904250711";

  Future<void> fetchAlerts() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() => _error = "Please enter a city name");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _alerts.clear();
    });

    final url = "https://api.weatherapi.com/v1/alerts.json?key=$apiKey&q=$city";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final alerts = data["alerts"]?["alert"] ?? [];

      setState(() {
        if (alerts.isEmpty) {
          _error = "No active alerts for $city ✅";
        } else {
          _alerts = List<Map<String, dynamic>>.from(alerts);
        }
      });
    } catch (e) {
      setState(() => _error = "Error fetching alerts: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert["headline"] ?? "Unknown Alert",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              alert["desc"] ?? "No description available.",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              "Severity: ${alert["severity"] ?? "N/A"}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Alerts"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: "Enter City Name",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _cityController.clear(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _loading ? null : fetchAlerts,
              icon: const Icon(Icons.cloud),
              label: Text(_loading ? "Fetching..." : "Get Alerts"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _error!.contains("✅") ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: _alerts.isEmpty
                  ? Center(
                child: Text(
                  _loading ? "Loading..." : "No alerts yet",
                  style: const TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _alerts.length,
                itemBuilder: (context, i) => _buildAlertCard(_alerts[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
