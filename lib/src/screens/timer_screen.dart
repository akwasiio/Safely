import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pref_dessert/pref_dessert.dart';
import 'dart:math' as math;
import 'package:safely/src/model/activity_information.dart';
import 'package:safely/src/model/custom_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerScreen extends StatefulWidget {
  final UserActivityInfo userActivityInfo;

  TimerScreen({Key key, this.userActivityInfo}) : super(key: key);

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  AnimationController animationController;
  Animation animation;

  static const platform = const MethodChannel('io.safely.code.shinobi/');
  int repeatCount = 0;

  String numbers;


  String get timerString {
    Duration duration =
        animationController.duration * animationController.value;
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: widget.userActivityInfo.duration);

    animation =
        CurvedAnimation(parent: animationController, curve: Curves.linear)
          ..addStatusListener((AnimationStatus status) {
            if (status == AnimationStatus.dismissed && repeatCount == 0) {
              setState(() {
                repeatCount += 1;
                animationController = AnimationController(
                    vsync: this, duration: Duration(seconds: 10));
                animation = animationController
                  ..addStatusListener((status) {
                    if (status == AnimationStatus.dismissed) {
                      sendingSms();
                      Navigator.of(context).pop();
                    }
                  });
              });
              startCountDown();
            }
          });
    retrieveSavedContacts();
    startCountDown();
  }

  retrieveSavedContacts() async {
    var prefs = await SharedPreferences.getInstance();
    var repo = PreferencesRepository<CustomContact>(prefs, JsonCustomContactDesSer());
    var temp = repo.findAll();
    List holder = [];

    temp.forEach((tem) {
      setState(() {
        var num = tem.contact.phones.toList();
        var tempo = num[0].value;

        holder.add(tempo);
        numbers = holder.join(",");
      });
    });

  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void sendingSms() async {
    await platform.invokeMethod("sendSms", <String, dynamic>{
      "phone": numbers,
      "message": "Emergency"
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: FractionalOffset.center,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: animationController,
                            builder: (BuildContext context, Widget child) {
                              return CustomPaint(
                                painter: TimerPainter(
                                    animation: animation,
                                    backgroundColor: Colors.white,
                                    color: Theme.of(context).accentColor),
                              );
                            },
                          ),
                        ),
                        Align(
                          alignment: FractionalOffset.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "Count Down",
                                style: Theme.of(context).textTheme.subhead,
                              ),
                              AnimatedBuilder(
                                  animation: animationController,
                                  builder: (_, Widget child) {
                                    return Text(
                                      timerString,
                                      style:
                                          Theme.of(context).textTheme.display3,
                                    );
                                  })
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FloatingActionButton(
                      child: AnimatedBuilder(
                          animation: animationController,
                          builder: (_, Widget child) {
                            return Icon(animationController.isAnimating
                                ? Icons.pause
                                : Icons.play_arrow);
                          }),
                      onPressed: () {
                        if (animationController.isAnimating) {
                          animationController.stop();
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void startCountDown() {
    animationController.reverse(
        from:
            animationController.value == 0.0 ? 1.0 : animationController.value);
  }
}

class TimerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color backgroundColor;
  final Color color;
  final bool restartPainting;

  TimerPainter(
      {this.animation, this.backgroundColor, this.color, this.restartPainting})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * math.pi;
    canvas.drawArc(Offset.zero & size, math.pi * 1.5, -progress, false, paint);
    // TODO: implement paint
  }

  @override
  bool shouldRepaint(TimerPainter old) {
    return animation.value != old.animation.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}
