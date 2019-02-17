import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger("issue_add");

class AddIssue extends StatelessWidget {
  AddIssue({@required this.feteId, @required this.feteName});

  final String feteId;
  final String feteName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Issue'),
      ),
      body: IssueForm(feteId: feteId, feteName: feteName),
    );
  }
}

class IssueForm extends StatefulWidget {
  IssueForm({this.feteId, this.feteName});

  final String feteId;
  final String feteName;

  @override
  _IssueFormState createState() => _IssueFormState();
}

class _IssueFormState extends State<IssueForm> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _descController = new TextEditingController();

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
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.description),
                    hintText: 'Describe the issue with fete.',
                    labelText: 'Description',
                  ),
                  controller: _descController,
                  validator: (val) =>
                      val.isEmpty ? 'Issue must have a description' : null,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  maxLength: 128,
                  maxLengthEnforced: true,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop<bool>(context, false);
                      },
                    ),
                    FlatButton(
                      child: Text('Add'),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          Firestore.instance
                              .collection('fete_issues')
                              .document()
                              .setData(
                            <String, dynamic>{
                              'fete_name': widget.feteName,
                              'description': _descController.text,
                              'timestamp': FieldValue.serverTimestamp(),
                              'status': 'open'
                            },
                          ).then((Void) {
                            logger.fine('Issue created');
                            EventPublisher.publishEvent(
                              eventName: EventPublisher.FETE_ADD_ISSUE_EVENT,
                              eventParams: <String, dynamic>{
                                EventPublisher.FETE_NAME_PARAM: widget.feteName,
                                EventPublisher.FETE_ID_PARAM: widget.feteId,
                              },
                            );
                            Navigator.pop<bool>(context, true);
                          });
                        } else {
                          logger.warning(
                              'Form not filled in correctly. User must try again.');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
