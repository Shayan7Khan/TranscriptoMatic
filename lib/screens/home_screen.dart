//Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//Providers
import 'package:transcriptomatic/provider/theme_provider.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Access themeProvider inside the build method
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Record or Upload Audio"),
              SizedBox(height: 16),
              _buildRecordAudioCard(),
              SizedBox(height: 24),
              _buildUploadAudioCard(),
              SizedBox(height: 24),
              _buildSectionTitle("Recent Recordings"),
              SizedBox(height: 16),
              _buildRecordingList(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeProvider themeProvider) {
    return AppBar(
      title: Text("Audio"),
      actions: [
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge, // Replaces headline6
    );
  }

  Widget _buildRecordAudioCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Record Audio",
              style: Theme.of(context).textTheme.titleLarge,
            ), // Replaces headline6
            SizedBox(height: 8),
            Text(
              "Tap and hold the microphone to start recording",
              style:
                  Theme.of(context).textTheme.titleMedium, // Replaces subtitle1
            ),
            SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onLongPress: () {
                  // Start recording logic
                },
                onLongPressUp: () {
                  // Stop recording logic
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
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
            Center(child: Text("00:00", style: _boldTextStyle())),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadAudioCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upload Audio File",
              style: Theme.of(context).textTheme.titleLarge,
            ), // Replaces headline6
            SizedBox(height: 8),
            Text(
              "Select an audio file from your device",
              style:
                  Theme.of(context).textTheme.titleMedium, // Replaces subtitle1
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // File picker logic
                },
                style: _buttonStyle(),
                child: Text(
                  "Choose File",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => SizedBox(height: 0),
      itemBuilder: (context, index) {
        return _buildRecordingItem("Recording ${index + 1}", "${index + 1}:30");
      },
    );
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
          onPressed: () {
            // Play recording logic
          },
        ),
        onTap: () {
          // Navigate to recording details
        },
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
