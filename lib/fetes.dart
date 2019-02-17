import 'package:carnival_compass_mobile/fete_details.dart';
import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:quiver/collection.dart';

class FetesWidget extends StatelessWidget {
  FetesWidget({
    this.filterMap,
  });

  final Map<String, dynamic> filterMap;

  Query _getBaseQuery(
    bool published,
    String userId,
  ) {
    final _now = DateTime.now();
    final _currentDate = DateTime(_now.year, _now.month, _now.day);

    Query _baseQuery = Firestore.instance
        .collection('fetes')
        .orderBy('party_time')
        .where('party_time', isGreaterThanOrEqualTo: _currentDate);

    if (published) {
      return _baseQuery.where('published', isEqualTo: true);
    } else {
      return _baseQuery
          .where('published', isEqualTo: false)
          .where('author', isEqualTo: userId);
    }
  }

  Map<String, dynamic> _setFeteStreams(var user) {
    final Map<String, dynamic> _feteStreams = new Map();

    Query _publishedQuery = _getBaseQuery(true, null);
    Query _unpublishedQuery = _getBaseQuery(false, user.uid);

    if (filterMap['option'] == FilterOption.myFetes) {
      _publishedQuery = _publishedQuery.where('author', isEqualTo: user.uid);
    }

    _feteStreams['published'] = _publishedQuery;
    _feteStreams['unpublished'] = _unpublishedQuery;
    return _feteStreams;
  }

  List<dynamic> _filterFeteList(List feteSnapshots, Function filter) {
    List<dynamic> _tempList = List();
    for (var _fete in feteSnapshots) {
      if (filter(_fete)) {
        _tempList.add(_fete);
      }
    }
    return _tempList;
  }

  bool _feteIsLiked(Map<String, DocumentSnapshot> userFetes, String userId,
      DocumentSnapshot fete) {
    return userFetes.containsKey(fete.documentID) &&
        userFetes[fete.documentID]['like'] != null &&
        userFetes[fete.documentID]['like'];
  }

  List<dynamic> _performManualFilters(List feteSnapshots,
      Map<String, DocumentSnapshot> userFetesMap, String userId) {
    if (filterMap['option'] == FilterOption.day) {
      feteSnapshots = _filterFeteList(
        feteSnapshots,
        (var _fete) {
          final _partyTime = _fete['party_time'].toDate();
          final _partyDate =
              DateTime(_partyTime.year, _partyTime.month, _partyTime.day);
          return _partyDate == filterMap['date'];
        },
      );
    } else if (filterMap['option'] == FilterOption.price) {
      feteSnapshots = _filterFeteList(
        feteSnapshots,
        (var _fete) {
          return _fete['base_price'] <= filterMap['price'];
        },
      );
    } else if (filterMap['option'] == FilterOption.liked) {
      feteSnapshots = _filterFeteList(
        feteSnapshots,
        (var _fete) {
          return _feteIsLiked(userFetesMap, userId, _fete);
        },
      );
    }
    return feteSnapshots;
  }

  Widget _getEventDate(Timestamp partyTime) {
    String partyTimeStr = 'To be announced';
    if (partyTime != null) {
      partyTimeStr = CarnivalCompassUtilities().toEventDateFormat(partyTime);
    }
    return Text(
      partyTimeStr,
    );
  }

  Widget feteLiked(Map<String, DocumentSnapshot> userFetes, String userId,
      DocumentSnapshot fete) {
    final liking = userFetes.containsKey(fete.documentID) &&
        userFetes[fete.documentID]['liking'] != null &&
        userFetes[fete.documentID]['liking'];
    final likedFete = _feteIsLiked(userFetes, userId, fete);

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(
          opacity: liking ? 1 : 0,
          child: CircularProgressIndicator(),
        ),
        IconButton(
          icon: Icon(Icons.thumb_up),
          color: likedFete ? Colors.blue.shade400 : Colors.black,
          onPressed: () {
            FeteUtilities.likeFete(userId, fete);
          },
        ),
      ],
    );
  }

  Map<String, DocumentSnapshot> querySnapshotToMap(
      QuerySnapshot querySnapshot) {
    final documentMap = Map<String, DocumentSnapshot>();
    for (DocumentSnapshot documentSnapshot in querySnapshot.documents) {
      documentMap[documentSnapshot.documentID] = documentSnapshot;
    }
    return documentMap;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthUtilities.getCurrentUser(),
      builder: (_, AsyncSnapshot<FirebaseUser> snapshot) {
        if (snapshot.hasData) {
          var user = snapshot.data;
          final Map<String, dynamic> _feteStreams = _setFeteStreams(user);
          Observable<List<QuerySnapshot>> zipStream = Observable.combineLatest3(
            _feteStreams['published'].snapshots(),
            _feteStreams['unpublished'].snapshots(),
            Firestore.instance
                .collection('users/${user.uid}/fetes')
                .snapshots(),
            (fetes, drafts, userFetes) => [fetes, drafts, userFetes],
          );

          return StreamBuilder(
            stream: zipStream,
            builder: (_, AsyncSnapshot<List<QuerySnapshot>> snapshots) {
              if (snapshots.hasData) {
                QuerySnapshot _fetesSnapshot = snapshots.data[0];
                QuerySnapshot _draftsSnapshot = snapshots.data[1];
                final _fetesTree = TreeSet(
                  comparator: (a, b) => a['party_time'] == b['party_time']
                      ? a['name'].compareTo(b['name'])
                      : a['party_time'].compareTo(b['party_time']),
                );
                _fetesTree.addAll(_fetesSnapshot.documents);
                _fetesTree.addAll(_draftsSnapshot.documents);
                List<dynamic> _feteSnapshots = _fetesTree.toList();

                QuerySnapshot _userFetesSnapshot = snapshots.data[2];
                Map<String, DocumentSnapshot> _userFetesMap =
                    querySnapshotToMap(_userFetesSnapshot);

                _feteSnapshots = _performManualFilters(
                    _feteSnapshots, _userFetesMap, user.uid);

                if (_feteSnapshots.length != 0) {
                  return ListView.builder(
                    itemCount: _feteSnapshots.length,
                    itemBuilder: (_, index) {
                      final _fete = _feteSnapshots[index];
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            InkWell(
                              child: Hero(
                                tag: 'poster_${_fete.documentID}',
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Center(
                                      child: FadeInImage.assetNetwork(
                                        placeholder: 'assets/placeholder.png',
                                        image: _fete['poster_url'],
                                        fit: BoxFit.cover,
                                        height: 200,
                                      ),
                                    ),
                                    _fete['published'] == false
                                        ? FeteUtilities.getFeteLabel(
                                            context,
                                            _fete['status'],
                                          )
                                        : Container(),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  settings: RouteSettings(
                                      name: 'fetes/' + _fete['name']),
                                  builder: (context) => FeteDetails(
                                        posterUrl: _fete['poster_url'],
                                        feteId: _fete.documentID,
                                      ),
                                ));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      _fete['name'],
                                      style: TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  Row(
                                    children: <Widget>[
                                      feteLiked(_userFetesMap, user.uid, _fete),
                                      Text(
                                        ' ${_fete['likes']}',
                                        style: TextStyle(fontSize: 22),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _getEventDate(_fete['party_time']),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return Text(
                    'No results found.',
                    style: TextStyle(
                      fontSize: 22,
                      color: Theme.of(context).accentTextTheme.caption.color,
                    ),
                  );
                }
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
      },
    );
  }
}
