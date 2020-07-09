
import 'dart:math';

import 'package:contacts_service/contacts_service.dart';
import 'package:pref_dessert/pref_dessert.dart';

class CustomContact {
  final Contact contact;
  bool isChecked;

  CustomContact({this.contact, this.isChecked = false});
}

class JsonCustomContactDesSer extends DesSer<CustomContact> {
  @override
  CustomContact deserialize(String s) {
    var toDeserialize = s.split(",");
    List<Item> phoneList = [];
    var con = Contact(givenName: toDeserialize[0],);
    con.displayName = con.givenName;
    if (toDeserialize.length > 2){
      for (int i = 1; i < toDeserialize.length; i++){
        var newItem =Item(value: toDeserialize[i]);
        phoneList.add(newItem);
      }
    }else {
      phoneList.add(Item(value: toDeserialize[1]));
    }

    con.phones = phoneList;
    return CustomContact(contact: con);
  }

  @override
  String get key => "nums";

  @override
  String serialize(CustomContact t) {
    var phoneString ="";

    if(t.contact.phones.toList().length > 1) {
      phoneString = t.contact.phones.toList().map((item) => item.value).join(",");
    }else{
      phoneString = t.contact.phones.first.value.toString();
    }

    return "${t.contact.displayName},${phoneString.split(" ").join("")}";
  }

}
