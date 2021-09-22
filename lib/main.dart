import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp();
  runApp(MaterialApp(
    title: 'EcuaDom',
    debugShowCheckedModeBanner: false,
    home: MyHomePage(app: app),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.app}) : super(key: key);
  final FirebaseApp app;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class LocationFirestore{
  final LatLng position;
  LocationFirestore(this.position);
}

class _MyHomePageState extends State<MyHomePage> {
  late StreamSubscription<QuerySnapshot> _fsData;
  final firestoreInstance = FirebaseFirestore.instance;

  Location location = Location();

  late GoogleMapController mapController;
  Map<MarkerId, Marker> _markers = {};
  Set<Marker> get markers => _markers.values.toSet();

  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(0.0946797, -78.0524709),
    zoom: 10,
  );

  CameraPosition _position = _kInitialPosition;

  @override
  void initState() {
    super.initState();
    _fsData = firestoreInstance
        .collection('ubicacion')
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {

      querySnapshot.docs.forEach((doc) {
        _onMap(LatLng(doc["lat"],doc["lng"]));
      });
    });

    getLoc();

  }

  getLoc() async{
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }


  }


  @override
  void dispose() {
    super.dispose();

    if(_fsData != null){
      _fsData.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcuaDom'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kInitialPosition,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            //mapType: MapType.hybrid,
            onCameraMove: _updateCameraPosition,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            markers: markers,
            /*markers: _location.map(
                    (e) => Marker(
                        markerId: MarkerId('x'),
                    position: e.position)
            ).toSet(),*/
            //onTap: _onMap,
          ),
        ],
      ),

    );
  }


  void _onMap(LatLng position){

    final markerId = MarkerId(_markers.length.toString());
    final marker = Marker(markerId: markerId,
      position: position,
    //infoWindow: InfoWindow(title: 'Ubicacion obtenida de firebase'),
    );
    _markers[markerId] = marker;

    setState(() {});
  }


  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _updateCameraPosition(CameraPosition position) {
    setState(() {
      _position = position;
    });
  }
}
