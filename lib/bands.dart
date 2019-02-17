import 'package:carnival_compass_mobile/band_details.dart';
import 'package:carnival_compass_mobile/band_header.dart';
import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger("bands");

class BandsWidget extends StatelessWidget {
  final Query _bandsReference =
      Firestore.instance.collection('bands').orderBy('name');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseUser>(
        future: AuthUtilities.getCurrentUser(),
        builder: (_, AsyncSnapshot<FirebaseUser> user) {
          if (user.hasData) {
            return StreamBuilder(
              stream: _bandsReference.snapshots(),
              builder: (_, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  final int bandCount = snapshot.data.documents.length;
                  return ListView.builder(
                      itemCount: bandCount,
                      itemBuilder: (_, int index) {
                        final DocumentSnapshot document =
                            snapshot.data.documents[index];
                        return getBandDetailsLink(
                          context,
                          document,
                          Column(children: <Widget>[
                            Row(children: <Widget>[
                              BandImage(
                                snapshot: document,
                              ),
                              Expanded(
                                child: BandTitle(
                                  snapshot: document,
                                ),
                              ),
                            ]),
                            Row(children: <Widget>[
                              BandDirections(
                                snapshot: document,
                              ),
                              BandWebsite(
                                snapshot: document,
                              ),
                            ]),
                            BandInfo(
                              snapshot: document,
                            ),
                          ]),
                        );
                      });
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Widget getBandDetailsLink(
      BuildContext context, DocumentSnapshot snapshot, Widget widget) {
    return InkWell(
      onTap: () {
        logger.fine('Display details for band: ${snapshot.data['name']}');
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(name: 'bands/${snapshot.data['name']}'),
            builder: (context) =>
                CarnivalCompassBandDetails(bandId: snapshot.documentID),
          ),
        );
      },
      child: widget,
    );
  }
}
