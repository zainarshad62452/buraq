import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:buraq/AllScreens/ratingScreen.dart';
import 'package:buraq/AllScreens/registerationScreen.dart';
import 'package:buraq/AllScreens/searchScreen.dart';
import 'package:buraq/AllWidgets/Divider.dart';
import 'package:buraq/AllWidgets/collectFareDialog.dart';
import 'package:buraq/AllWidgets/noDriverAvailableDialog.dart';
import 'package:buraq/AllWidgets/progressDialod.dart';
import 'package:buraq/Assistants/assistantMethod.dart';
import 'package:buraq/DataHandler/appData.dart';
import 'package:buraq/Models/directionDetails.dart';
import 'package:buraq/Models/nearbyAvailableDrivers.dart';
import 'package:buraq/configMaps.dart';
import 'package:buraq/main.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Assistants/geofireAssistant.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainscreen";

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  late GoogleMapController newGoogleMapController;
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};
  late String _selectedOption;
  List<String> _options = ['Cash', 'Card'];

  Map<String, IconData> _optionIcons = {
    'Cash': Icons.attach_money,
    'Card': Icons.credit_card,
  };

  static const colorizeColors = [
    Colors.green,
    Colors.purple,
    Colors.pink,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 55.0,
    fontFamily: 'Signatra',
  );

  DirectionDetails? tripDirectionDetails;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};
  bool nearbyAvailableDriverKeysLoaded = false;

  String state = 'normal';
  String uName = "";
  double rideDetailsContainer = 0;
  bool drawerOpen = true;

  late Position currentPosition;
  var geolocator = Geolocator();
  double searchContainerHeight = 300.0;
  double rideDetailsContainerHeight = 0.0;
  double requestRideContainerHeight = 0;
  double bottomPaddingOfMap = 0;
  double driverDetailsContainerHeight = 0;

  String paymentMethod = "Cash";

  DatabaseReference? rideRequestRef;

  BitmapDescriptor? nearbyIcon;
  List<NearbyAvailableDrivers>? availableDrivers;

  StreamSubscription<DatabaseEvent>? rideStreamSubscription;

  bool isRequestingPositionDetails = false;

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 600.0;
      bottomPaddingOfMap = 600.0;
      drawerOpen = false;
    });
  }

  @override
  void initState() {
    super.initState();
    AssistantMethods.getOnlineUserInfo();
    _selectedOption = _options[0];
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.ref().child("Ride Requests").push();

    var pickup = Provider.of<AppData>(context, listen: false).pickupLocation;
    var dropoff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickup.latitude.toString(),
      "longitude": pickup.longititue.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropoff.latitude.toString(),
      "longitude": dropoff.longititue.toString(),
    };

    Map rideinfoMap = {
      "driver_id": "waiting",
      "payment_method": _selectedOption,
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo?.name,
      "rider_phone": userCurrentInfo?.phone,
      "pickup_address": pickup.placeName,
      "dropoff_address": dropoff.placeName,
      "ride_type": carRideType,
    };
    rideRequestRef?.set(rideinfoMap);

    rideStreamSubscription = rideRequestRef?.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }
      var data = event.snapshot.value! as Map;

      if (data['car_details'] != null) {
        setState(() {
          car_details = data['car_details'].toString();
        });
      }
      if (data['captain_name'] != null) {
        setState(() {
          driverName = data['captain_name'].toString();
        });
      }
      if (data['captain_phone'] != null) {
        setState(() {
          driverPhone = data['captain_phone'].toString();
        });
      }

      if (data['driver_location'] != null) {
        double driverLat =
            double.parse(data['driver_location']['latitude'].toString());
        double driverLong =
            double.parse(data['driver_location']['longitude'].toString());

        LatLng driverCurrentLocation = LatLng(driverLat, driverLong);

        if (data['status'] != null) {
          statusRide = data['status'].toString();
        }

        if (statusRide == 'accepted') {
          displayDriverDetailsContainer();
          Geofire.stopListener();
          deleteGeoFireMarkers();
        }

        if (statusRide == "accepted") {
          updateRideTimeToPickLoc(driverCurrentLocation);
        }

        if (statusRide == "arrived") {
          setState(() {
            rideStatus = "Driver has Arrived";
          });
        }
        if (statusRide == "onride") {
          updateRideTimeToDropLoc(driverCurrentLocation);
        }

        if (statusRide == "Ended") {
          if (data['fares'] != null) {
            int fare = int.parse(data['fares'].toString());

            var res = await showDialog(
                context: context,
                builder: (ctx) {
                  return CollectFareDailog(
                      paymentMethod: data['payment_method'], fareAmount: fare);
                });
            String driverId = "";
            if (res == "close") {
              if (data['driver_id'] != null) {
                driverId = data['driver_id'].toString();
              }

              Get.to(() => RatingScreen(
                    driverId: driverId,
                  ));
              rideRequestRef?.onDisconnect();
              rideRequestRef = null;
              rideStreamSubscription = null;
              resetApp();
            }
          }
        }
      }
    });
  }

  void deleteGeoFireMarkers() {
    setState(() {
      markersSet
          .removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;
      var positionUserLatlng =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(
          driverCurrentLocation, positionUserLatlng);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Driver is Coming - ${details.durationText!}";
      });
      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;
      var dropOff =
          Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffLatln = LatLng(dropOff.latitude, dropOff.longititue);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(
          driverCurrentLocation, dropOffLatln);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Going To Destination - ${details.durationText!}";
      });
      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    rideRequestRef?.remove();
    setState(() {
      state = 'normal';
    });
  }

  void displayRequestContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  void displayDriverDetailsContainer() {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 290.0;
      driverDetailsContainerHeight = 320.0;
    });
  }

  void resetApp() {
    setState(() {
      searchContainerHeight = 300;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 300.0;
      drawerOpen = true;
      polylineSet.clear();
      requestRideContainerHeight = 0.0;
      driverDetailsContainerHeight = 0.0;
      statusRide = "null";
      driverName = "";
      driverName = "";
      car_details = "";
      rideStatus = "Driver is Coming";
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }

  void locatePosition() async {
    await Geolocator.requestPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        currentPosition = position;
        LatLng latLngPosition = LatLng(position.latitude, position.longitude);
        CameraPosition cameraPosition =
            new CameraPosition(target: latLngPosition, zoom: 14);
        newGoogleMapController
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        String address =
            await AssistantMethods.searchCoordinateAddress(position, context);

        initGeoFireListner();
        uName = userCurrentInfo!.name!;
      } on Exception catch (e) {
        print(e);
      }
    } else {
      await Geolocator.requestPermission();
      displayToastMessage('Location Permission is denied', context);
    }
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  String home() {
    try {
      if (Provider.of<AppData>(context).pickupLocation != null) {
        return Provider.of<AppData>(context).pickupLocation.placeName;
      } else {
        return "Add Home";
      }
    } catch (exp) {
      return "Home";
    }
  }

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.black87,
        onPressed: () {
          locatePosition();
        },
        child: Icon(
          Icons.my_location,
          color: Colors.white,
        ),
      ),
      key: scaffoldKey,
      drawer: Drawer(
        child: ListView(
          children: [
            //Drawer Header
            Container(
              // height: 185.0,
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'images/user_icon.png',
                          height: 65.0,
                          width: 65.0,
                        ),
                        SizedBox(
                          width: 16.0,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              uName,
                              style: TextStyle(
                                  fontSize: 16.0, fontFamily: 'Brand-Bold'),
                            ),
                            SizedBox(
                              height: 6.0,
                            ),
                            Text('Visit Profile'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const DividerWidget(),
            const SizedBox(
              height: 12.0,
            ),
            //Drawer Body Controller
            const ListTile(
              leading: Icon(Icons.history),
              title: Text(
                'History',
                style: TextStyle(fontSize: 15.0),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text(
                'Visit Profile',
                style: TextStyle(fontSize: 15.0),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.info),
              title: Text(
                'About',
                style: TextStyle(fontSize: 15.0),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 300.0;
              });

              locatePosition();
            },
          ),
          //Hamburger Button for Drawer
          Positioned(
              top: 38.0,
              left: 22.0,
              child: GestureDetector(
                onTap: () {
                  if (drawerOpen) {
                    scaffoldKey.currentState?.openDrawer();
                  } else {
                    resetApp();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22.0),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 6.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7))
                      ]),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      (drawerOpen) ? Icons.menu : Icons.close,
                      color: Colors.black,
                    ),
                    radius: 20.0,
                  ),
                ),
              )),
          //Search Ui
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              // key: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 6.0,
                      ),
                      const Text(
                        "Hi There, ",
                        style: TextStyle(fontSize: 12.0),
                      ),
                      const Text(
                        "Where to? ",
                        style:
                            TextStyle(fontSize: 20.0, fontFamily: 'Brand-Bold'),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));
                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text('Search Drop off'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 34.0,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.home,
                            color: Colors.grey,
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                home();
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  home(),
                                ),
                                const SizedBox(
                                  height: 4.0,
                                ),
                                const Text(
                                  'Your living home address',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      const DividerWidget(),
                      const SizedBox(
                        height: 16.0,
                      ),
                      const Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Work'),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                'Your office address',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //Ride Details UI
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              // vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 16.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      //bike ride
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            state = 'requesting';
                          });
                          carRideType = "Bike";
                          displayRequestContainer();
                          availableDrivers =
                              GeofireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver("Bike");
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/bike.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Bike",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand-Bold"),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null
                                          ? '${tripDirectionDetails?.distanceText}'
                                          : '')),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  (tripDirectionDetails != null
                                      ? 'PKR-${(AssistantMethods.calculateFares(tripDirectionDetails!)) / 2}'
                                      : ''),
                                  style: TextStyle(fontFamily: "Brand-Bold"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      //Buraq Super
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            state = 'requesting';
                          });
                          carRideType = "Buraq-Super";
                          displayRequestContainer();
                          availableDrivers =
                              GeofireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver("Buraq-Super");
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/buraqSuper.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Buraq Super",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand-Bold"),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null
                                          ? '${tripDirectionDetails?.distanceText}'
                                          : '')),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  (tripDirectionDetails != null
                                      ? 'PKR-${AssistantMethods.calculateFares(tripDirectionDetails!)}'
                                      : ''),
                                  style: TextStyle(fontFamily: "Brand-Bold"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      //Buraq Ultra
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            state = 'requesting';
                          });
                          carRideType = "Buraq-Ultra";
                          displayRequestContainer();
                          availableDrivers =
                              GeofireAssistant.nearbyAvailableDriversList;
                          searchNearestDriver("Buraq-Ultra");
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "images/buraqUltra.png",
                                  height: 70.0,
                                  width: 80.0,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Buraq Ultra",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand-Bold"),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null
                                          ? '${tripDirectionDetails?.distanceText}'
                                          : '')),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  (tripDirectionDetails != null
                                      ? 'PKR-${(AssistantMethods.calculateFares(tripDirectionDetails!) * 2)}'
                                      : ''),
                                  style: TextStyle(fontFamily: "Brand-Bold"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: DropdownButtonFormField(
                          value: _selectedOption,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon: Icon(_optionIcons[_selectedOption]),
                          ),
                          items: _options.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Row(
                                children: [
                                  Icon(_optionIcons[option]),
                                  SizedBox(width: 10),
                                  Text(option),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //Request or Cancel UI
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16.0,
                      color: Colors.black54,
                      offset: Offset(0.7, 0.7),
                    ),
                  ]),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 12.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting a Ride',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                            speed: Duration(milliseconds: 20),
                          ),
                          ColorizeAnimatedText(
                            'Please wait....',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                            speed: Duration(milliseconds: 20),
                          ),
                          ColorizeAnimatedText(
                            'Finding a Driver....',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                            speed: Duration(milliseconds: 20),
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {},
                      ),
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0, color: Colors.grey),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel Ride",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          //Display Assigned Driver Info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              height: driverDetailsContainerHeight,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16.0,
                      color: Colors.black54,
                      offset: Offset(0.7, 0.7),
                    ),
                  ]),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 6.0,
                    ),
                    Row(
                      children: [
                        Text(
                          rideStatus,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20.0, fontFamily: "Brand-Bold"),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Divider(
                      height: 2.0,
                      thickness: 2.0,
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Text(
                      car_details,
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      driverName,
                      style: TextStyle(fontSize: 20.0),
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Divider(
                      height: 2.0,
                      thickness: 2.0,
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //call button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.0),
                          child: MaterialButton(
                            onPressed: () {
                              launchUrl(Uri.parse('tel:${driverPhone}'));
                            },
                            color: Colors.pink,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: const [
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 26.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        MaterialButton(
                          onPressed: () {
                            launchUrl(Uri.parse('sms:${driverPhone}'));
                          },
                          color: Colors.pink,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: const [
                                Text(
                                  'Message',
                                  style: TextStyle(
                                      fontSize: 20.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Icon(
                                  Icons.sms,
                                  color: Colors.white,
                                  size: 26.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickupLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;
    var pickUpLatlan = LatLng(initialPos.latitude, initialPos.longititue);
    var dropoffLatlan = LatLng(finalPos.latitude, finalPos.longititue);
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialod(message: "Please wait...."));

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatlan, dropoffLatlan);

    setState(() {
      tripDirectionDetails = details!;
    });

    Navigator.pop(context);
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsResult =
        polylinePoints.decodePolyline("${details?.encodedPoints}");
    pLineCoordinates.clear();
    if (!decodedPolylinePointsResult.isEmpty) {
      decodedPolylinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
          polylineId: PolylineId("PolylineID"),
          color: Colors.pink,
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polylineSet.add(polyline);
    });
    LatLngBounds latLngBounds;
    if (pickUpLatlan.latitude > dropoffLatlan.latitude &&
        pickUpLatlan.longitude > dropoffLatlan.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropoffLatlan, northeast: pickUpLatlan);
    } else if (pickUpLatlan.latitude > dropoffLatlan.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropoffLatlan.latitude, pickUpLatlan.longitude),
          northeast: LatLng(pickUpLatlan.latitude, dropoffLatlan.longitude));
    } else if (pickUpLatlan.longitude > dropoffLatlan.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatlan.latitude, dropoffLatlan.longitude),
          northeast: LatLng(dropoffLatlan.latitude, pickUpLatlan.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatlan, northeast: dropoffLatlan);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));
    Marker pickUpLocationMarker = Marker(
      markerId: MarkerId("Pick Up Marker"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: "my Location"),
      position: pickUpLatlan,
    );
    Marker dropOffLocationMarker = Marker(
      markerId: MarkerId("DropOff Marker"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: finalPos.placeName, snippet: "DropOff Location"),
      position: dropoffLatlan,
    );
    setState(() {
      markersSet.add(pickUpLocationMarker);
      markersSet.add(dropOffLocationMarker);
    });

    Circle pickUpCircle = Circle(
        circleId: CircleId("PickUpID"),
        fillColor: Colors.blueAccent,
        center: pickUpLatlan,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent);
    Circle dropOffCircle = Circle(
        circleId: CircleId("DropOffID"),
        fillColor: Colors.deepPurple,
        center: dropoffLatlan,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple);

    setState(() {
      circlesSet.add(pickUpCircle);
      circlesSet.add(dropOffCircle);
    });
    // searchNearestDriver();
  }

  void initGeoFireListner() {
    Geofire.initialize("availableDrivers");
    //comment
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)
        ?.listen((map) {
      if (map != null) {
        var callback = map['callBack'];

        switch (callback) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeofireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeofireAssistant.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();

            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeofireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {
      });
    });
    //cpmment
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();

    for (NearbyAvailableDrivers driver
        in GeofireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailabePosition =
          LatLng(driver.latitude!, driver.longitude!);

      Marker marker = Marker(
        markerId: MarkerId("driver${driver.key}"),
        position: driverAvailabePosition,
        icon: nearbyIcon!,
        rotation: AssistantMethods.createRandomNumber(360),
      );
      tMarkers.add(marker);
    }
    setState(() {
      markersSet = tMarkers;
    });
  }

  void createIconMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2.0, 2.0));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_ios.png")
          .then((value) {
        nearbyIcon = value;
      });
    }
  }

  void noDriverFound() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return NoAvailableDriverDialog();
        });
  }

  void searchNearestDriver(String carType) async {
    if (availableDrivers!.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }
    //
    // List<NearbyAvailableDrivers>? updatedDrivers = [];
    // for (var driver in availableDrivers!){
    //   driversRef
    //       .child(driver!.key!)
    //       .child("car_details")
    //       .child("type")
    //       .once()
    //       .then((value) async {
    //     if (await value.snapshot.value != null) {
    //       var newDriver = driver;
    //       String carType = value.snapshot.value.toString();
    //       if (carType == "Bike") {
    //         newDriver.carType = carType;
    //
    //       }else if(carType == "Buraq-Super"){
    //         newDriver.carType = carType;
    //       }else if(carType == "Buraq-Ultra"){
    //         newDriver.carType = carType;
    //       }
    //       var details = await AssistantMethods.obtainPlaceDirectionDetails(LatLng(newDriver.latitude!, newDriver.latitude!), LatLng(currentPosition.latitude, currentPosition.longitude));
    //       newDriver.distanceText = details?.durationText!;
    //       updatedDrivers.add(newDriver);
    //     }
    //
    //   });
    // }
    // setState(() {
    //   GeofireAssistant.nearbyAvailableDriversList = updatedDrivers;
    // });
    // var driver = availableDrivers![0];
    for (var driver in availableDrivers!){
      // var details = await AssistantMethods.obtainPlaceDirectionDetails(LatLng(driver.latitude!, driver.latitude!), LatLng(currentPosition.latitude, currentPosition.longitude));
      driversRef
          .child(driver.key!)
          .child("car_details")
          .child("type")
          .once()
          .then((value) async {
        if (await value.snapshot.value != null) {
          String carType = value.snapshot.value.toString();
          // print(details!.distanceValue);
          if (carType == carRideType) {
            notifyDriver(driver);
            availableDrivers!.removeWhere((element) => element.key == driver.key!);
            return;
          }
        } else {
          displayToastMessage("No car found. Try again.", context);
        }
      });

    }

  }

  void notifyDriver(NearbyAvailableDrivers driver) {
    driversRef.child(driver.key!).child('newRide').set(rideRequestRef!.key);
    driversRef.child(driver.key!).child('token').once().then((value) {
      if (value.snapshot.value != null) {
        String token = value.snapshot.value.toString();
        driverToken = token;
        AssistantMethods.sendNotificationToDriver(
            token, context, rideRequestRef!.key!);
      } else {
        return;
      }

      const oneSecondPasses = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPasses, (timer) {
        if (state != 'requesting') {
          driversRef.child(driver.key!).child('newRide').set('cancelled');
          driversRef.child(driver.key!).child('newRide').onDisconnect();
          driverRequestTimeout = 40;
          timer.cancel();
        }

        driverRequestTimeout = driverRequestTimeout - 1;

        driversRef.child(driver.key!).child('newRide').onValue.listen((event) {
          if (event.snapshot.value.toString() == "accepted") {
            driversRef.child(driver.key!).child('newRide').onDisconnect();
            driverRequestTimeout = 40;
            timer.cancel();
          }
        });

        if (driverRequestTimeout == 0) {
          driversRef.child(driver.key!).child('newRide').set('timeout');
          driversRef.child(driver.key!).child('newRide').onDisconnect();
          driverRequestTimeout = 40;
          timer.cancel();

          // searchNearestDriver();
        }
      });
    });
  }
}
