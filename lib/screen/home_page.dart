import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/sos_location_map_page.dart';

// ⭐ ADD THIS
import '../pages/emergency_contacts_page.dart';

import '../services/weather_service.dart';
import '../services/location_helper.dart';
import '../pages/weather_page.dart';
import '../pages/map_page.dart';
import '../pages/alert_page.dart';
import '../pages/history_page.dart';
import '../pages/fuel_station_page.dart';
import '../pages/parking_page.dart';
import '../pages/sos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _getCurrentLocation();
    _startSOSListener();
  }

  // 🔥 REAL-TIME SOS LISTENER — ONLY FOR ALERTS MEANT FOR THIS USER
  void _startSOSListener() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    supabase
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('contact_user_id', user.id)
        .order('created_at', ascending: false)
        .listen((rows) {
      if (rows.isEmpty) return;

      final latest = rows.first;
      final message = latest['message'] ?? "SOS Alert";
      final lat = latest['latitude'];
      final lon = latest['longitude'];

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 7),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🚨 SOS Alert!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(message, style: const TextStyle(color: Colors.white)),

              if (lat != null && lon != null)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SosLocationMapPage(
                          latitude: (lat as num).toDouble(),
                          longitude: (lon as num).toDouble(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "📍 View Location",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position =
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  Future<void> _handleWeatherTap(BuildContext context) async {
    try {
      final locationHelper = LocationHelper();
      final position = await locationHelper.getCurrentLocation();

      final weatherService = WeatherService();
      final weather =
      await weatherService.getWeather(position.latitude, position.longitude);

      if (!context.mounted) return;

      if (weather != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeatherPage(weather: weather),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch weather data.")),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  // ⭐ UPDATED — Contacts option added
  Widget _buildTopCircleButton(
      BuildContext context, String label, String imagePath) {
    return GestureDetector(
      onTap: () {
        if (label == 'Weather') {
          _handleWeatherTap(context);
        } else if (label == 'Map') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
        } else if (label == 'Alerts') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertPage()));
        } else if (label == 'SOS') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSPage()));
        } else if (label == 'Contacts') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EmergencyContactsPage()));
        }
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }

  Widget _buildBottomButton(IconData icon, String label, {bool isSOS = false}) {
    return GestureDetector(
      onTap: () {
        if (label == 'Fuel Stations') {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FuelStationPage()));
        } else if (label == 'Parking') {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ParkingPage()));
        } else if (label == 'History') {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HistoryPage()));
        } else if (label == 'SOS') {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SOSPage()));
        } else if (label == 'Re-Centre') {
          _getCurrentLocation();
        }
      },
      child: Container(
        width: 120,
        height: 45,
        decoration: BoxDecoration(
          color: isSOS ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSOS ? Colors.white : Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSOS ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search a place...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ UPDATED: Top buttons with Contacts added
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildTopCircleButton(
                      context, 'Weather', 'assets/images/weather.png'),
                  const SizedBox(width: 15),
                  _buildTopCircleButton(
                      context, 'Map', 'assets/images/map.png'),
                  const SizedBox(width: 15),
                  _buildTopCircleButton(
                      context, 'Alerts', 'assets/images/alert.jpg'),
                  const SizedBox(width: 15),
                  _buildTopCircleButton(
                      context, 'SOS', 'assets/images/sos.png'),
                  const SizedBox(width: 15),

                  // ⭐ NEW BUTTON
                  _buildTopCircleButton(
                      context, 'Contacts', 'assets/images/contacts.jpg'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // map
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _currentPosition == null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: {
                      Marker(
                        markerId:
                        const MarkerId('currentLocation'),
                        position: _currentPosition!,
                        infoWindow: const InfoWindow(
                          title: 'Your Location',
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // bottom buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              child: Wrap(
                spacing: 15,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildBottomButton(Icons.my_location, 'Re-Centre'),
                  _buildBottomButton(
                      Icons.local_gas_station, 'Fuel Stations'),
                  _buildBottomButton(Icons.local_parking, 'Parking'),
                  _buildBottomButton(
                      Icons.warning, 'SOS', isSOS: true),
                  _buildBottomButton(Icons.history, 'History'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
