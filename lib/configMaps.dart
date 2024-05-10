import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'Models/allUsers.dart';
import 'dart:convert';
// String mapKey = "AIzaSyCev2LI2DLPWPAqQkbPs0hSrJdL989c2Bc";
// String mapKey = "AIzaSyDWt1GqrbFbH1fnH40LRytjU9l4ekHHycE";
String mapKey = "AIzaSyC_n2DzkMvHK_wxXAGPm3Klk75LtyIwJ0I";

const String stripePublishableKey = 'YOUR_PUBLISHABLE_KEY';
const String stripeSecretKey = 'YOUR_SECRET_KEY';

String serverToken = "key=AAAAGrkP1-w:APA91bG8uQKibkTjEETsleHKlNgxhYi_t-ayXmoDkSgEQdkNiYwqxJcNyOxG9lhwEI9kt5IvqcbkR4fTiETj2dWlfYa-8xaA_5qCvwsVo42puabWchkL6sztf1I2m2szlf_9lyThhxTe";

User? firebaseUser;

Users? userCurrentInfo;
String statusRide = "null";
String car_details = "";
String rideStatus = "Driver is Coming";
String driverName = "";
String driverPhone = "";
String carRideType = "";
double starCounter = 0.0;
String title = "";
String driverToken = "";
String riderToken = "";



final kApiUrl = defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:4242'
    : 'http://localhost:4242';

int driverRequestTimeout = 40;

extension PrettyJson on Map<String, dynamic> {
  String toPrettyString() {
    var encoder = new JsonEncoder.withIndent("     ");
    return encoder.convert(this);
  }
}