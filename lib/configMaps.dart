import 'package:firebase_auth/firebase_auth.dart';

import 'Models/allUsers.dart';

String mapKey = "Enter your google api key";


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

int driverRequestTimeout = 40;
