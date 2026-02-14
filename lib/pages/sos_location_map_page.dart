import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SosLocationMapPage extends StatelessWidget {
  final double latitude;
  final double longitude;

  const SosLocationMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng target = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Location"),
        backgroundColor: Colors.red,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: target,
          zoom: 16,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("sos_location"),
            position: target,
            infoWindow: const InfoWindow(title: "SOS Sender"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
