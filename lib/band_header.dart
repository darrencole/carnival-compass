import 'dart:async';

import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logging/logging.dart';

final Logger bandHeaderLog = Logger("band_header");

class BandImage extends StatelessWidget {
  BandImage({this.snapshot});

  final DocumentSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder.png',
        image: snapshot['photo_url'],
        fit: BoxFit.cover,
      ),
      padding: const EdgeInsets.all(8.0),
      width: 125.0,
      height: 125.0,
    );
  }
}

class BandTitle extends StatelessWidget {
  BandTitle({this.snapshot});

  final DocumentSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
              text: snapshot['name'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
          TextSpan(
              text: '\n${snapshot['tagline']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0)),
        ],
      ),
    );
  }
}

class BandInfo extends StatelessWidget {
  BandInfo({this.snapshot});

  final DocumentSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    CarnivalCompassUtilities ccu = CarnivalCompassUtilities();
    String lastReported = ccu.lastReportedFormat(snapshot['last_updated']);

    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 30.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('${snapshot['address']} \n$lastReported'),
      ),
    );
  }
}

class BandDirections extends StatelessWidget {
  BandDirections({
    this.snapshot,
  });

  final DocumentSnapshot snapshot;

  _directionsHandler(BuildContext context) {
    bandHeaderLog.fine(
      'Directions button pressed for band: ${snapshot['name']}',
    );
    CarnivalCompassUtilities.launchDirections(
      context: context,
      label: snapshot['name'],
      position: snapshot['position'],
    );
    EventPublisher.publishEvent(
      eventName: EventPublisher.BAND_DIRECTIONS_EVENT,
      eventParams: <String, dynamic>{
        EventPublisher.BAND_NAME_PARAM: snapshot['name'],
        EventPublisher.BAND_ID_PARAM: snapshot.documentID,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 20.0, 0.0),
      child: Row(children: <Widget>[
        InkWell(
          onTap: () {
            _directionsHandler(context);
          },
          child: Text('Directions:'),
        ),
        IconButton(
          icon: Icon(Icons.directions),
          tooltip: 'Directions to band',
          onPressed: () {
            _directionsHandler(context);
          },
        ),
      ]),
    );
  }
}

class BandWebsite extends StatelessWidget {
  BandWebsite({
    this.snapshot,
  });

  final DocumentSnapshot snapshot;

  Future<bool> _canLaunch() async {
    return (await canLaunch(snapshot['website']));
  }

  _websiteHandler() async {
    bandHeaderLog.fine(
      'Website button pressed for band: ${snapshot['name']}',
    );
    await launch(snapshot['website']);
    EventPublisher.publishEvent(
        eventName: EventPublisher.BAND_LINK_EVENT,
        eventParams: <String, dynamic>{
          EventPublisher.BAND_NAME_PARAM: snapshot['name'],
          EventPublisher.BAND_ID_PARAM: snapshot.documentID,
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canLaunch(), // a Future<bool> or null
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Container();
          case ConnectionState.waiting:
            return Container();
          default:
            if (snapshot.data == true) {
              return Row(children: <Widget>[
                InkWell(
                  onTap: () {
                    _websiteHandler();
                  },
                  child: Text('Website:'),
                ),
                IconButton(
                  icon: Icon(Icons.link),
                  tooltip: 'Go to band\'s website',
                  onPressed: () {
                    _websiteHandler();
                  },
                ),
              ]);
            } else {
              return Container();
            }
        }
      },
    );
  }
}
