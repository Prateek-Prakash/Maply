import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';
import 'package:get_it_hooks/get_it_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final getIt = GetIt.instance;
void setupGetIt() {
  getIt.registerSingleton(AppShellVM());
  getIt.registerSingleton(HomeTabVM());
  getIt.registerSingleton(SettingsTabVM());
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
        children: useGet<AppShellVM>().navTabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black38, spreadRadius: 0.0, blurRadius: 10.0),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: useWatchOnly((AppShellVM appShellVM) => appShellVM.navIndex),
            onTap: (index) {
              useGet<AppShellVM>().navIndex = index;
            },
            items: useGet<AppShellVM>().navItems,
          ),
        ),
      ),
    );
  }
}

class AppShellVM extends ChangeNotifier {
  // Tab Views
  final List<Widget> _navTabs = [
    HomeTabView(),
    const SettingsTabView(),
  ];
  List<Widget> get navTabs => _navTabs;

  // Navigation Items
  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      label: 'Assets',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      label: 'Settings',
    )
  ];
  List<BottomNavigationBarItem> get navItems => _navItems;

  // Navigation Index
  int _navIndex = 0;
  int get navIndex => _navIndex;
  set navIndex(int val) {
    _navIndex = val;
    notifyListeners();
  }
}

class HomeTabView extends HookWidget {
  HomeTabView({Key? key}) : super(key: key);

  final Completer<GoogleMapController> _mapController = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maply'),
        centerTitle: true,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        },
        zoomControlsEnabled: false,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

class SettingsTabVM extends ChangeNotifier {}

class SettingsTabView extends HookWidget {
  const SettingsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maply'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Settings'),
      ),
    );
  }
}

class HomeTabVM extends ChangeNotifier {}
