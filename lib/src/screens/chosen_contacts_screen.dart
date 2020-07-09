import 'dart:async';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:pref_dessert/pref_dessert.dart';
import 'package:safely/src/model/custom_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChosenContactsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChosenContactsPageState();
  }
}

class ChosenContactsPageState extends State<ChosenContactsPage> {
  List<CustomContact> savedContacts = List();

  bool _loading = true;

  retrieveSavedContacts() async {
    var prefs = await SharedPreferences.getInstance();
    var repo =
        PreferencesRepository<CustomContact>(prefs, JsonCustomContactDesSer());
    savedContacts = repo.findAll();
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  savePreferences() async {
    var prefs = await SharedPreferences.getInstance();
    var repo =
        PreferencesRepository<CustomContact>(prefs, JsonCustomContactDesSer());
    repo.saveAll(savedContacts);
  }

  @override
  void initState() {
    super.initState();
    retrieveSavedContacts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : _buildChosenContactsList(),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      color: Colors.blueGrey[200],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
          child: Text(
            "Selected Contacts",
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }

  Widget _buildChosenContactsList() {
    return Column(
      children: <Widget>[
        _buildTitleBar(),
        Expanded(
          child: ListView.builder(
            itemCount: savedContacts.length,
            itemBuilder: (context, index) {
              CustomContact contact = savedContacts[index];

              return _buildListTile(contact, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(CustomContact customContact, int index) {
    var list = customContact.contact.phones.toList();
    return Dismissible(
      background: Container(
        color: Colors.red,
      ),
      onDismissed: (direction) {
        setState(() {
          savedContacts.removeAt(index);
        });
        savePreferences();
      },
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (customContact.contact.displayName[0].toUpperCase()),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(customContact.contact.displayName ?? ""),
        subtitle: list.length >= 1 && list[0]?.value != null
            ? Text(list[0].value)
            : Text(''),
      ),
      key: Key(customContact.contact.displayName),
    );
  }
}
