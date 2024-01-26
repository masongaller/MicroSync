import 'package:flutter/material.dart';

class MySettingsPage extends StatefulWidget {
  const MySettingsPage({super.key});
  @override
  State<MySettingsPage> createState() => _MySettingsPageState();
}

class _MySettingsPageState extends State<MySettingsPage> with AutomaticKeepAliveClientMixin<MySettingsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have clicked the button this many times:',
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}