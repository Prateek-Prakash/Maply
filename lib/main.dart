import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get_it/get_it.dart';
import 'package:get_it_hooks/get_it_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

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

  CameraPosition _camPosition = const CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 15.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.map_rounded),
              title: const Text('Map'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.location_on_rounded),
              title: const Text('Markers'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.contacts_rounded),
              title: const Text('Contacts'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () {},
            ),
          ],
        ),
      ),
      drawerEnableOpenDragGesture: false,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(),
          _buildFloatingSearchBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_location_alt_rounded),
        onPressed: () {
          useGet<AppShellVM>().addMapMarker(_camPosition.target);
        },
      ),
    );
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  Widget _buildMap() {
    Set<Marker> mapMarkers = useWatchOnly((AppShellVM appShellVM) => appShellVM.mapMarkers.toSet());
    return FutureBuilder(
      future: _getCurrentLocation(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Position currPosition = snapshot.data as Position;
          _camPosition = CameraPosition(
            target: LatLng(currPosition.latitude, currPosition.longitude),
            zoom: 15.0,
          );
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _camPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            tiltGesturesEnabled: false,
            onCameraMove: (position) {
              _camPosition = position;
            },
            markers: mapMarkers,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildFloatingSearchBar() {
    return FloatingSearchBar(
      hint: 'Search',
      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      scrollPadding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
      transitionDuration: const Duration(milliseconds: 500),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: 0.0,
      openAxisAlignment: 0.0,
      width: 500.0,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) {},
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction.searchToClear(),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: Colors.accents.map((color) {
                return Container(height: 75.0, color: color);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class AppShellVM extends ChangeNotifier {
  List<Marker> _mapMarkers = [];
  List<Marker> get mapMarkers => _mapMarkers;

  void addMapMarker(LatLng target) {
    Marker marker = Marker(
      markerId: MarkerId(target.toString()),
      position: target,
      icon: BitmapDescriptor.defaultMarker,
    );
    _mapMarkers.add(marker);
    notifyListeners();
  }
}
