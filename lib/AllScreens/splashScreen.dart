import 'dart:async';

import 'package:buraq/AllScreens/loginScreen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:buraq/AllScreens/mainscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  static const String idScreen = "splash";

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.bounceOut);
    controller.forward();
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Timer(
        Duration(seconds: 4),
        () {
          if(FirebaseAuth.instance.currentUser!=null){
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (BuildContext context) => MainScreen()));
          }else{
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (BuildContext context) => LoginScreen()));
          }

        } );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: const Color(0xFFc6520a),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: animation.value * 250,
                          child: Image.asset('images/1.png'),
                          height: animation.value * 250,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(width: 20.0, height: 100.0),
                        const Text(
                          'GET RIDE',
                          style: TextStyle(
                            fontSize: 43.0,
                            fontFamily: 'Brand-Regular',
                            color: Color.fromARGB(255, 41, 41, 40),
                          ),
                        ),
                        const SizedBox(width: 20.0, height: 100.0),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 40.0,
                            fontFamily: 'Brand-Bold',
                          ),
                          child: AnimatedTextKit(
                            pause: Duration(milliseconds: 700),
                            animatedTexts: [
                              RotateAnimatedText('FAST',
                                  duration: Duration(milliseconds: 700)),
                              RotateAnimatedText('ON-TIME',
                                  duration: Duration(milliseconds: 700)),
                              RotateAnimatedText('CHEAP',
                                  duration: Duration(milliseconds: 700)),
                            ],
                            onTap: () {

                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Padding(padding: EdgeInsets.only(top: 20.0)),
                      SizedBox(
                        height: 10.0,
                      ),
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
