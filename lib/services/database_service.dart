import 'dart:io';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_path_provider/android_path_provider.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final Dio _dio = Dio();

  // AssemblyAI Configuration (FREE TIER)
  static const _assemblyAiApiKey =
      "19cbd1dd7e7f47c4bc103d2fe3697c7a"; // Get from https://www.assemblyai.com/
  static const _transcriptionUrl = "https://api.assemblyai.com/v2/transcript";
  static const _uploadUrl = "https://api.assemblyai.com/v2/upload";

  // --- Supabase Audio File Management ---
  Future<String?> uploadAudio(File audioFile) async {
    try {
      final fileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}${path.extension(audioFile.path)}';
      await _client.storage.from('audio').upload(fileName, audioFile);
      return _client.storage.from('audio').getPublicUrl(fileName);
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<List<String>> fetchAudioFiles() async {
    try {
      final response = await _client.storage.from('audio').list();
      return response
          .map((file) => _client.storage.from('audio').getPublicUrl(file.name))
          .toList();
    } catch (e) {
      print('Fetch error: $e');
      return [];
    }
  }

  // --- AssemblyAI Transcription ---
  Future<String?> transcribeAudioFromUrl(String audioUrl) async {
    try {
      // 1. Download audio from Supabase URL to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFilePath =
          '${tempDir.path}/temp_audio${path.extension(audioUrl)}';
      await _dio.download(audioUrl, tempFilePath);

      // 2. Upload audio bytes to AssemblyAI
      final audioFile = File(tempFilePath);
      final uploadResponse = await _dio.post(
        _uploadUrl,
        options: Options(
          headers: {
            "authorization": _assemblyAiApiKey,
            "Content-Type": "application/octet-stream"
          },
        ),
        data: await audioFile.readAsBytes(),
      );
      final uploadUrl = uploadResponse.data['upload_url'];

      // 3. Start transcription with uploaded audio
      final transcriptionResponse = await _dio.post(
        _transcriptionUrl,
        options: Options(headers: {"authorization": _assemblyAiApiKey}),
        data: {"audio_url": uploadUrl},
      );

      // 4. Poll for transcription result (keep your existing polling logic)
      final transcriptId = transcriptionResponse.data['id'];
      String? transcript;
      while (true) {
        final statusResponse = await _dio.get(
          '$_transcriptionUrl/$transcriptId',
          options: Options(headers: {"authorization": _assemblyAiApiKey}),
        );

        if (statusResponse.data['status'] == 'completed') {
          transcript = statusResponse.data['text'];
          break;
        } else if (statusResponse.data['status'] == 'failed') {
          throw Exception("Transcription failed");
        }
        await Future.delayed(const Duration(seconds: 2));
      }

      return transcript;
    } catch (e) {
      print("Transcription error: $e");
      return "Error: $e";
    }
  }

  // --- PDF Generation ---
  // Save transcription as PDF
  Future<File?> saveTranscriptionAsPdf(String transcription) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
          pw.Page(build: (pw.Context context) => pw.Text(transcription)));

      // Get Downloads directory path
      String downloadsPath;

      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), use scoped storage path
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 29) {
          downloadsPath = await AndroidPathProvider.downloadsPath ??
              '/storage/emulated/0/Download';
        } else {
          // For Android 9 and below
          final status = await Permission.storage.request();
          if (!status.isGranted) return null;
          final externalDir = await getExternalStorageDirectory();
          downloadsPath = '${externalDir!.path}/Download';
        }
      } else {
        // For iOS/other platforms
        final dir = await getDownloadsDirectory();
        downloadsPath =
            dir?.path ?? (await getApplicationDocumentsDirectory()).path;
      }

      // Create directory if needed
      final Directory dir = Directory(downloadsPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      // Save file
      final fileName =
          'Transcription_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }
}
