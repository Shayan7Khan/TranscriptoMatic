// Packages
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:transcriptomatic/provider/theme_provider.dart';

// Services
import '../services/navigation_service.dart';

class TranscriptionPage extends StatefulWidget {
  final String audioId;

  TranscriptionPage({required this.audioId});

  @override
  _TranscriptionPageState createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  bool _isProcessing = false;
  bool _showSpeakerDetection = false;
  bool _showTimestamps = false;
  bool _showTranscribedText = false;
  String _transcribedText = "";

  void _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _showTranscribedText = false;
    });

    // Simulate processing (will replace it with Firebase logic)
    await _fetchAndProcessAudio(widget.audioId);

    setState(() {
      _isProcessing = false;
      //to show the transcribed text after processing
      _showTranscribedText = true;
    });
  }

  Future<void> _fetchAndProcessAudio(String audioId) async {
    // Simulate transcription
    await Future.delayed(Duration(seconds: 5)); // Simulate processing delay
    setState(() {
      _transcribedText =
          "Welcome everyone to today's meeting.\n\n"
          "Thank you for the introduction. I've\n"
          "prepared a detailed analysis of our\n"
          "revenue trends over the past quarter.\n\n"
          "Excellent. Let's start with the revenue.";
    });
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Transcription Settings"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingOption(
                    "Speaker Detection",
                    _showSpeakerDetection,
                    (value) {
                      setState(() {
                        _showSpeakerDetection = value; // Update state
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildSettingOption("Timestamps", _showTimestamps, (value) {
                    setState(() {
                      _showTimestamps = value; // Update state
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSettingOption(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(context, themeProvider),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, "Current Transcription"),
              SizedBox(height: 16),
              if (_isProcessing) _buildProcessingIndicator(context),
              SizedBox(height: 24),
              if (_showTranscribedText)
                Center(child: _buildTranscribedTextSection(context)),
              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _startProcessing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Start Processing",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return AppBar(
      title: Text("Transcription"),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          // back to the Home Page
        },
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            _showSettingsDialog(context);
          },
        ),
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge, // Replaces headline6
    );
  }

  Widget _buildProcessingIndicator(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Processing audio...",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              value: _isProcessing ? null : 0, // Static when not processing
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                "00:45",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscribedTextSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Transcribed Text",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Text(
              _transcribedText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
