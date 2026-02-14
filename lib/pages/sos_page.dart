import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class SOSPage extends StatelessWidget {
  const SOSPage({super.key});

  SupabaseClient get _supabase => Supabase.instance.client;

  // 🚨 MAIN SOS FUNCTION
  Future<void> _sendSOS(BuildContext context) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to send SOS"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 1️⃣ Get user's emergency contacts
      final contacts = await _supabase
          .from("user_contacts")
          .select("contact_user_id")
          .eq("user_id", user.id);

      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No emergency contacts added!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2️⃣ Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final double lat = position.latitude;
      final double lon = position.longitude;

      // 3️⃣ Insert SOS for each contact (with location)
      for (var contact in contacts) {
        await _supabase
            .from('sos_alerts')
            .insert({
          'user_id': user.id,
          'contact_user_id': contact["contact_user_id"],
          'message':
          "🚨 Emergency! I need help! Please check my location.",
          'latitude': lat,
          'longitude': lon,
        });
      }

      // 4️⃣ Send push notification via OneSignal REST API
      await _sendPushNotificationToContacts(user.id, lat, lon);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("SOS sent with your location!"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send SOS: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔔 Send push notifications using OneSignal REST API
  Future<void> _sendPushNotificationToContacts(
      String userId, double lat, double lon) async {
    const String oneSignalAppId = "YOUR_ONESIGNAL_APP_ID_HERE";
    const String oneSignalRestApiKey = "YOUR_ONESIGNAL_REST_API_KEY_HERE";

    // 1️⃣ Get all contact_user_ids
    final contacts = await _supabase
        .from("user_contacts")
        .select("contact_user_id")
        .eq("user_id", userId);

    if (contacts.isEmpty) return;

    // 2️⃣ Get player_ids from user_push_tokens
    final List<String> playerIds = [];

    for (var c in contacts) {
      final tokenRow = await _supabase
          .from("user_push_tokens")
          .select("player_id")
          .eq("user_id", c["contact_user_id"])
          .maybeSingle();

      if (tokenRow != null && tokenRow["player_id"] != null) {
        playerIds.add(tokenRow["player_id"] as String);
      }
    }

    if (playerIds.isEmpty) return;

    // 3️⃣ Call OneSignal REST API
    final url = Uri.parse("https://api.onesignal.com/notifications");

    final body = jsonEncode({
      "app_id": oneSignalAppId,
      "include_player_ids": playerIds,
      "headings": {"en": "Emergency SOS"},
      "contents": {
        "en":
        "Someone sent an SOS. Tap to open the app and check their location."
      },
      "data": {
        "type": "sos",
        "latitude": lat,
        "longitude": lon,
      }
    });

    await http.post(
      url,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Authorization": "Basic $oneSignalRestApiKey",
      },
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text(
          "Emergency SOS",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Press the SOS button to send alert\nwith your current location",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => _sendSOS(context),
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "This will immediately notify your emergency contacts about your situation with your current GPS location.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
