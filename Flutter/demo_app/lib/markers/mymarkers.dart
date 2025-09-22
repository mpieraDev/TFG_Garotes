import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui';

import 'package:widget_to_marker/widget_to_marker.dart';

// El zoom va  de 3 a 28;

class BlobMarker extends StatelessWidget {
  static const double _maxDepth = 14;
  static const double _minDepth = 0;
  static const Color _endColor = Color(0xffFF9F21);
  static const Color _startColor = Color(0xffFFFFFF);
  

  final Color markerColor;
  final String depth;

  const BlobMarker({super.key, required this.markerColor, required this.depth});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          //child: Text(depth, maxLines: 1, selectionColor: Colors.black),
        ),
      ],
    );
  }

  static Color colorBasedOnDepth (double depth) {
    return _colorInterpolation(_startColor, _endColor, _factorFromDepthAndColor(depth));
  }

  static Color _colorInterpolation (Color startColor, Color endColor, double factor) {
    factor = factor.clamp(0.0, 1.0);

    print('START COLOR R: ${startColor.red}');
    print('START COLOR R: ${startColor.green}');
    print('START COLOR R: ${startColor.blue}');
    print('END COLOR R: ${endColor.red}');
    print('END COLOR R: ${endColor.green}');
    print('END COLOR R: ${endColor.blue}');

    int r = ((endColor.red - startColor.red) * factor + startColor.red).toInt();
    int g = ((endColor.green - startColor.green) * factor + startColor.green).toInt();
    int b = ((endColor.blue - startColor.blue) * factor + startColor.blue).toInt();
    //int a = ((endColor.a - startColor.a) * factor + startColor.a).toInt();
    print('BLOB COLOR: ${Color.fromARGB(255, r, g, b)}');
    return Color.fromARGB(255, r, g, b);
  }

  static double _factorFromDepthAndColor(double depth) {
    print('NEW DEPTH Factor: ${((depth - _minDepth) / (_maxDepth - _minDepth))}');
    return ((depth - _minDepth) / (_maxDepth - _minDepth));
  }
}

class MyCustomMarkerProperties {
  MyCustomMarkerProperties({required this.markerProperties, required this.look});

  final Marker markerProperties;
  final BlobMarker look;
}

class MyCustomMarkers {
  List<MyCustomMarkerProperties> _myMarkers = [];
  Set<Marker> _depthMarkers = {};
  late Marker _positionMarker;
  late Marker _userPositionMarker;
  Set<Marker> _markersBuffer = {};
  final double size;

  MyCustomMarkers({required this.size});

  Future<void> updateMarkersOnZoom(double zoom, int visibilityLimit) async {
    _markersBuffer.clear();
    _markersBuffer.add(_positionMarker);
    _markersBuffer.add(_userPositionMarker);
    //if (zoom > visibilityLimit) {
      for (MyCustomMarkerProperties marker in _myMarkers) {
        _markersBuffer.add(
          Marker(
            markerId: marker.markerProperties.markerId,
            position: marker.markerProperties.position,
            icon: await marker.look.toBitmapDescriptor(
              logicalSize: Size(size * zoom, size * zoom),
              imageSize: Size(size * zoom, size * zoom),
            ),
          ),
        );
      }
    //}
  }

  Future<void> updateMarkersOnZoomSteps(double zoom) async {
    /*if (zoom != prevZoom) {
      if (zoom > x) {

      }
    }*/


    _markersBuffer.clear();
    for (MyCustomMarkerProperties marker in _myMarkers) {
      _markersBuffer.add(
        Marker(
          markerId: marker.markerProperties.markerId,
          position: marker.markerProperties.position,
          icon: await marker.look.toBitmapDescriptor(
            logicalSize: Size(size * zoom, size * zoom),
            imageSize: Size(size * zoom, size * zoom),
          ),
        ),
      );
    }
  }

  /*Future<void> addMarker({required double depth, required LatLng position, required double zoom, required String id}) async {
    try {
      // print('DEPTH: ${depth.toString()}');
      // print('MYBLOB!');
      BlobMarker newlook = createBlobMarker(depth);
      // print('MYBLOB: $newlook');
      Marker newMarker = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: await newlook.toBitmapDescriptor(
          logicalSize: Size(size * zoom, size * zoom),
          imageSize: Size(size * zoom, size * zoom),
        ),
      );
      // print('MYNEWMARKER: $newMarker');
      _myMarkers.add(MyCustomMarkerProperties(
        markerProperties: newMarker, 
        look: newlook,
      ));
      _markersBuffer.add(newMarker);
    } catch (err) {
      print('catched error adding marker: $err');
    }
  }*/

  Future<void> addMarker({required double depth, required LatLng position, required double zoom, required String id}) async {
    try {
      // print('DEPTH: ${depth.toString()}');
      // print('MYBLOB!');
      BlobMarker newlook = createBlobMarker(depth);
      // print('MYBLOB: $newlook');
      Marker newMarker = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: await newlook.toBitmapDescriptor(
          logicalSize: Size(size * zoom, size * zoom),
          imageSize: Size(size * zoom, size * zoom),
        ),
      );
      // print('MYNEWMARKER: $newMarker');
      _depthMarkers.add(newMarker);
    } catch (err) {
      print('catched error adding marker: $err');
    }
  }

  Future<void> addPositionMarker({required Marker positionMarker}) async {
    try {
      _positionMarker = positionMarker;
      _markersBuffer.add(_positionMarker);
    } catch (err) {
      print('catched error adding position marker: $err');
    }
  }

  /*Future<void> updateDronePositionMarker({required double latitude, required double longitude}) async {
    _markersBuffer.clear();
    _positionMarker = Marker(
      markerId: const MarkerId('USV'),
      position: LatLng(latitude, longitude),
      icon: await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(24, 24)), 
        'assets/icons/USV_POSITION.png'
      ),
    );
    _markersBuffer.add(_positionMarker);
    for (MyCustomMarkerProperties marker in _myMarkers) {
      _markersBuffer.add(
         Marker(
          markerId: marker.markerProperties.markerId,
          position: marker.markerProperties.position,
          icon: await marker.look.toBitmapDescriptor(
            logicalSize: Size(size, size),
            imageSize: Size(size, size),
          ),
        ),
      );
    }
  }*/

    Future<void> updateDronePositionMarker({required double latitude, required double longitude, required double rotation}) async {
    _markersBuffer.clear();
    _positionMarker = Marker(
      markerId: const MarkerId('USV'),
      position: LatLng(latitude, longitude),
      rotation: rotation,
      zIndex: 1,
      icon: await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(24, 24)), 
        'assets/icons/USV_POSITION.png'
      ),
    );
    _markersBuffer.add(_positionMarker);
  }

  BlobMarker createBlobMarker(double depth) {
    // print('DEPTH2: ${depth.toString()}');
    return BlobMarker(
      markerColor: BlobMarker.colorBasedOnDepth(depth), 
      depth: depth.toString()
    );
  }

  Set<Marker> getMarkers() {
    print("MyMarkersBuffer: $_markersBuffer");
    return _depthMarkers.union(_markersBuffer);
  }
}
