

import 'package:buraq/AllWidgets/Divider.dart';
import 'package:buraq/AllWidgets/progressDialod.dart';
import 'package:buraq/Assistants/resquestAssistant.dart';
import 'package:buraq/Models/address.dart';
import 'package:buraq/Models/placePredicitions.dart';
import 'package:buraq/configMaps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:provider/provider.dart';

import '../DataHandler/appData.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
TextEditingController pickUpTextEditingController = TextEditingController();
TextEditingController dropOffTextEditingController = TextEditingController();

 List<PlacePredicitions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    String home(){
  try{
if(Provider.of<AppData>(context).pickupLocation!=null){
return Provider.of<AppData>(context).pickupLocation.placeName;
}else{
  return "";
}
  }catch(exp){
    return "";
  }

}

    pickUpTextEditingController.text = home();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 215.0,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 6.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 25.0,top: 20.0,right: 25.0,bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(height: 5.0,),
                  Stack(
                  children: [
                    GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back
                        ),
                    ),
                    Center(
                      child: Text('Set Drop Off',style: TextStyle(fontSize:18.0,fontFamily: "Brand-Bold"),
                    ),
                    ),
                  ],
                  ),
                  SizedBox(height: 16.0,),
      
      
                  Row(
                    children: [
                      Image.asset("images/pickicon.png",height: 16.0,width: 16.0,),
      
                      SizedBox(width: 18.0,),
      
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(5.0),
      
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              controller: pickUpTextEditingController,
                              decoration: InputDecoration(
                                hintText: "PickUp Location",
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom: 8.0),
      
                              ),
                            ), 
                            ),
                        ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.0,),
      
                  
                  Row(
                    children: [
                      Image.asset("images/desticon.png",height: 16.0,width: 16.0,),
      
                      SizedBox(width: 18.0,),
      
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(5.0),
      
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                            child: TextField(
                              onChanged: (val){
                                findPlace(val);
                              },
                              controller: dropOffTextEditingController,
                              decoration: InputDecoration(
                                hintText: "Where to?",
                                fillColor: Colors.grey[400],
                                filled: true,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(left: 11.0,top: 8.0,bottom: 8.0),
                              ),
                            ), 
                            ),
                        ),
                        ),
                    ],
                  ),
                ],
              ),
              
              ),
            ),
            SizedBox(height: 8.0,),
            //tile for displaying predictions
            (placePredictionList.length > 0)?Padding(padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 16.0,),
            child: ListView.separated(itemBuilder: (context,index){
              return PredictionTile(placePredicitions: placePredictionList[index],);
            }, separatorBuilder: (BuildContext context, int index)=>DividerWidget(), itemCount: placePredictionList.length,
            shrinkWrap: true,
              physics: ClampingScrollPhysics(),
            ),
            ):Container(),

          ],
        ),
      ),
    );
  }

  void findPlace(String placeName) async{
    if(placeName.length >= 1){
      String autoCompleteUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:pk";

      var response = await RequestAssistant.getRequest(autoCompleteUrl);

      if(response == 'failed'){
        return;
      }

      if(response["status"]=="OK"){

        var predictions = response["predictions"];

        var placesList = (predictions as List).map((e) => PlacePredicitions.fromJson(e)).toList();
        setState((){
          placePredictionList = placesList;
        });

      }

    }

  }
}


class PredictionTile extends StatelessWidget {
   PredictionTile({Key? key,required this.placePredicitions}) : super(key: key);

  final PlacePredicitions placePredicitions;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      padding: EdgeInsets.all(0.0),
      onPressed: (){
        getPlaceAddressDetails("${placePredicitions.place_id}", context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10.0,),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(width: 14.0,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0,),
                      Text("${placePredicitions.main_Text}",overflow:TextOverflow.ellipsis,style: TextStyle(fontSize: 16.0),),
                      SizedBox(height: 2.0,),
                      Text("${placePredicitions.secondaryText}",style: TextStyle(fontSize: 16.0,color: Colors.grey),overflow:TextOverflow.ellipsis,),
                      SizedBox(height: 8.0,),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(width: 10.0,),
          ],
        ),
      ),
    );
  }
  void getPlaceAddressDetails(String placeId,context) async{

    showDialog(context: context, builder: (BuildContext context)=>ProgressDialod(message: "Setting Dropoff, please wait..."));

    String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";
    var res = await RequestAssistant.getRequest(placeDetailsUrl);
    Navigator.pop(context);
    if(res=='failed'){
      return;
    }

    if(res["status"]=="OK"){

      Address address = Address(placeName: res["result"]["name"], latitude: res["result"]["geometry"]["location"]["lat"], longititue: res["result"]["geometry"]["location"]["lng"],);
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longititue = res["result"]["geometry"]["location"]["lng"];
      Provider.of<AppData>(context,listen: false).updateDropOffLocation(address);
      Navigator.pop(context,"obtainDirection");

    }

  }
}
