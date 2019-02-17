import 'package:carnival_compass_mobile/feedback_add.dart';
import 'package:carnival_compass_mobile/fete_add.dart';
import 'package:carnival_compass_mobile/home.dart';
import 'package:carnival_compass_mobile/about.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  FirebaseAnalytics analytics = FirebaseAnalytics();
  FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true);

  runApp(MaterialApp(
    title: 'Carnival Compass',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      accentColor: Colors.yellow,
    ),
    navigatorObservers: <NavigatorObserver>[
      observer,
    ],
    home: CarnivalCompassHome(),
    routes: <String, WidgetBuilder>{
      'about': (BuildContext context) => CarnivalCompassAbout(),
      'fete_add': (BuildContext context) => AddFete(),
      'feedback_add': (BuildContext context) => AddFeedback(),
    },
  ));
}
