import 'package:flutter/material.dart';

class MySavedPage extends StatefulWidget {
  const MySavedPage({super.key});
  @override
  State<MySavedPage> createState() => _MySavedPageState();
}

class _MySavedPageState extends State<MySavedPage> with AutomaticKeepAliveClientMixin<MySavedPage> {

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
  bool get wantKeepAlive => true;
}