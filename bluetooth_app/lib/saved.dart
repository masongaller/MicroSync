import 'dart:io';
import 'dart:ui';
import 'package:bluetooth_app/shareddata.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MySavedPage extends StatefulWidget {
  final Function(int) onChangeIndex;
  const MySavedPage({super.key, required this.onChangeIndex});

  @override
  State<MySavedPage> createState() => _MySavedPageState();
}

class _MySavedPageState extends State<MySavedPage> {
  List<File> files = [];

  late TutorialCoachMark tutorialCoachMark;
  GlobalKey savedKey = GlobalKey();
  bool _isThemeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFiles();
    // Ensure the theme is initialized only once
    if (!_isThemeInitialized) {
      // Access the theme and create tutorial only when dependencies change
      createTutorial();
      _isThemeInitialized = true;
    }
  }

  void showTutorial(BuildContext context) {
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Must have at least 1 saved file to show tutorial'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      tutorialCoachMark.show(context: context);
    }
  }

  void createTutorial() {
    ThemeData theme = Theme.of(context);
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(theme),
      colorShadow: Theme.of(context).shadowColor,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.5,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onSkip: () {
        return true;
      },
    );
  }

  List<TargetFocus> _createTargets(ThemeData theme) {
    List<TargetFocus> targets = [];

    targets.add(TargetFocus(
      identify: "Scan Button",
      keyTarget: savedKey,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Saved File",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Clicking on one of the available file names will load the saved file into the table. If you swipe left or right, you can delete the file.",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));

    return targets;
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final updatedFiles = await retrieveData();
    setState(() {
      files = updatedFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final watchBLE = context.watch<SharedBluetoothData>();

    if (watchBLE.showTutorial[3]) {
      showTutorial(context);
      watchBLE.showTutorial[3] = false;
    }

    if (files.isNotEmpty) {
      return Scaffold(
        body: ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final fileName = SaveHelperMethods.extractFileName(file.path);
            final time = extractTime(file.path);
            return Dismissible(
              key: Key(file.path),
              onDismissed: (direction) {
                setState(() {
                  files.removeAt(index);
                  file.delete();
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${fileName} deleted')));
              },
              background: Container(color: Colors.red),
              child: GestureDetector(
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loading File: $fileName'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.read<SharedBluetoothData>().openedFile = file;
                  await context.read<SharedBluetoothData>().readData(file, context);
                  widget.onChangeIndex(1); //Switch to the table page
                },
                child: ListTile(
                  key: index == 0 ? savedKey : null,
                  title: Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  subtitle: Text(
                    time,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Text(
            'No Saved Files!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }
  }

  Future<List<File>> retrieveData() async {
    final directory = await getApplicationDocumentsDirectory();
    final filesInDirectory = await directory.list().toList();
    return filesInDirectory.map((entity) => File(entity.path)).toList();
  }

  String extractTime(String filePath) {
    final List<String> parts = filePath.split('\x1F');
    if (parts.length > 1) {
      final timeStringWithExtension = parts[1];
      final indexOfDot = timeStringWithExtension.lastIndexOf('.');
      final timeString = indexOfDot != -1 ? timeStringWithExtension.substring(0, indexOfDot) : timeStringWithExtension;

      // Convert timeString to DateTime
      final dateTime = DateTime.parse(timeString);

      // Format DateTime to a shorter string
      final formattedTime = '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ' +
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';

      return formattedTime;
    }
    return 'Unknown Time';
  }

  String _twoDigits(int n) {
    return n >= 10 ? '$n' : '0$n';
  }
}

class SaveHelperMethods {
  static String extractFileName(String filePath) {
    final List<String> parts = filePath.split('/');
    if (parts.isNotEmpty) {
      final fileNameWithExtension = parts.last;
      final fileNameParts = fileNameWithExtension.split('\x1F');

      // Remove the time part if it exists
      final fileName = fileNameParts.isNotEmpty ? fileNameParts.first : fileNameWithExtension;

      return fileName;
    }
    return filePath;
  }
}
