import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:carnival_compass_mobile/band_header.dart';
import 'package:carnival_compass_mobile/location_history.dart';

class CarnivalCompassBandDetails extends StatefulWidget {
  CarnivalCompassBandDetails({
    this.bandId,
  });

  final String bandId;

  @override
  State<StatefulWidget> createState() => CarnivalCompassBandDetailsState();
}

class CarnivalCompassBandDetailsState
    extends State<CarnivalCompassBandDetails> {
  DocumentReference bandReference;
  CollectionReference locationsReference;

  void initState() {
    super.initState();
    bandReference = Firestore.instance.document('bands/${widget.bandId}');

    locationsReference = bandReference.collection('locations');
  }

  Widget _getTitle() {
    return StreamBuilder(
      stream: bandReference.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text('Loading...');
        }
        return Text(snapshot.data['name']);
      },
    );
  }

  Widget getBandHeader() {
    return StreamBuilder(
      stream: bandReference.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        var bandSnapshot = snapshot.data;
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                BandImage(
                  snapshot: bandSnapshot,
                ),
                Expanded(
                    child: BandTitle(
                  snapshot: bandSnapshot,
                )),
              ],
            ),
            Row(
              children: <Widget>[
                BandDirections(
                  snapshot: bandSnapshot,
                ),
                BandWebsite(
                  snapshot: bandSnapshot,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _getTitle(),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: getBandHeader(),
          ),
          LocationHistory(
            locationsReference: locationsReference,
          ),
        ],
      ),
    );
  }
}
