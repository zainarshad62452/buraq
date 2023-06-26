import 'package:flutter/material.dart';

class NoAvailableDriverDialog extends StatelessWidget {
  const NoAvailableDriverDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10.0,),

                Text("No driver found",style: TextStyle(fontSize: 22.0,fontFamily: 'Brand-Bold'),),

                SizedBox(height: 25.0,),

                Padding(
                    padding: EdgeInsets.all(8.0),
                  child: Text("No available driver found in the nearby, we suggest you to try again shortly",textAlign: TextAlign.center,),
                ),

                SizedBox(height: 30.0,),

                Padding(padding: EdgeInsets.all(17.0),
                  child: MaterialButton(
                    onPressed: (){
                      Navigator.pop(context);
                  },
                    color: Theme.of(context).hintColor,
                    child: Padding(padding: EdgeInsets.fromLTRB(5.0, 0.0, 5.0, 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Close',style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold,color: Colors.white),),
                          Icon(Icons.car_repair,color: Colors.white,size: 26.0,),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
