import 'package:buraq/AllScreens/registerationScreen.dart';
import 'package:buraq/Assistants/assistantMethod.dart';
import 'package:buraq/configMaps.dart';
import 'package:flutter/material.dart';

import '../DataHandler/stripe.dart';
class CollectFareDailog extends StatefulWidget {

  final String paymentMethod;
  final int fareAmount;

   CollectFareDailog({Key? key,required this.paymentMethod,required this.fareAmount}) : super(key: key);

  @override
  State<CollectFareDailog> createState() => _CollectFareDailogState();
}

class _CollectFareDailogState extends State<CollectFareDailog> {
  String title = "";

  @override
  void initState() {
    title = "Pay by "+widget.paymentMethod;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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

            Text("Trip Fare"),

            SizedBox(height: 22.0,),
            Divider(height: 2.0,thickness: 2.0,),

            SizedBox(height: 16.0,),

            Text("PKR-${widget.fareAmount}",style: TextStyle(fontSize: 55.0,fontFamily: "Brand-Bold"),),

            SizedBox(height: 16.0),

            Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text("This is the total trip amount, it has been charged to the rider",textAlign: TextAlign.center,),
            ),

            SizedBox(height: 30.0,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MaterialButton(
                onPressed: () async {
                  if(widget.paymentMethod == "Cash"){
                    Navigator.pop(context,"close");
                  }else if(widget.paymentMethod == "Card"){
                    await StripeServices.instance.initialize();
                    await StripeServices.instance.startPurchase(widget.fareAmount!.toDouble(),
                            (isSuccess, message) async {
                          if (isSuccess) {
                            AssistantMethods.sendCustomNotificationToDriver(driverToken,context,"You have recieved an amount of RS ${widget.fareAmount} by rider");
                            displayToastMessage("Successfully", context);
                            Navigator.pop(context,"close");
                          } else {
                            displayToastMessage("Error Please pay by cash", context);
                          }
                        },context);
                  }
                },
                color: Colors.deepPurpleAccent,
              padding: EdgeInsets.all(17.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color: Colors.white),),
                    Icon(Icons.attach_money,color: Colors.white,size: 26.0,),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30.0,),
          ],
        ),
      ),
    );
  }
}
