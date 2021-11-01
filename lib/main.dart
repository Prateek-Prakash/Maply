import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get_it/get_it.dart';
import 'package:get_it_hooks/get_it_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;
void setupGetIt() {
  getIt.registerSingleton(AppShellVM());
  getIt.registerSingleton(MapNavVM());
  getIt.registerSingleton(MarkersNavVM());
  getIt.registerSingleton(ContactsNavVM());
  getIt.registerSingleton(SettingsNavVM());
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

Uuid UUID = Uuid();
GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

class Application extends StatelessWidget {
  const Application({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      title: 'Maply',
      home: const AppShellView(),
      theme: appTheme,
    );
  }
}

class AppShellView extends HookWidget {
  const AppShellView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: useWatchOnly((AppShellVM appShellVM) => appShellVM.navIndex),
        children: useGet<AppShellVM>().navViews,
      ),
    );
  }
}

class AppShellVM extends ChangeNotifier {
  // Navigation Index
  int _navIndex = 0;
  int get navIndex => _navIndex;
  set navIndex(int val) {
    _navIndex = val;
    notifyListeners();
  }

  // Navigation Views
  final List<Widget> _navViews = [
    MapNavView(),
    const MarkersNavView(),
    const ContactsNavView(),
    const SettingsNavView(),
  ];
  List<Widget> get navViews => _navViews;

  // Navigation Drawer Items
  final List<Widget> _navItems = [
    UserAccountsDrawerHeader(
      currentAccountPicture: const CircleAvatar(
        radius: 36.0,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 34.0,
          backgroundColor: Colors.black,
          child: Icon(
            Icons.person_rounded,
            color: Colors.white,
          ),
        ),
      ),
      accountName: const Text('Prateek Prakash'),
      accountEmail: Text(
        UUID.v4().toUpperCase(),
        style: const TextStyle(fontSize: 10.0),
      ),
    ),
    ListTile(
      leading: const Icon(Icons.map_rounded),
      title: const Text('Map'),
      onTap: () {
        useGet<AppShellVM>().navIndex = 0;
        Navigator.pop(navKey.currentContext!);
      },
    ),
    ListTile(
      leading: const Icon(Icons.location_on_rounded),
      title: const Text('Markers'),
      onTap: () {
        useGet<AppShellVM>().navIndex = 1;
        Navigator.pop(navKey.currentContext!);
      },
    ),
    ListTile(
      leading: const Icon(Icons.contacts_rounded),
      title: const Text('Contacts'),
      onTap: () {
        useGet<AppShellVM>().navIndex = 2;
        Navigator.pop(navKey.currentContext!);
      },
    ),
    ListTile(
      leading: const Icon(Icons.settings_rounded),
      title: const Text('Settings'),
      onTap: () {
        useGet<AppShellVM>().navIndex = 3;
        Navigator.pop(navKey.currentContext!);
      },
    ),
    const Divider(),
    ListTile(
      leading: const Icon(
        Icons.exit_to_app_rounded,
        color: Colors.red,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      onTap: () {
        Navigator.pop(navKey.currentContext!);
      },
    ),
  ];
  List<Widget> get navItems => _navItems;
}

class MapNavView extends HookWidget {
  MapNavView({Key? key}) : super(key: key);

  final Completer<GoogleMapController> _mapController = Completer();

