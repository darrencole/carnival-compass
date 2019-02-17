import 'package:carnival_compass_mobile/bands.dart';
import 'package:carnival_compass_mobile/fetes.dart';
import 'package:carnival_compass_mobile/fete_filter.dart';
import 'package:carnival_compass_mobile/utilities.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:share/share.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Choice {
  const Choice({this.title, this.icon});
  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'About', icon: Icons.info_outline),
  const Choice(title: 'Share', icon: Icons.share),
  const Choice(title: 'Feedback', icon: Icons.feedback),
];

final Logger homeLog = Logger("home");

class CarnivalCompassHome extends StatefulWidget {
  @override
  CarnivalCompassHomeState createState() => CarnivalCompassHomeState();
}

class CarnivalCompassHomeState extends State<CarnivalCompassHome>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  TabController _tabController;
  Map<String, dynamic> _filterMap;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      homeLog.fine('onMessage: $message');
      homeLog.fine(message);
    }, onLaunch: (Map<String, dynamic> message) {
      homeLog.fine('onLaunch: $message');
      homeLog.fine(message);
    }, onResume: (Map<String, dynamic> message) {
      homeLog.fine('onResume: $message');
      homeLog.fine(message);
    });

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      homeLog.fine("Settings registered: $settings");
    });

    initializeDateFormatting();

    _filterMap = Map();
    _filterMap['option'] = FilterOption.none;
  }

  void _select(Choice choice) async {
    switch (choice.title) {
      case 'About':
        homeLog.fine('Go to About Screen');
        Navigator.of(context).pushNamed('about');
        break;
      case 'Share':
        homeLog.fine('Share Carnival Compass');
        Share.share(
            'Find your fete and band with Carnival Compass. https://carnivalcompass.page.link/XktS');
        EventPublisher.publishEvent(
          eventName: EventPublisher.SHARE_CARNIVAL_COMPASS_EVENT,
        );
        break;
      case 'Feedback':
        homeLog.fine('Go to Feedback Screen');
        final result = await Navigator.of(context).pushNamed('feedback_add');
        if (result != null && result) {
          final snackBar = SnackBar(content: Text('Thanks for the feedback!'));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        }
        break;
      default:
        break;
    }
  }

  void _logFilterAction() {
    homeLog.fine('Filter Fetes List: $_filterMap');

    Map<String, dynamic> _eventParams = Map();
    _eventParams[EventPublisher.FETE_FILTER_OPTION_PARAM] =
        _filterMap['option'].toString();
    if (_filterMap['option'] == FilterOption.day) {
      _eventParams[EventPublisher.FETE_FILTER_DATE_PARAM] =
          _filterMap['date'].toString();
    } else if (_filterMap['option'] == FilterOption.price) {
      _eventParams[EventPublisher.FETE_FILTER_PRICE_PARAM] =
          _filterMap['price'];
    }
    EventPublisher.publishEvent(
      eventName: EventPublisher.FETE_FILTER_EVENT,
      eventParams: _eventParams,
    );
  }

  void _filterFeteList() {
    FeteFilterWidget _feteFilter = FeteFilterWidget(
      filterMap: _filterMap,
    );
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Filter fetes by...'),
          children: <Widget>[
            _feteFilter,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                FlatButton(
                  child: Text('Filter'),
                  onPressed: () {
                    setState(() {
                      _filterMap = _feteFilter.getSelected();
                    });
                    _logFilterAction();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _addFete() async {
    final result = await Navigator.of(context).pushNamed('fete_add');
    if (result != null && result) {
      final snackBar = SnackBar(content: Text('Thanks for adding a fete!'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  List<Widget> _getHomeActions() {
    List<Widget> actions = <Widget>[
      PopupMenuButton<Choice>(
        onSelected: _select,
        itemBuilder: (BuildContext context) {
          return choices.map((Choice choice) {
            return PopupMenuItem<Choice>(
              value: choice,
              child: Text(choice.title),
            );
          }).toList();
        },
      ),
    ];
    if (_tabController.index == 0) {
      actions.insert(
        0,
        IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: _filterFeteList,
          tooltip: 'Filter fete list',
        ),
      );
      actions.insert(
        1,
        IconButton(
          icon: Icon(Icons.add),
          onPressed: _addFete,
          tooltip: 'Add fete',
        ),
      );
    }
    return actions;
  }

  Widget _getFilterChip() {
    String _text =
        "Filtered by ${_filterMap['option'].toString().split('.').last}";
    if (_filterMap['option'] == FilterOption.day) {
      String _date = DateFormat.yMMMd('en_GB').format(_filterMap['date']);
      _text = "$_text: $_date";
    } else if (_filterMap['option'] == FilterOption.price) {
      _text = "$_text: \$${_filterMap['price']}";
    } else if (_filterMap['option'] == FilterOption.liked) {
      _text = "Liked by me";
    } else if (_filterMap['option'] == FilterOption.myFetes) {
      _text = "Submitted by me";
    }
    return Chip(
      backgroundColor: Theme.of(context).accentColor,
      label: Text(_text),
      deleteButtonTooltipMessage: 'Remove filter',
      onDeleted: () {
        setState(() {
          _filterMap = Map();
          _filterMap['option'] = FilterOption.none;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: _getHomeActions(),
        leading: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Image.asset('assets/cc_logo.png'),
        ),
        title: Text('Carnival Compass'),
        titleSpacing: 0.0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.local_play),
              text: 'Fetes',
            ),
            Tab(
              icon: Icon(Icons.local_shipping),
              text: 'Bands',
            ),
          ],
        ),
      ),
      body: TabBarView(
        physics: NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: [
          Column(
            children: <Widget>[
              _filterMap['option'] != FilterOption.none
                  ? _getFilterChip()
                  : Container(),
              Expanded(
                child: FetesWidget(
                  filterMap: _filterMap,
                ),
              ),
            ],
          ),
          BandsWidget(),
        ],
      ),
    );
  }
}
