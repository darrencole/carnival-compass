import 'dart:io';

import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger("fete_add");

class AddFete extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Fete'),
      ),
      body: FeteForm(),
    );
  }
}

class FeteFormValidators {
  // HH:MM 12-hour format, optional leading 0, Mandatory Meridiems (AM/PM)
  static final todRegEx =
      RegExp(r"((1[0-2]|0?[1-9]):([0-5][0-9]) ?([AaPp][Mm]))");

  @visibleForTesting
  static TimeOfDay parsePartyTimeOfDay(text) {
    final matches = FeteFormValidators.todRegEx.allMatches(text);
    if (matches.length == 1) {
      final hourStr = text.split(':')[0];
      var hour = int.parse(hourStr);
      if (text.toLowerCase().contains('pm')) {
        hour += 12;
      }
      text = text.split(':')[1];
      final minuteStr = text.substring(0, 3);
      final minute = int.parse(minuteStr);

      return TimeOfDay(hour: hour, minute: minute);
    }
    throw FormatException();
  }

  static _validateFile(String text) {
    if (text.isEmpty) {
      return 'Fete must have a poster image';
    }

    File file = File(text);
    try {
      final fileLength = file.lengthSync();
      if (fileLength < 100) {
        return 'Use a higher quality image please.';
      }
    } on Exception {
      return 'Invalid image, please try again';
    }
  }

  static _validateTime(String text) {
    if (text.isEmpty) {
      return 'Fete must have a time.';
    }

    Iterable<Match> matches = todRegEx.allMatches(text);
    if (matches.length != 1) {
      return 'Please use date of format: HH:MM AM/PM';
    }
  }

  @visibleForTesting
  static validateDate(String text) {
    try {
      DateFormat.yMMMd('en_GB').parse(text);
      return null;
    } on FormatException {
      // do nothing
    }

    try {
      DateFormat.yMMMMd('en_GB').parse(text);
      return null;
    } on FormatException {
      return 'Date format incorrect. Try eg: 1 Mar 2019';
    }
  }

  @visibleForTesting
  static validateBasePrice(String text) {
    if (text.isEmpty) {
      return 'Fete must have a base price';
    }

    try {
      // Check for max two decimal places
      if (text.contains('.') &&
          text.substring(text.indexOf('.') + 1).length > 2) {
        throw FormatException();
      }

      final price = double.parse(text);

      if (price < 0) {
        return 'Price must be \$0.00 or more';
      }
      if (price > 10000) {
        return 'Price must be less than \$10000';
      }
    } on FormatException catch (_) {
      return 'Price must be valid format, eg: 350.00';
    }
  }

  static _validateNotEmpty(String text, String field) {
    return text.isEmpty ? 'Fete must have $field' : null;
  }

  static _validateLink(String text) {
    if (text.isEmpty) {
      return 'Fete must have a link';
    }

    RegExp exp = new RegExp(
        r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");
    Iterable<Match> matches = exp.allMatches(text);
    if (matches.length != 1) {
      return 'Please enter a properly formatted link.';
    }
  }
}

class FeteForm extends StatefulWidget {
  @override
  _FeteFormState createState() => _FeteFormState();
}

class _FeteFormState extends State<FeteForm> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _dateController = new TextEditingController();
  final TextEditingController _timeController = new TextEditingController();
  final TextEditingController _fileController = new TextEditingController();
  final TextEditingController _priceController = new TextEditingController();
  final TextEditingController _linkController = new TextEditingController();
  final TextEditingController _nameController = new TextEditingController();
  final TextEditingController _venueController = new TextEditingController();
  final TextEditingController _descController = new TextEditingController();

  DateTime _partyTime = DateTime.now();

  updateFeteTime() {
    try {
      final partyTime =
          FeteFormValidators.parsePartyTimeOfDay(_timeController.text);
      _partyTime = DateTime(
        _partyTime.year,
        _partyTime.month,
        _partyTime.day,
        partyTime.hour,
        partyTime.minute,
      );
    } on FormatException {
      // do nothing since time format is incorrect.
    }
  }

  updateFeteDate() {
    try {
      final partyDate = DateFormat.yMMMd('en_GB').parse(_dateController.text);
      _partyTime = DateTime(
        partyDate.year,
        partyDate.month,
        partyDate.day,
        _partyTime.hour,
        _partyTime.minute,
      );
    } on FormatException {
      // do nothing since date format is incorrect.
    }
  }

