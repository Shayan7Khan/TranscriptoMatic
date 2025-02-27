import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadAudio(File audioFile) async {
    try {
      final String fileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}${path.extension(audioFile.path)}';
      final response =
          await _client.storage.from('audio').upload(fileName, audioFile);

      if (response.isEmpty) {
        return null;
      } else {
        return _client.storage.from('audio').getPublicUrl(fileName);
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<List<String>> fetchAudioFiles() async {
    try {
      final response = await _client.storage.from('audio').list();

      if (response.isEmpty) {
        print('No audio files found.');
        return [];
      }

      // Filter out placeholder files
      final audioFiles = response
          .where((file) => file.name != '.emptyFolderPlaceholder')
          .toList();

      // Return updated audio file list
      return audioFiles.map((file) {
        return _client.storage.from('audio').getPublicUrl(file.name);
      }).toList();
    } catch (e) {
      print('Fetch error: $e');
      return [];
    }
  }
}
