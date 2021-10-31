import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get_it/get_it.dart';
import 'package:get_it_hooks/get_it_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final getIt = GetIt.instance;
void setupGetIt() {
  getIt.registerSingleton(AppShellVM());
}

final appTheme = ThemeData(
  fontFamily: 'Comfortaa',
  visualDensity: VisualDensity.adaptivePlatformDensity,
  brightness: Brightness.light,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  setupGetIt();
  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maply',
      home: AppShellView(),
      theme: appTheme,
    );
  }
}

class AppShellView extends HookWidget {
  AppShellView({Key? key}) : super(key: key);

  final Completer<GoogleMapController> _mapController = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maply'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _getCurrentLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Position currPosition = snapshot.data as Position;
            CameraPosition camPosition = CameraPosition(
              target: LatLng(currPosition.latitude, currPosition.longitude),
              zoom: 15.0,
            );
            return GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: camPosition,
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              tiltGesturesEnabled: false,
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }
}

class AppShellVM extends ChangeNotifier {}
