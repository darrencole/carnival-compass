import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:carnival_compass_mobile/utilities.dart';

class CarnivalCompassAbout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget _detailLine(Widget content) {
      return Container(
        padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
        child: content,
      );
    }

    Widget _appSection(PackageInfo packageInfo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/cc_logo.png',
            fit: BoxFit.cover,
          ),
          _detailLine(
            Text(
              '${packageInfo.appName}',
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          _detailLine(
            Text('Version: ${packageInfo.version}'),
          ),
          // TODO: update before release.
          _detailLine(
            Text('Last Updated: 8/1/2019'),
          ),
        ],
      );
    }

    Widget _poweredBySection = Container(
      padding: EdgeInsets.fromLTRB(0.0, 60.0, 0.0, 0.0),
      child: Align(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Powered by:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0),
                  child: Image.asset(
                    'assets/scl_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Text(
                  'Signature Coding Ltd.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: FutureBuilder(
        future: PackageInfoUtilities.getPackageInfo(),
        builder: (_, AsyncSnapshot<PackageInfo> snapshot) {
          if (snapshot.hasData) {
            PackageInfo _packageInfo = snapshot.data;
            return Container(
              padding: const EdgeInsets.all(32.0),
              child: ListView(
                children: <Widget>[
                  _appSection(_packageInfo),
                  _poweredBySection,
                ],
              ),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
