import 'package:carnival_compass_mobile/issue_add.dart';
import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class FeteDetails extends StatefulWidget {
  FeteDetails({this.feteId, this.posterUrl});

  final String feteId;
  final String posterUrl;

  @override
  _FeteDetailsState createState() => _FeteDetailsState();
}

class _FeteDetailsState extends State<FeteDetails> {
  String _userId;
  DocumentSnapshot _feteSnapshot;
  DocumentSnapshot _userFeteSnapshot;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    AuthUtilities.getCurrentUser().then((user) {
      _userId = user.uid;
      final feteStream =
          Firestore.instance.document('fetes/${widget.feteId}').snapshots();
      final userFeteStream = Firestore.instance
          .document('users/$_userId/fetes/${widget.feteId}')
          .snapshots();
      Observable<List<DocumentSnapshot>> observable = Observable.combineLatest2(
          feteStream, userFeteStream, (fete, userFete) => [fete, userFete]);
      observable.listen((snapshots) {
        if (this.mounted) {
          setState(() {
            _feteSnapshot = snapshots[0];
            _userFeteSnapshot = snapshots[1];
          });
        }
      });
    });
  }

  Widget _showDirections(BuildContext context) {
    if (_feteSnapshot['location'] != null) {
      return IconButton(
        icon: Icon(Icons.directions),
        onPressed: () {
          CarnivalCompassUtilities.launchDirections(
            position: _feteSnapshot['location'],
            context: context,
            label: _feteSnapshot['name'],
          );
          EventPublisher.publishEvent(
              eventName: EventPublisher.FETE_DIRECTIONS_EVENT,
              eventParams: <String, dynamic>{
                EventPublisher.FETE_NAME_PARAM: _feteSnapshot['name'],
                EventPublisher.FETE_ID_PARAM: _feteSnapshot.documentID,
              });
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_feteSnapshot == null) {
      return _getLoadingScaffold();
    }
    return _getDetailScaffold();
  }

  Widget _getLoadingScaffold() {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text("Fete Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    )),
                background: Hero(
                    tag: 'poster_${widget.feteId}',
                    child: Opacity(
                        opacity: 0.3,
                        child: Image.network(
                          widget.posterUrl,
                          fit: BoxFit.cover,
                        ))),
              ),
            ),
          ];
        },
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _getDetailScaffold() {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.report_problem),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        settings: RouteSettings(
                          name: 'issue/${_feteSnapshot['name']}',
                        ),
                        builder: (context) => AddIssue(
                              feteId: widget.feteId,
                              feteName: _feteSnapshot['name'],
                            ),
                      ),
                    )
                        .then(
                      (result) {
                        if (result != null && result) {
                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Issue submitted, thank you.'),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(_feteSnapshot['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    )),
                background: Hero(
                    tag: 'poster_${widget.feteId}',
                    child: Opacity(
                        opacity: 0.3,
                        child: Image.network(
                          widget.posterUrl,
                          fit: BoxFit.cover,
                        ))),
              ),
            ),
          ];
        },
        body: ListView(
          children: <Widget>[
            _feteSnapshot['published'] == false
                ? ListTile(
                    leading: Icon(Icons.traffic),
                    title: Text(_feteSnapshot['status']),
                  )
                : Container(),
            ListTile(
              leading: Icon(Icons.thumb_up),
              title: Text('${_feteSnapshot['likes']}'),
              trailing: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Opacity(
                    opacity: _userFeteSnapshot.exists &&
                            _userFeteSnapshot['liking'] != null &&
                            _userFeteSnapshot['liking']
                        ? 1
                        : 0,
                    child: CircularProgressIndicator(),
                  ),
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    color: _userFeteSnapshot.exists &&
                            _userFeteSnapshot['like'] != null &&
                            _userFeteSnapshot['like']
                        ? Colors.blue
                        : Colors.black,
                    onPressed: () {
                      FeteUtilities.likeFete(_userId, _feteSnapshot);
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.local_play),
              title: Text(_feteSnapshot['name']),
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text(_feteSnapshot['description']),
              trailing: IconButton(
                icon: Icon(Icons.open_in_new),
                onPressed: () {
                  launch(_feteSnapshot['link']);
                  EventPublisher.publishEvent(
                      eventName: EventPublisher.FETE_LINK_EVENT,
                      eventParams: <String, dynamic>{
                        EventPublisher.FETE_NAME_PARAM: _feteSnapshot['name'],
                        EventPublisher.FETE_ID_PARAM: _feteSnapshot.documentID,
                      });
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.today),
              title: Text(DateFormat.yMMMMd('en_AU')
                  .add_jm()
                  .format(_feteSnapshot['party_time'].toDate())),
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('${_feteSnapshot['base_price']} TTD'),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text(_feteSnapshot['venue']),
              trailing: _showDirections(context),
            ),
          ],
        ),
      ),
    );
  }
}
