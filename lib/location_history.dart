import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:carnival_compass_mobile/utilities.dart';

class LocationItem extends StatelessWidget {
  LocationItem({this.snapshot});

  final DocumentSnapshot snapshot;

  Widget _getOnSiteImage() {
    String _onSiteImageURL = snapshot['on_site_image'];

    if (_onSiteImageURL != null &&
        _onSiteImageURL.isNotEmpty &&
        _onSiteImageURL != 'none') {
      return FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder.png',
        image: _onSiteImageURL,
        fit: BoxFit.cover,
      );
    } else {
      return Container();
    }
  }

  Widget _getOnSiteReport() {
    String _onSiteReport = snapshot['on_site_report'];

    if (_onSiteReport != null &&
        _onSiteReport.isNotEmpty &&
        _onSiteReport != 'none') {
      return Text(
        _onSiteReport,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
      );
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    CarnivalCompassUtilities ccu = CarnivalCompassUtilities();
    String published = ccu.lastReportedFormat(snapshot['report_timestamp']);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _getOnSiteReport(),
          ),
          _getOnSiteImage(),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text('${snapshot['address']}\n$published\n\n'),
          ),
        ]);
  }
}

class LocationHistory extends StatelessWidget {
  LocationHistory({
    this.locationsReference,
  });

  final CollectionReference locationsReference;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: StreamBuilder<QuerySnapshot>(
          stream: locationsReference.snapshots(),
          builder: (_, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              List<DocumentSnapshot> locations = snapshot.data.documents;
              return ListView.builder(
                itemCount: locations.length,
                itemBuilder: (_, index) {
                  DocumentSnapshot location = locations[index];
                  return LocationItem(snapshot: location);
                },
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}
