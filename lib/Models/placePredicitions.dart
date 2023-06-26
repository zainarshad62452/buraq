class PlacePredicitions{

  String? secondaryText;
  String? main_Text;
  String? place_id;

  PlacePredicitions({this.secondaryText,this.main_Text,this.place_id});

  PlacePredicitions.fromJson(Map<String, dynamic> json){

    place_id = json["place_id"];
    main_Text = json["structured_formatting"]["main_text"];
    secondaryText = json["structured_formatting"]["secondary_text"];
  }

}