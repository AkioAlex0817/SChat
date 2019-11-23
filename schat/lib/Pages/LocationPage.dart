import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPage extends StatefulWidget{


  @override
  LocationPageState createState() => LocationPageState();
}

class LocationPageState extends State<LocationPage>{

  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _position = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GoogleMap(
          mapType: MapType.hybrid,
          initialCameraPosition: _position,
          onMapCreated: (GoogleMapController controller){
            _controller.complete(controller);
            _goToTarget();
          },
        ),
      ),
    );
  }

  Future<void> _goToTarget() async{
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_position));
  }
}