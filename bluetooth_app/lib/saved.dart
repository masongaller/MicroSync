import 'dart:io';
import 'package:bluetooth_app/shareddata.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class MySavedPage extends StatefulWidget {
  final Function(int) onChangeIndex;
  const MySavedPage({super.key, required this.onChangeIndex});

  @override
  State<MySavedPage> createState() => _MySavedPageState();
}

class _MySavedPageState extends State<MySavedPage> {
  List<File> files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (files.isNotEmpty) {
      return Scaffold(
        body: ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final fileName = extractFileName(file.path);
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Loading File: $fileName'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  context.read<SharedBluetoothData>().readData(file);
                  widget.onChangeIndex(1); //Switch to the table page
                },
                child: ListTile(
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

  String extractFileName(String filePath) {
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
