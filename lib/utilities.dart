import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum FilterOption { none, day, price, liked, myFetes }

final Logger logger = Logger("utilities");

class EventPublisher {
  static const String BAND_DIRECTIONS_EVENT = "band_directions";
  static const String BAND_LINK_EVENT = "band_link";
  static const String FETE_DIRECTIONS_EVENT = "fete_directions";
  static const String FETE_LINK_EVENT = "fete_link";
  static const String SHARE_CARNIVAL_COMPASS_EVENT = "share";
  static const String FETE_ADD_ISSUE_EVENT = "fete_add_issue";
  static const String FETE_LIKE_EVENT = "fete_like";
  static const String FETE_ADD_EVENT = "fete_add";
  static const String FETE_FILTER_EVENT = "fete_filter";
  static const String FEEDBACK_EVENT = "feedback";

  static const String BAND_NAME_PARAM = "band_name";
  static const String BAND_ID_PARAM = "band_id";
  static const String FETE_NAME_PARAM = "fete_name";
  static const String FETE_ID_PARAM = "fete_id";
  static const String FETE_THUMB_PARAM = "thumb";
  static const String FETE_FILTER_OPTION_PARAM = "fete_filter_option";
  static const String FETE_FILTER_DATE_PARAM = "fete_filter_date";
  static const String FETE_FILTER_PRICE_PARAM = "fete_filter_price";

  static Future<Null> publishEvent({
    String eventName,
    Map<String, dynamic> eventParams,
  }) async {
    if (eventParams == null) {
      await FirebaseAnalytics().logEvent(
        name: eventName,
      );
    } else {
      await FirebaseAnalytics()
          .logEvent(name: eventName, parameters: eventParams);
    }
  }
}

class CarnivalCompassUtilities {
  static const int _END_MONTH = 3;
  static const int _END_DAY = 6;

  static DateTime lastDate() {
    return DateTime(DateTime.now().year + 1, _END_MONTH, _END_DAY);
  }

  String lastReportedFormat(Timestamp lastUpdated) {
    DateTime _lastUpdated = lastUpdated.toDate();
    Duration lastReported = DateTime.now().difference(_lastUpdated);

    if (lastReported.inMinutes < 3) {
      return 'Just now';
    }
    if (lastReported.inMinutes < 30) {
      return 'A few minutes ago';
    }
    if (lastReported.inMinutes < 60) {
      return 'About half hour ago';
    }
    if (lastReported.inHours < 2) {
      return 'About an hour ago';
    }

    //Weekday hh:mm AM/PM eg: Monday 2:30 PM
    return DateFormat.EEEE().add_jm().format(_lastUpdated);
  }

  String toEventDateFormat(Timestamp eventDate) {
    //Month Date, Year hh:mm AM/PM eg: October 1, 2018 2:30 PM
    return DateFormat('MMMM d, y', 'en_US').add_jm().format(eventDate.toDate());
  }

  static launchDirections({
    @required BuildContext context,
    @required GeoPoint position,
    @required String label,
  }) async {
    String lat = position.latitude.toString();
    String lng = position.longitude.toString();

    String url;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      //if iOS device
      url =
          'comgooglemaps://?center=$lat,$lng&q=$lat,$lng($label)zoom=14&mode=w';
      if (!await canLaunch(url)) {
        //if Google Maps not on iOS device
        url = 'http://maps.apple.com/?ll=$lat,$lng&q=$label';
      }
    } else if (Theme.of(context).platform == TargetPlatform.android) {
      //if android device
      url = 'geo:$lat,$lng?q=$lat,$lng($label)&mode=w';
    } else {
      url = 'https://www.google.com/maps/?q=$lat,$lng';
    }

    await launch(Uri.encodeFull(url));
  }
}

class AuthUtilities {
  static Future<FirebaseUser> getCurrentUser() {
    return FirebaseAuth.instance.currentUser().then((FirebaseUser user) {
      if (user == null) {
        return FirebaseAuth.instance.signInAnonymously().then((newUser) {
          return newUser;
        });
      }
      return user;
    });
  }
}

class FeteUtilities {
  static void likeFete(String userId, DocumentSnapshot fete) async {
    final userFeteReference =
        Firestore.instance.document('users/$userId/fetes/${fete.documentID}');

    await userFeteReference.setData(<String, dynamic>{
      'liking': true,
    }, merge: true);

    dynamic result = await CloudFunctions.instance.call(
        functionName: 'likeFete',
        parameters: <String, dynamic>{
          'uid': userId,
          'fete_id': fete.documentID
        }).catchError((error) {
      logger.severe('Like call failed', error);
    });

    EventPublisher.publishEvent(
        eventName: EventPublisher.FETE_LIKE_EVENT,
        eventParams: <String, dynamic>{
          EventPublisher.FETE_NAME_PARAM: result['feteName'],
          EventPublisher.FETE_THUMB_PARAM: result['thumb'],
        });

    userFeteReference.setData(<String, dynamic>{
      'liking': false,
    }, merge: true);
  }

  static Widget getFeteLabel(
    BuildContext context,
    String text,
  ) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).accentTextTheme.caption.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      color: Theme.of(context).accentColor,
    );
  }
}

class PackageInfoUtilities {
  static Future<PackageInfo> getPackageInfo() {
    return PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      return packageInfo;
    });
  }
}
