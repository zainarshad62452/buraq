import 'package:buraq/Models/address.dart';
import 'package:flutter/cupertino.dart';



class AppData extends ChangeNotifier{

late Address pickupLocation,dropOffLocation;


void updatePickUpLocation(Address pickUpAddress){

pickupLocation = pickUpAddress;
notifyListeners();
}
void updateDropOffLocation(Address dropOffAddress){

  dropOffLocation = dropOffAddress;
  notifyListeners();
}

}