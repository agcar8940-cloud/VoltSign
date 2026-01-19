import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const VoltSignApp());

class VoltSignApp extends StatelessWidget {
  const VoltSignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.dark),
      home: VoltMainScreen(),
    );
  }
}

class VoltMainScreen extends StatefulWidget {
  const VoltMainScreen({super.key});

  @override
  State<VoltMainScreen> createState() => _VoltMainScreenState();
}

class _VoltMainScreenState extends State<VoltMainScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        height: 65.0,
        iconSize: 23.0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_stack_3d_up),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.folder),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            if (index == 0) return const AppsPage();
            if (index == 1) return const FilesPage();
            return const SettingsPage();
          },
        );
      },
    );
  }
}

// --- APPS & SETTINGS (Placeholders) ---
class AppsPage extends StatelessWidget {
  const AppsPage({super.key});
  @override
  Widget build(BuildContext context) => const CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: Text('My Apps')),
    child: Center(child: Text('No apps signed yet.')),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => const CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: Text('Settings')),
    child: Center(child: Text('Settings content here.')),
  );
}

// --- FILES PAGE (Corrected Logic) ---
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<FileSystemEntity> files = [];
  bool isSelectionMode = false;
  Set<String> selectedPaths = {};

  @override
  void initState() {
    super.initState();
    _refreshFiles();
  }

  // FIXED: The method now works correctly with path_provider
  Future<void> _refreshFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    if (await dir.exists()) {
      setState(() {
        files = dir.listSync();
      });
    }
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('File Operations'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createNewFolder();
            },
            child: const Text('New Folder'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _importFile();
            },
            child: const Text('Import File'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: !isSelectionMode,
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isSelectionMode = !isSelectionMode;
                selectedPaths.clear();
              });
            },
            child: Text(isSelectionMode ? 'Exit Selection' : 'Select Files'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _createNewFolder() async {
    final dir = await getApplicationDocumentsDirectory();
    final newDir = Directory(
      '${dir.path}/Folder_${DateTime.now().millisecondsSinceEpoch}',
    );
    await newDir.create();
    _refreshFiles();
  }

  Future<void> _importFile() async {
    // FIXED: Correct usage of FilePickerResult
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(result.files.single.path!);
      await file.copy('${dir.path}/${result.files.single.name}');
      _refreshFiles();
    }
  }

  void _deleteSelected() async {
    for (var path in selectedPaths) {
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else if (type == FileSystemEntityType.file) {
        await File(path).delete();
      }
    }
    setState(() {
      selectedPaths.clear();
      isSelectionMode = false;
    });
    _refreshFiles();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Files'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            isSelectionMode
                ? CupertinoIcons.trash
                : CupertinoIcons.ellipsis_vertical,
          ),
          onPressed: () =>
              isSelectionMode ? _deleteSelected() : _showActionSheet(context),
        ),
      ),
      child: SafeArea(
        child: files.isEmpty
            ? const Center(child: Text("No files. Use 3-dots to import."))
            : ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final item = files[index];
                  final name = item.path.split('/').last;
                  final isSelected = selectedPaths.contains(item.path);

                  return GestureDetector(
                    onTap: () {
                      if (isSelectionMode) {
                        setState(() {
                          if (isSelected)
                            selectedPaths.remove(item.path);
                          else
                            selectedPaths.add(item.path);
                        });
                      }
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item is Directory
                                ? CupertinoIcons.folder_fill
                                : CupertinoIcons.doc,
                            color: item is Directory
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 17),
                            ),
                          ),
                          if (isSelectionMode)
                            // FIXED: Using 'checkmark_circle' which is the standard icon name
                            Icon(
                              isSelected
                                  ? CupertinoIcons.checkmark_circle
                                  : CupertinoIcons.circle,
                              color: CupertinoColors.activeBlue,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
