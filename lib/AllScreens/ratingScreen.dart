import 'package:buraq/configMaps.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
class RatingScreen extends StatefulWidget {

  final String driverId;

  const RatingScreen({Key? key,required this.driverId,}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22.0,),

              Text("Rate This Driver",style: TextStyle(fontSize: 20.0,fontFamily: "Brand-Bold",color: Colors.black54),),

              SizedBox(height: 22.0,),
              Divider(height: 2.0,thickness: 2.0,),

              SizedBox(height: 16.0),

              SmoothStarRating(
                rating: starCounter,
                color: Colors.green,
                allowHalfRating: false,
                starCount: 5,
                size: 45,
                onRatingChanged: (value){
                  starCounter = value;
                  if(starCounter == 1.0){
                    setState(() {
                      title = "Very Bad";
                    });
                  }
                  if(starCounter == 2.0){
                    setState(() {
                      title = "Bad";
                    });
                  }
                  if(starCounter == 3.0){
                    setState(() {
                      title = "Good";
                    });
                  }
                  if(starCounter == 4.0){
                    setState(() {
                      title = "Very Good";
                    });
                  }
                  if(starCounter == 5.0){
                    setState(() {
                      title = "Excellent";
                    });
                  }
                },
              ),

              SizedBox(height: 14.0,),

              Text(title,style: TextStyle(fontSize: 55.0,fontFamily: "Signatra",color: Colors.green),),

              SizedBox(height: 15.0,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: MaterialButton(
                  onPressed: (){
                    DatabaseReference driverRatingRef = FirebaseDatabase.instance.ref().child("captain")
                    .child(widget.driverId).child("ratings");

                    driverRatingRef.once().then((value) {
                      if(value.snapshot.value!=null){
                        double oldRatings = double.parse(value.snapshot.value.toString());
                        double addRatings = oldRatings+starCounter;
                        double averageRatings = addRatings/2;
                        driverRatingRef.set(averageRatings.toString());
                      }else{
                        driverRatingRef.set(starCounter.toString());
                      }
                    });
                    Navigator.pop(context);
                  },
                  color: Colors.deepPurpleAccent,
                  padding: EdgeInsets.all(17.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("Submit",style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color: Colors.white),),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30.0,),
            ],
          ),
        ),
      ),
    );
  }
}
