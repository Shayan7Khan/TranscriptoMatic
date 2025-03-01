import 'dart:io';

//Packages
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

//Services
import '../services/database_service.dart';

//Widgets
import '../widgets/app_bar_widget.dart';

//Pages
import 'analytics_dashboard_screen.dart';

class TranscriptionScreen extends StatefulWidget {
  @override
  _TranscriptionScreenState createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  final DatabaseService _databaseService = DatabaseService();

  List<String> _audioFiles = [];
  String? _selectedAudioUrl;
  String? _transcription;
  bool _isLoading = false;
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _fetchAudioFiles();
  }

  Future<void> _fetchAudioFiles() async {
    setState(() => _isLoading = true);
    try {
      List<String> files = await _databaseService.fetchAudioFiles();
      print('Fetched audio URLs: $files');

      List<String> validFiles = [];
      for (String url in files) {
        if (await _fileExists(url) && !_isPlaceholder(url)) {
          validFiles.add(url);
        } else {
          print('Invalid or placeholder URL: $url');
        }
      }

      setState(() => _audioFiles = validFiles);
      print('Valid audio files: $_audioFiles');
    } catch (e) {
      _showErrorSnackbar("Error fetching audio files: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  bool _isPlaceholder(String url) {
    // Check if the URL contains '.emptyFolderPlaceholder' to identify it as a placeholder
    return url.contains('.emptyFolderPlaceholder');
  }

  Future<void> _transcribeAudio() async {
    if (_selectedAudioUrl == null) return;

    setState(() {
      _isTranscribing = true;
      _transcription = null;
    });

    try {
      String? result =
          await _databaseService.transcribeAudioFromUrl(_selectedAudioUrl!);
      if (result != null && !result.contains("429")) {
        setState(() {
          _transcription = result;
        });
      } else {
        setState(() {
          _transcription = result != null && result.contains("429")
              ? "Rate limit exceeded. Try again later."
              : result;
        });
      }
    } catch (e) {
      _showErrorSnackbar("Error transcribing audio: $e");
    } finally {
      setState(() => _isTranscribing = false);
    }
  }

  Future<void> _saveAsPdf() async {
    if (_transcription == null || _transcription!.isEmpty) return;

    try {
      final pdfFile =
          await _databaseService.saveTranscriptionAsPdf(_transcription!);
      if (pdfFile != null) {
        OpenFile.open(pdfFile.path);
        _showSuccessSnackbar("Transcription saved successfully!");
      }
    } catch (e) {
      _showErrorSnackbar("Error saving PDF: $e");
    }
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBarWidget(name: 'Audio Transcription'),
      body: RefreshIndicator(
        onRefresh: _fetchAudioFiles,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Audio Files", theme),
              SizedBox(height: 16),
              _buildAudioList(theme, isDarkMode),
              SizedBox(height: 24),
              _buildSectionTitle("Transcription", theme),
              SizedBox(height: 16),
              _buildTranscriptionSection(theme, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildAudioList(ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? theme.colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                  ))
                : Container(
                    height: 200, // Set a fixed height for the audio list
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: _audioFiles.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) =>
                          _buildAudioItem(index, theme),
                    ),
                  ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.translate, color: Colors.white),
              label: Text("Start Transcription",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              onPressed: _selectedAudioUrl != null && !_isTranscribing
                  ? _transcribeAudio
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioItem(int index, ThemeData theme) {
    final audioUrl = _audioFiles[index];
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.blueAccent,
        radius: 20,
        child: Icon(Icons.audiotrack, color: Colors.white, size: 20),
      ),
      title: Text(
        "Recording ${index + 1}",
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      subtitle: Text(
        "Tap to select",
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: _selectedAudioUrl == audioUrl
          ? Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () => setState(() => _selectedAudioUrl = audioUrl),
      tileColor: _selectedAudioUrl == audioUrl
          ? theme.colorScheme.primary.withOpacity(0.05)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildTranscriptionSection(ThemeData theme, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? theme.colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_transcription != null)
                  ElevatedButton.icon(
                    icon: Icon(Icons.save_alt, size: 20, color: Colors.white),
                    label: Text("Export PDF",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _saveAsPdf,
                  ),
                if (_transcription != null)
                  ElevatedButton.icon(
                    icon: Icon(Icons.insights, color: Colors.white),
                    label: Text("View Analysis"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnalyticsDashboard()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.colorScheme.surface : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: SingleChildScrollView(
                child: _isTranscribing
                    ? Center(
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blue),
                          SizedBox(height: 16),
                          Text("Processing audio...",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              )),
                        ],
                      ))
                    : Text(
                        _transcription ?? "No transcription available",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