  _FeteFormState() {
    initializeDateFormatting();
    _dateController.addListener(() {
      updateFeteDate();
    });
    _timeController.addListener(() {
      updateFeteTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidate: false,
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          icon: const Icon(Icons.photo),
                          hintText: 'Fete image.',
                          labelText: 'Fete image',
                        ),
                        controller: _fileController,
                        validator: (val) =>
                            FeteFormValidators._validateFile(val),
                      ),
                    ),
                    IconButton(
                      icon: new Icon(Icons.add_photo_alternate),
                      tooltip: 'Choose Image',
                      onPressed: (() async {
                        File _imageFile = await ImagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (_imageFile.path.isNotEmpty) {
                          setState(() {
                            _fileController.text = _imageFile.path;
                          });
                        }
                      }),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.local_play),
                    hintText: 'Enter the name of the fete.',
                    labelText: 'Name',
                  ),
                  controller: _nameController,
                  validator: (val) =>
                      FeteFormValidators._validateNotEmpty(val, 'name'),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.description),
                    hintText: 'Enter a description or summary of the fete.',
                    labelText: 'Description',
                  ),
                  controller: _descController,
                  validator: (val) =>
                      FeteFormValidators._validateNotEmpty(val, 'description'),
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  maxLength: 128,
                  maxLengthEnforced: true,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          icon: const Icon(Icons.event),
                          hintText: 'yyyy-mm-dd',
                          labelText: 'Fete Date',
                        ),
                        keyboardType: TextInputType.datetime,
                        controller: _dateController,
                        validator: (val) =>
                            FeteFormValidators.validateDate(val),
                      ),
                    ),
                    IconButton(
                      icon: new Icon(Icons.more_horiz),
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
                            _dateController.text =
                                DateFormat.yMMMd('en_GB').format(selectedDate);
                          });
                        }
                      }),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          icon: const Icon(Icons.access_time),
                          hintText: 'Enter the time of the fete.',
                          labelText: 'Fete Time',
                        ),
                        controller: _timeController,
                        keyboardType: TextInputType.datetime,
                        validator: (val) =>
                            FeteFormValidators._validateTime(val),
                      ),
                    ),
                    IconButton(
                      icon: new Icon(Icons.more_horiz),
                      tooltip: 'Choose time',
                      onPressed: (() async {
                        final partyTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (partyTime != null) {
                          setState(() {
                            _timeController.text = partyTime.format(context);
                          });
                        }
                      }),
                    ),
                  ],
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.attach_money),
                    hintText: 'Enter the base price in TTD.',
                    labelText: 'Base Price',
                  ),
                  controller: _priceController,
                  validator: (val) => FeteFormValidators.validateBasePrice(val),
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  maxLength: 8,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.location_on),
                    hintText: 'Enter the address of the venue.',
                    labelText: 'Venue',
                  ),
                  controller: _venueController,
                  validator: (val) =>
                      FeteFormValidators._validateNotEmpty(val, 'venue'),
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  maxLength: 128,
                  maxLengthEnforced: true,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.link),
                    hintText: 'Link to more info about fete.',
                    labelText: 'Fete link',
                  ),
                  controller: _linkController,
                  validator: (val) => FeteFormValidators._validateLink(val),
                  maxLength: 128,
                  maxLengthEnforced: true,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              FlatButton(
                child: Text('Add'),
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    AuthUtilities.getCurrentUser().then((user) {
                      // Get new fete ID.
                      final feteId = Firestore.instance
                          .collection('fetes')
                          .document()
                          .documentID;

                      FirebaseStorage.instance
                          .ref()
                          .child('fetes')
                          .child(feteId)
                          .child('poster')
                          .putFile(File(_fileController.text))
                          .onComplete
                          .then((snapshot) {
                        return snapshot.ref.getDownloadURL();
                      }).then((downloadUrl) {
                        return Firestore.instance
                            .document('fetes/$feteId')
                            .setData(<String, dynamic>{
                          'author': user.uid,
                          'base_price': double.parse(_priceController.text),
                          'issues': 0,
                          'likes': 0,
                          'link': _linkController.text,
                          'name': _nameController.text,
                          'description': _descController.text,
                          'party_time': Timestamp.fromDate(_partyTime),
                          'poster_url': downloadUrl,
                          'promoter': 'cc',
                          'status': 'draft',
                          'published': false,
                          'status_message': '',
                          'venue': _venueController.text,
                        });
                      }).then((Void) {
                        logger.fine('Fete created');
                        EventPublisher.publishEvent(
                            eventName: EventPublisher.FETE_ADD_EVENT,
                            eventParams: <String, dynamic>{
                              EventPublisher.FETE_NAME_PARAM:
                                  _nameController.text,
                              EventPublisher.FETE_ID_PARAM: feteId,
                            });
                        Navigator.of(context).pop(feteId);
                      });
                    });
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
