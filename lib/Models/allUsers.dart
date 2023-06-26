import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Users{

  String? id;
  String? email;
  String? name;
  String? phone;

  Users({this.id,this.email,this.name,this.phone});

  Users.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.key;
    final data = snapshot.value as Map;
    name = data["name"] as String;
    email = data['email'] as String;
    phone = data['phone'] as String;
  }

}