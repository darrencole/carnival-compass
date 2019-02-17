import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:carnival_compass_mobile/utilities.dart';

class FeteFilterWidget extends StatefulWidget {
  FeteFilterWidget({
    this.filterMap,
  });

  final Map<String, dynamic> filterMap;
  final FeteFilterWidgetState _ffws = FeteFilterWidgetState();

  Map<String, dynamic> getSelected() {
    return _ffws._getSelected();
  }

  @override
  State<StatefulWidget> createState() => _ffws;
}

class FeteFilterWidgetState extends State<FeteFilterWidget> {
  final _initialPrice = 500;
  final _priceIncrement = 50;
  final _priceUpperLimit = 10000;
  final _priceLowerLimit = 0;

  FilterOption _option;
  String _date;
  int _price;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();

    _date = DateFormat.yMMMd('en_GB').format(DateTime.now());
    _price = _initialPrice;

    _option = widget.filterMap['option'];
    if (_option == FilterOption.none) {
      _option = FilterOption.day;
    } else if (_option == FilterOption.day) {
      _date = DateFormat.yMMMd('en_GB').format(widget.filterMap['date']);
    } else if (_option == FilterOption.price) {
      _price = widget.filterMap['price'];
    }
  }

  Map<String, dynamic> _getSelected() {
    Map<String, dynamic> _filterMap = Map();
    _filterMap['option'] = _option;
    if (_option == FilterOption.day) {
      _filterMap['date'] = DateFormat.yMMMd('en_GB').parse(_date);
    } else if (_option == FilterOption.price) {
      _filterMap['price'] = _price;
    }
    return _filterMap;
  }

  @override
  Widget build(BuildContext context) {
    Widget _getFilterRadioListTile(String title, FilterOption value) {
      return RadioListTile<FilterOption>(
        title: Text(title),
        value: value,
        groupValue: _option,
        onChanged: (FilterOption value) {
          setState(() {
            _option = value;
          });
        },
      );
    }

    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _getFilterRadioListTile(
                  'Day',
                  FilterOption.day,
                ),
              ),
              _option == FilterOption.day
                  ? Row(
                      children: <Widget>[
                        Text(_date),
                        IconButton(
                          icon: new Icon(Icons.event),
                          tooltip: 'Choose date',
                          onPressed: (() async {
                            final now = DateTime.now();
                            DateTime selectedDate = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: CarnivalCompassUtilities.lastDate(),
                              locale: Locale('en', 'GB'),
                            );
                            if (selectedDate != null) {
                              setState(() {
                                _date = DateFormat.yMMMd('en_GB')
                                    .format(selectedDate);
                              });
                            }
                          }),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _getFilterRadioListTile(
                  'Price',
                  FilterOption.price,
                ),
              ),
              _option == FilterOption.price
                  ? Row(
                      children: <Widget>[
                        IconButton(
                          icon: new Icon(Icons.remove),
                          tooltip: 'Decrease price',
                          onPressed: () {
                            if (_price > _priceLowerLimit) {
                              setState(() {
                                _price -= _priceIncrement;
                              });
                            }
                          },
                        ),
                        Text('\$$_price'),
                        IconButton(
                          icon: new Icon(Icons.add),
                          tooltip: 'Increase price',
                          onPressed: () {
                            if (_price < _priceUpperLimit) {
                              setState(() {
                                _price += _priceIncrement;
                              });
                            }
                          },
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
          _getFilterRadioListTile(
            'Liked',
            FilterOption.liked,
          ),
          _getFilterRadioListTile(
            'My Fetes',
            FilterOption.myFetes,
          ),
        ],
      ),
    );
  }
}
