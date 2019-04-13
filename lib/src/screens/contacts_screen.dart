import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:pref_dessert/pref_dessert.dart';
import 'package:safely/src/model/custom_contact.dart';
import 'package:safely/src/misc/permissions.dart' as perm;
import 'package:shared_preferences/shared_preferences.dart';
import 'chosen_contacts_screen.dart';

class ContactsPage extends StatefulWidget {
  @override
  State<ContactsPage> createState() => ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
  List<Contact> _contacts = List();
  List<CustomContact> _uiCustomContacts = List();
  List<CustomContact> _allContacts = List();

  List<CustomContact> selectedContacts = List();
  bool _isLoading = false;
  
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    perm.requestPermissions();
    refreshContacts();
    super.initState();
  }

  refreshContacts() async {
    setState(() {
      _isLoading = true;
    });
    var contacts = await ContactsService.getContacts(withThumbnails: false);
    _populateContacts(contacts);
  }

  Widget _buildSearchField() {
    return Container(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                filterSearchResults(value);
              },
              controller: searchController,
              decoration: InputDecoration(
                  labelText: "Search Contacts",
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)))),
            ),
          )
        ],
      ),
    );
  }

  void _populateContacts(Iterable<Contact> contacts) {
    _contacts = contacts.where((item) => item.displayName != null).toList();
    _contacts.sort((a, b) => a.displayName.compareTo(b.displayName));

    _allContacts =
        _contacts.map((contact) => CustomContact(contact: contact)).toList();

    setState(() {
      _uiCustomContacts = _allContacts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: !_isLoading
            ? buildContactsUI()
            : Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.black54,
                ),
              ),
      ),
    );
  }

  void filterSearchResults(String query) {
    print(query);
    List<CustomContact> searchedContacts = List();
    searchedContacts.addAll(_uiCustomContacts);
    if (query.isNotEmpty) {
      List<CustomContact> dummyContacts = List();
      searchedContacts.forEach((item) {
        if (item.contact.displayName.contains(query)) dummyContacts.add(item);
      });
      setState(() {
        _uiCustomContacts.clear();
        _uiCustomContacts.addAll(dummyContacts);
      });
      return;
    } else {
      setState(() {
        _uiCustomContacts.clear();
        _uiCustomContacts.addAll(searchedContacts);
      });
    }
  }

  Widget buildContactsUI() {
    print("Building Contacts UI");
    return Column(
      children: <Widget>[
        _buildSearchField(),
        Expanded(
          child: ListView.builder(
            itemCount: _uiCustomContacts?.length,
            itemBuilder: (context, index) {
              CustomContact _contact = _uiCustomContacts[index];
              var _phonesList = _contact.contact.phones.toList();

              return _buildListTile(_contact, _phonesList);
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            if (!(selectedContacts.length >= 3)) {
              final snackBar = SnackBar(
                content: Text("Select at least 3 contacts"),
                backgroundColor: Colors.blueGrey,
              );
              Scaffold.of(context).showSnackBar(snackBar);
            } else {
              updateSharedPrefs();
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChosenContactsPage()));
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: selectedContacts.length >= 3 ? Colors.amber : Colors.grey[850],
            height: 50.0,
            child: Center(
              child: Text(
                "ADD CONTACTS",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        )
      ],
    );
  }

  ListTile _buildListTile(CustomContact customContact, List<Item> list) {
    return ListTile(
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
      trailing: Checkbox(
        activeColor: Colors.green,
        value: customContact.isChecked,
        onChanged: (value) {
          setState(() {
            customContact.isChecked = value;
            if (customContact.isChecked) {
              selectedContacts.add(customContact);
            } else {
              selectedContacts.remove(customContact);

            }
          });
        },
      ),
    );
  }

  updateSharedPrefs() async {
    var prefs = await SharedPreferences.getInstance();
    var repo =
        PreferencesRepository<CustomContact>(prefs, JsonCustomContactDesSer());
    repo.saveAll(selectedContacts);
  }
}
