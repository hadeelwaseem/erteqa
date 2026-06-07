import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sooq_merchant/features/commerce/checkout/data/commerce_store_origin.dart';

/// OSM map picker for checkout delivery coordinates (feature-layer widget).
class CheckoutLocationPickerPage extends StatefulWidget {
  const CheckoutLocationPickerPage({super.key, required this.initial});

  final LatLng initial;

  @override
  State<CheckoutLocationPickerPage> createState() =>
      _CheckoutLocationPickerPageState();
}

class _CheckoutLocationPickerPageState extends State<CheckoutLocationPickerPage> {
  late LatLng _selected;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _mapController = MapController();
  }

  void _updateSelection(LatLng point) {
    setState(() => _selected = point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حدد موقع التوصيل'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: const Text('تأكيد'),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selected,
          initialZoom: 14,
          onTap: (_, point) => _updateSelection(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.sooq.merchant',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selected,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 48,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mapController.move(
            const LatLng(
              CommerceStoreOrigin.latitude,
              CommerceStoreOrigin.longitude,
            ),
            14,
          );
        },
        label: const Text('دمشق'),
        icon: const Icon(Icons.my_location),
      ),
    );
  }
}