  CameraPosition _cameraPosition = const CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 15.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: useGet<AppShellVM>().navItems,
        ),
      ),
      drawerEnableOpenDragGesture: false,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMap(),
          CustomFloatingSearchBar(
            hint: 'Search Places',
            actions: [
              FloatingSearchBarAction.icon(
                icon: Icons.my_location_rounded,
                onTap: () async {
                  Position currPosition = await _getCurrentLocation();
                  _cameraPosition = CameraPosition(
                    target: LatLng(currPosition.latitude, currPosition.longitude),
                    zoom: 15.0,
                  );
                  GoogleMapController mapController = await _mapController.future;
                  mapController.animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_location_alt_rounded),
        onPressed: () {
          useGet<MapNavVM>().addMapMarker(_cameraPosition.target);
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
    Set<Marker> mapMarkers = useWatchOnly((MapNavVM mapNavVM) => mapNavVM.mapMarkers.toSet());
    return FutureBuilder(
      future: _getCurrentLocation(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Position currPosition = snapshot.data as Position;
          _cameraPosition = CameraPosition(
            target: LatLng(currPosition.latitude, currPosition.longitude),
            zoom: 15.0,
          );
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _cameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            tiltGesturesEnabled: false,
            onCameraMove: (position) {
              _cameraPosition = position;
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
}

class MapNavVM extends ChangeNotifier {
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

class MarkersNavView extends HookWidget {
  const MarkersNavView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: useGet<AppShellVM>().navItems,
        ),
      ),
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Markers'),
      ),
      resizeToAvoidBottomInset: false,
      body: const Center(
        child: Text('MARKERS VIEW'),
      ),
    );
  }
}

class MarkersNavVM extends ChangeNotifier {}

class ContactsNavView extends HookWidget {
  const ContactsNavView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: useGet<AppShellVM>().navItems,
        ),
      ),
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Contacts'),
      ),
      resizeToAvoidBottomInset: false,
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: const CircleAvatar(
                child: Text('A'),
                backgroundColor: Colors.blueAccent,
              ),
              title: const Text('Anish Patel'),
              subtitle: Text(
                UUID.v4().toUpperCase(),
                style: const TextStyle(fontSize: 12.5),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Text('J'),
                backgroundColor: Colors.blueAccent,
              ),
              title: const Text('Jill Idicula'),
              subtitle: Text(
                UUID.v4().toUpperCase(),
                style: const TextStyle(fontSize: 12.5),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Text('K'),
                backgroundColor: Colors.blueAccent,
              ),
              title: const Text('Kamesh Patel'),
              subtitle: Text(
                UUID.v4().toUpperCase(),
                style: const TextStyle(fontSize: 12.5),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Text('K'),
                backgroundColor: Colors.blueAccent,
              ),
              title: const Text('Komal Patel'),
              subtitle: Text(
                UUID.v4().toUpperCase(),
                style: const TextStyle(fontSize: 12.5),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Text('Y'),
                backgroundColor: Colors.blueAccent,
              ),
              title: const Text('Yagnik Patel'),
              subtitle: Text(
                UUID.v4().toUpperCase(),
                style: const TextStyle(fontSize: 12.5),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Text('Y'),
                backgroundColor: Colors.blueAccent,
              ),
              title: const Text('Yeetesh Patel'),
              subtitle: Text(
                UUID.v4().toUpperCase(),
                style: const TextStyle(fontSize: 12.5),
              ),
              onTap: () {},
            )
          ],
        ).toList(),
      ),
    );
  }
}

class ContactsNavVM extends ChangeNotifier {}

class SettingsNavView extends HookWidget {
  const SettingsNavView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: useGet<AppShellVM>().navItems,
        ),
      ),
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Settings'),
      ),
      resizeToAvoidBottomInset: false,
      body: const Center(
        child: Text('SETTINGS VIEW'),
      ),
    );
  }
}

class SettingsNavVM extends ChangeNotifier {}

class CustomFloatingSearchBar extends StatelessWidget {
  const CustomFloatingSearchBar({
    Key? key,
    this.hint,
    this.actions,
    this.onQueryChanged,
  }) : super(key: key);

  final String? hint;
  final List<Widget>? actions;
  final Function(String)? onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      hint: hint ?? 'Search',
      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      scrollPadding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
      transitionDuration: const Duration(milliseconds: 500),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: 0.0,
      openAxisAlignment: 0.0,
      width: 500.0,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: onQueryChanged,
      transition: CircularFloatingSearchBarTransition(),
      actions: actions ?? [],
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
