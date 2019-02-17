import 'package:carnival_compass_mobile/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger logger = Logger("feedback_add");

class AddFeedback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Feedback'),
      ),
      body: FeedbackForm(),
    );
  }
}

class FeedbackForm extends StatefulWidget {
  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();

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
                    hintText: 'App feedback...',
                    labelText: 'Feedback',
                  ),
                  controller: _contentController,
                  validator: (val) =>
                      val.isEmpty ? 'Feedback can\'t be empty' : null,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  maxLength: 256,
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
                      child: Text('Submit'),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          final user = await AuthUtilities.getCurrentUser();
                          Firestore.instance
                              .collection('feedback')
                              .document()
                              .setData(
                            <String, dynamic>{
                              'author': user.uid,
                              'content': _contentController.text,
                              'timestamp': FieldValue.serverTimestamp()
                            },
                          ).then((Void) {
                            logger.fine('Feedback created');
                            EventPublisher.publishEvent(
                                eventName: EventPublisher.FEEDBACK_EVENT);
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
