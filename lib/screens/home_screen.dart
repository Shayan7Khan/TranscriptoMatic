// Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:io';
import 'dart:async';

// Providers
import 'package:transcriptomatic/provider/theme_provider.dart';
import 'package:transcriptomatic/screens/analytics_dashboard_screen.dart';
import 'transcription_screen.dart';

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

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreenContent(),
    TranscriptionScreen(audioId: 'audioId'),
    AnalyticsDashboard(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // No AppBar here
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

  Future<void> _fetchRecordings() async {
    setState(() {
      _recordings = []; // Clear previous recordings
      print('Recordings cleared');
    });

    final List<String> audioUrls = await _databaseService.fetchAudioFiles();
    print('Fetched audio URLs: $audioUrls');

    setState(() {
      _recordings = audioUrls.map((url) => {'url': url}).toList();
      print('Updated recordings: $_recordings');
    });
  }

  Future<void> _initializeRecorder() async {
    await _recorder!.openRecorder();
    await Permission.microphone.request();
  }

  void _startTimer() {
    _recordDuration = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

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

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

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
              return Card(
                margin: EdgeInsets.symmetric(
                    vertical: 4, horizontal: 8), // Reduced padding
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4), // Less padding inside
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    radius: 20,
                    child:
                        Icon(Icons.audiotrack, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    "Recording ${index + 1}",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Tap to play",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_circle_fill,
                        color: Colors.blueAccent, size: 28),
                    onPressed: () => _playAudio(_recordings[index]['url']),
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

  Widget _buildRecordingItem(String title, String duration) {
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
