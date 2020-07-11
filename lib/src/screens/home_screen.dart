import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:easy_dialogs/easy_dialogs.dart";
import 'package:flutter/services.dart';
import 'package:safely/src/screens/contacts_screen.dart';
import 'package:safely/src/screens/timer_screen.dart';
import 'duration_dialog.dart';
import 'package:safely/src/model/activity_information.dart';
import 'package:safely/src/screens/chosen_contacts_screen.dart';
import 'package:rounded_modal/rounded_modal.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  double margin = 1.0;
  String selected;
  String durationSelected = "Select duration";
  String userActivity = "Choose activity";

//  String chooseActivityLabel = displayActivityLabel ? "Choose Activity" : "";
//  static bool displayActivityLabel = false;
//  String chooseDurationLabel = displayDurationLabel ? "Choose Duration" : "";
//  static bool displayDurationLabel = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        body: _buildHomeScreen(),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.only(top: 8.0), child: _buildAppBar()),
        SizedBox(
          height: 60.0,
        ),
        _buildButtonToTriggerDialog(),
        SizedBox(
          height: 40.0,
        ),
        _buildButtonToTriggerDurationDialog(),
        SizedBox(
          height: 40.0,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            keyboardType: TextInputType.multiline,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: "What are you wearing? Are you picking a taxi? etc.",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        SizedBox(
          height: 20.0,
        ),
        _buildStartTimerButton()
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: ShapeDecoration(
              shape: CircleBorder(
                  side: BorderSide(
                width: 4.0,
                color: Colors.white70,
              )),
            ),
            height: 50,
            width: 50,
            child: Hero(
                tag: "splash",
                child: Image.asset("assets/images/safely_logo.png")),
          ),
          Spacer(
            flex: 2,
          ),
          Theme(
            data: ThemeData(canvasColor: Colors.transparent),
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).accentColor,
                size: 30.0,
              ),
              onPressed: () {
                _showBottomSheet(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonToTriggerDialog() {
    return RaisedButton(
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Text(
          userActivity,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.subtitle2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      onPressed: () {
        _openDialog();
      },
    );
  }

  Widget _buildButtonToTriggerDurationDialog() {
    return RaisedButton(
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Text(
          durationSelected,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.subtitle2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onPressed: () {
        _showDurationPickerDialog();
      },
    );
  }

  String initial = "Taking a walk alone in the neighborhood";
  List<String> dialogList = [
    'Taking a walk alone in the neighborhood',
    'Picking a taxi',
    "Buying a phone from Circle",
    "Going to Kobby's house",
    "Going out for a run in the neighborhood",
  ];

  _openDialog() {
    showDialog(
        context: context,
        builder: (context) => SingleChoiceConfirmationDialog<String>(
              title: Text("Choose Activity"),
              initialValue: initial,
              items: dialogList,
              onSubmitted: (string) {
                setState(() {
                  userActivity = string;
                });
              },
            ));
  }

  void _showDurationPickerDialog() async {
    // this will contain the result of the Navigator.pop(context, result)
    final results = await showDialog(
        context: context, builder: (context) => DurationDialog());
    String hrText = results[0] == 1 || results[0] == 0 ? "hr" : "hrs";
    String minText = results[1] == 1 || results[1] == 0 ? "min" : "mins";

    setState(() {
      if (results != null) {
        hours = results[0];
        minutes = results[1];
        durationSelected = "${results[0]}$hrText, ${results[1]}$minText";
      }
    });
  }

  int hours;
  int minutes;

  Widget _buildStartTimerButton() {
    return RaisedButton(
      color: Theme.of(context).primaryColor,
      onPressed: () {
        if (userActivity.toLowerCase() != "choose activity" &&
            (hours != null && minutes != null)) {
          var infoObj = UserActivityInfo(
              activityTitle: userActivity,
              duration: Duration(hours: hours, minutes: minutes));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimerScreen(
                userActivityInfo: infoObj,
              ),
            ),
          );
        } else if (userActivity.toLowerCase() == "choose activity") {
          print("Pick an activity");
        } else if (hours == 0 && minutes == 0) {
          print("Pick a duration");
        }
      },
      padding: const EdgeInsets.all(15.0),
      child: Text(
        "Start Timer",
        style: Theme.of(context).primaryTextTheme.bodyText2.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showRoundedModalBottomSheet(
        context: context,
        color: Colors.blueGrey,
        radius: 20,
        builder: (context) {
          return Theme(
            data: ThemeData(canvasColor: Colors.transparent),
            child: Container(
              height: 350,
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: _buildBottomSheetContent(),
              ),
            ),
          );
        });
  }

  Widget _buildBottomSheetContent() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Center(
            child: Text(
              "Settings",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.remove_red_eye,
            color: Theme.of(context).accentColor,
          ),
          title: Text("View selected contacts"),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 18.0,
            color: Theme.of(context).accentColor,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => ChosenContactsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(
            Icons.add,
            color: Theme.of(context).accentColor,
          ),
          title: Text("Add New Contacts"),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 18.0,
            color: Theme.of(context).accentColor,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => ContactsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
