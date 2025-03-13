import 'dart:io';
import 'dart:async';

// Packages
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

//Screens
import 'package:transcriptomatic/screens/analytics_dashboard_screen.dart';
import 'transcription_screen.dart';

// Providers
import 'package:transcriptomatic/provider/theme_provider.dart';

import 'package:provider/provider.dart';

// Services
import 'package:transcriptomatic/services/database_service.dart';

// Widgets
import '../widgets/app_bar_widget.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of widgets for the bottom navigation bar
  static List<Widget> widgetOptions = <Widget>[
    HomeScreenContent(),
    TranscriptionScreen(),
    AnalyticsDashboard(),
  ];

// Function to handle bottom navigation bar item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex), // No AppBar here
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.transcribe),
            label: 'Transcription',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
        unselectedItemColor:
            themeProvider.isDarkMode ? Colors.white : Colors.grey[850],
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  @override
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _filePath;
  final DatabaseService _databaseService = DatabaseService();
  Timer? _timer;
  int _recordDuration = 0;
  List<Map<String, dynamic>> _recordings = [];

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initializeRecorder();
    _fetchRecordings();
  }

  // Function to fetch recordings from Supabase
  Future<void> _fetchRecordings() async {
    setState(() {
      _recordings = []; // Clear previous recordings
    });

    final List<String> audioUrls = await _databaseService.fetchAudioFiles();
    print('Fetched audio URLs: $audioUrls');

    // Filter out invalid or placeholder URLs
    List<Map<String, dynamic>> validRecordings = [];
    for (String url in audioUrls) {
      if (await _fileExists(url) && !_isPlaceholder(url)) {
        validRecordings.add({'url': url});
      } else {
        print('Invalid or placeholder URL: $url');
      }
    }

    setState(() {
      _recordings = validRecordings;
      print('Valid recordings: $_recordings');
    });
  }

// Function to check if the file exists
  Future<bool> _fileExists(String url) async {
    try {
      final request = await HttpClient().headUrl(Uri.parse(url));
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking file existence: $e');
      return false;
    }
  }

// Function to check if the URL is a placeholder
  bool _isPlaceholder(String url) {
    // Check if the URL contains '.emptyFolderPlaceholder' to identify it as a placeholder
    return url.contains('.emptyFolderPlaceholder');
  }

// Function to initialize the recorder
  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
    await Permission.microphone.request();
  }

  // Function to start the timer
  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordDuration++;
      });
    });
  }

// Function to stop the timer
  void _stopTimer() {
    _timer?.cancel();
  }

  // Function to start recording
  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = '${directory.path}/audio.aac';
    await _recorder!.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
      _recordDuration = 0; // Reset duration
    });
    _startTimer();
  }

// Function to stop recording
  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _stopTimer();
    if (_filePath != null) {
      await _uploadAudioToSupabase(_filePath!);
    }
  }

//function to upload the audio file recorded by the user to Supabase
  Future<void> _uploadAudioToSupabase(String filePath) async {
    final file = File(filePath);
    final publicURL = await _databaseService.uploadAudio(file);

    if (publicURL != null) {
      print('File uploaded successfully: $publicURL');
    } else {
      print('Error uploading file');
    }
  }

//Function to upload an audio file from the device to Supabase
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio, // Restrict selection to audio files
    );

    if (result != null) {
      File file = File(result.files.single.path!);

      // Show confirmation dialog
      bool confirmUpload = await _showConfirmationDialog(file.path);

      if (confirmUpload) {
        await _uploadAudioToSupabase(file.path);
      } else {
        print("Upload canceled by user");
      }
    } else {
      print("No file selected");
    }
  }

// Function to show confirmation dialog
  Future<bool> _showConfirmationDialog(String filePath) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Confirm Upload"),
              content: Text(
                  "Are you sure you want to upload this file?\n\n$filePath"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User cancels upload
                  },
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // User confirms upload
                  },
                  child: Text("Upload"),
                ),
              ],
            );
          },
        ) ??
        false; // Ensure it returns false if dialog is dismissed
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _recorder = null;
    _stopTimer();
    super.dispose();
  }

  // Function to format the duration in mm:ss format
  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(name: 'Home'),
      body: RefreshIndicator(
        onRefresh: _fetchRecordings,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, "Record or Upload Audio"),
                SizedBox(height: 16),
                _buildRecordAudioCard(context),
                SizedBox(height: 24),
                _buildUploadAudioCard(context),
                SizedBox(height: 24),
                _buildSectionTitle(context, "Recent Recordings"),
                SizedBox(height: 16),
                _buildRecordingList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to build the section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  // Function to build the record audio card
  Widget _buildRecordAudioCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Record Audio", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text("Tap and hold the microphone to start recording",
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onLongPress: _startRecording,
                onLongPressUp: _stopRecording,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.mic, color: Colors.white, size: 40),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                _isRecording ? _formatDuration(_recordDuration) : "00:00",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build the upload audio card
  Widget _buildUploadAudioCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upload Audio File",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text("Select an audio file from your device",
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _pickAndUploadFile,
                style: _buttonStyle(),
                child:
                    Text("Choose File", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build the recording list
  Widget _buildRecordingList() {
    return _recordings.isEmpty
        ? Center(
            child: Text(
              "No recordings found",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recordings.length,
            itemBuilder: (context, index) {
              final recording = _recordings[index];
              return Dismissible(
                key: Key(recording['url']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Recording'),
                    content:
                        Text('Are you sure you want to delete this recording?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
                onDismissed: (direction) async {
                  final success =
                      await _databaseService.deleteAudioFile(recording['url']);
                  if (success) {
                    setState(() {
                      _recordings.removeAt(index);
                    });
                    _showSuccessSnackbar('Recording deleted successfully');
                  } else {
                    _showErrorSnackbar('Failed to delete recording');
                    // Refresh the list to restore the item
                    _fetchRecordings();
                  }
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 20,
                      child:
                          Icon(Icons.audiotrack, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      "Recording ${index + 1}",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      "Swipe left to delete",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.play_circle_fill,
                          color: Colors.blueAccent, size: 28),
                      onPressed: () => _playAudio(recording['url']),
                    ),
                  ),
                ),
              );
            },
          );
  }

// Function to play audio
  void _playAudio(String url) {
    final player = FlutterSoundPlayer();
    player.openPlayer();
    player.startPlayer(fromURI: url);
  }

  // Function to build keyword chip
  Widget buildRecordingItem(String title, String duration) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.mic, color: Colors.blue),
        ),
        title: Text(title, style: _boldTextStyle()),
        subtitle: Text(duration),
        trailing: IconButton(
          icon: Icon(Icons.play_arrow, color: Colors.blue),
          onPressed: () {},
        ),
      ),
    );
  }

// Function to build the button style
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    );
  }

  TextStyle _boldTextStyle() {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
  }
}
