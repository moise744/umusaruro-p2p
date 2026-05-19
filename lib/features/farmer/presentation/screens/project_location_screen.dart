import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';

class ProjectLocationScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String title;

  const ProjectLocationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final location = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text('Location: \$title'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: location,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.umusaruro.mobile',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
