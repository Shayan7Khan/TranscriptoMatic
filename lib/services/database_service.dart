import 'dart:io';
import 'dart:collection';
import 'dart:async';
import 'dart:math' as math; // Add this import

//Packages
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

//providers
import 'package:path_provider/path_provider.dart';

//supabase
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final Dio _dio = Dio();

  // AssemblyAI Configuration (FREE TIER)
  static const _assemblyAiApiKey = "19cbd1dd7e7f47c4bc103d2fe3697c7a";
  static const _transcriptionUrl = "https://api.assemblyai.com/v2/transcript";
  static const _uploadUrl = "https://api.assemblyai.com/v2/upload";

  // Upload audio file to Supabase storage
  @pragma('vm:entry-point')
  Future<String?> uploadAudio(File audioFile) async {
    try {
      final fileName =
          'audio_${DateTime.now().millisecondsSinceEpoch}${path.extension(audioFile.path)}';
      await _client.storage.from('audio').upload(fileName, audioFile);
      return _client.storage.from('audio').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  // Fetch list of audio files from Supabase storage
  @pragma('vm:entry-point')
  Future<List<String>> fetchAudioFiles() async {
    try {
      final response = await _client.storage.from('audio').list();
      return response
          .map((file) => _client.storage.from('audio').getPublicUrl(file.name))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Transcribe audio file from URL using AssemblyAI
  @pragma('vm:entry-point')
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

      // Add these steps after getting the transcript
      final duration = await _getAudioDuration(audioFile);
      final analysis = await analyzeTranscription(transcript!);

      await saveAnalysisData({
        'audio_url': audioUrl,
        'duration': duration,
        'sentiment': analysis['sentiment'],
        'keywords': analysis['keywords']
      });

      return transcript;
    } catch (e) {
      return "Error: $e";
    }
  }

  // Get audio duration in seconds
  @pragma('vm:entry-point')
  Future<double> _getAudioDuration(File file) async {
    try {
      final player = just_audio.AudioPlayer();
      await player.setFilePath(file.path);
      final duration = await player.duration;
      return duration?.inSeconds.toDouble() ?? 0;
    } catch (e) {
      print('Duration error: $e');
      return 0;
    }
  }

  // Save transcription as PDF file
  @pragma('vm:entry-point')
  Future<File?> saveTranscriptionAsPdf(String transcription) async {
    try {
      final pdf = pw.Document();
      final titleStyle = pw.TextStyle(
        fontSize: 24,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue, // Blue color
      );
      final headerStyle = pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black, // Black color
      );
      final bodyStyle = pw.TextStyle(
        fontSize: 14,
        color: PdfColors.black, // Black color
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Transcription Report', style: titleStyle),
              pw.SizedBox(height: 16),
              pw.Text('Transcription:', style: headerStyle),
              pw.SizedBox(height: 8),
              pw.Text(transcription, style: bodyStyle),
            ],
          ),
        ),
      );

      // Get Downloads directory path
      String downloadsPath;

      if (Platform.isAndroid) {
        // For Android 10+ (API 29+), use scoped storage path
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 29) {
          downloadsPath = await AndroidPathProvider.downloadsPath;
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

  // Analyze transcription text for sentiment and keywords
  @pragma('vm:entry-point')
  Future<Map<String, dynamic>> analyzeTranscription(String text) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: "AIzaSyCq6OxQkf0HZdc80M7Y1f4xKEItS7e3Nxs",
      );

      final String sentimentPrompt = '''
      Analyze the sentiment of this transcribed text with high precision. Consider:
      
      1. Overall emotional tone and context
      2. Specific words and phrases that indicate sentiment
      3. Speaker's attitude and intention
      4. Factual vs emotional content
      
      Provide sentiment percentages that MUST add up to 100%:
      - Positive: enthusiasm, happiness, satisfaction, optimism
      - Neutral: factual statements, objective information
      - Negative: frustration, disappointment, concerns, complaints

      Format response EXACTLY as:
      positive: X%
      neutral: Y%
      negative: Z%
      
      Text for analysis:
      "${text.trim()}"
      ''';

      final sentimentResponse =
          await model.generateContent([Content.text(sentimentPrompt)]);
      final sentiment = _parseSentimentFromText(sentimentResponse.text ?? '');

      // Separate call for keywords
      final keywordPrompt = '''
      Extract the 5 most significant keywords from this transcribed text.
      Rules:
      1. ONLY use words that appear in the text
      2. Focus on nouns and important verbs that represent main topics
      3. Exclude common words (like "the", "and", "or", etc.)
      4. Order by importance to the main message
      5. Each keyword must be a single word found in the text

      Format: Return ONLY the keywords separated by commas, nothing else.
      
      Text:
      "${text.trim()}"
      ''';

      final keywordResponse =
          await model.generateContent([Content.text(keywordPrompt)]);
      final keywords = (keywordResponse.text ?? '')
          .split(',')
          .map((word) => word.trim())
          .where((word) =>
              word.isNotEmpty &&
              text.toLowerCase().contains(word.toLowerCase()))
          .take(5)
          .toList();

      print(
          'Analyzed Text: ${text.substring(0, math.min(100, text.length))}...');
      print('Generated Sentiment: $sentiment');
      print('Generated Keywords: $keywords');

      return {
        'sentiment': sentiment,
        'keywords': keywords,
      };
    } catch (e) {
      print('Analysis error: $e');
      return {
        'sentiment': {'positive': 0.0, 'neutral': 0.0, 'negative': 0.0},
        'keywords': []
      };
    }
  }

  // Parse sentiment analysis from text
  @pragma('vm:entry-point')
  Map<String, double> _parseSentimentFromText(String text) {
    final sentiment = {'positive': 0.0, 'neutral': 0.0, 'negative': 0.0};

    final positiveMatch = RegExp(r'positive:\s*(\d+)%').firstMatch(text);
    final neutralMatch = RegExp(r'neutral:\s*(\d+)%').firstMatch(text);
    final negativeMatch = RegExp(r'negative:\s*(\d+)%').firstMatch(text);

    if (positiveMatch != null) {
      sentiment['positive'] = double.parse(positiveMatch.group(1)!);
    }
    if (neutralMatch != null) {
      sentiment['neutral'] = double.parse(neutralMatch.group(1)!);
    }
    if (negativeMatch != null) {
      sentiment['negative'] = double.parse(negativeMatch.group(1)!);
    }

    return sentiment;
  }

  // Extract keywords from text
  @pragma('vm:entry-point')
  Future<List<String>> _extractKeywords(String text) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: "AIzaSyCq6OxQkf0HZdc80M7Y1f4xKEItS7e3Nxs",
      );

      final String prompt = '''
        Extract the keywords from the following text and return them in a list.
        Text: $text
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final keywords =
          response.text?.split(',').map((word) => word.trim()).toList() ?? [];

      // Clean up keywords to remove unwanted characters
      final cleanedKeywords = keywords.map((keyword) {
        return keyword.replaceAll(RegExp(r'[\[\]\(\)\{\}:,]'), '').trim();
      }).toList();

      return cleanedKeywords;
    } catch (e) {
      return [];
    }
  }

  // Parse sentiment data from dynamic input
  @pragma('vm:entry-point')
  Map<String, double> parseSentiment(dynamic sentiment) {
    try {
      if (sentiment is! Map<String, dynamic>) {
        return {
          'positive': 0.0,
          'neutral': 0.0,
          'negative': 0.0
        }; // Return default
      }

      double parseValue(dynamic value) {
        if (value is num) {
          return value.toDouble();
        }
        return 0.0; // Default to 0 if not a number
      }

      return {
        'positive': parseValue(sentiment['positive']),
        'neutral': parseValue(sentiment['neutral']),
        'negative': parseValue(sentiment['negative']),
      };
    } catch (e) {
      return {
        'positive': 0.0,
        'neutral': 0.0,
        'negative': 0.0
      }; // Return default
    }
  }

  // Parse keywords from dynamic input
  @pragma('vm:entry-point')
  List<String> parseKeywords(dynamic keywords) {
    try {
      return (keywords as List<dynamic>?)?.whereType<String>().toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  // Modified saveAnalysisData
  @pragma('vm:entry-point')
  Future<void> saveAnalysisData(Map<String, dynamic> analysis) async {
    try {
      // Generate a unique ID using timestamp and random number
      final uniqueId =
          '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';

      final sanitized = {
        'id': uniqueId,
        'audio_url': analysis['audio_url'].toString(),
        'sentiment': analysis['sentiment'] ??
            {'positive': 0.0, 'neutral': 0.0, 'negative': 0.0},
        'keywords': (analysis['keywords'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        'duration': (analysis['duration'] as num?)?.toDouble() ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Always insert as a new record
      await _client.from('analytics').insert([sanitized]);
      print('Saved analysis with ID: $uniqueId');
    } catch (e) {
      print('Error saving analysis data: $e');
    }
  }

  // Modified getAggregatedAnalysis
  @pragma('vm:entry-point')
  Future<Map<String, dynamic>> getAggregatedAnalysis() async {
    try {
      final response = await _client
          .from('analytics')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return {
          'totalRecordings': await _getTotalRecordings(),
          'totalHours': await _getTotalHours(),
          'sentiment':
              _convertToDoubleMap({'positive': 0, 'neutral': 0, 'negative': 0}),
          'keywords': []
        };
      }

      final latestAnalysis = response.first;
      print('Retrieved latest analysis: $latestAnalysis');

      // Convert sentiment values to double
      final rawSentiment = latestAnalysis['sentiment'] as Map<String, dynamic>;
      final convertedSentiment = _convertToDoubleMap(rawSentiment);

      return {
        'totalRecordings': await _getTotalRecordings(),
        'totalHours': await _getTotalHours(),
        'sentiment': convertedSentiment,
        'keywords': (latestAnalysis['keywords'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
      };
    } catch (e) {
      print('Error getting analysis: $e');
      return {
        'totalRecordings': await _getTotalRecordings(),
        'totalHours': 0.0,
        'sentiment':
            _convertToDoubleMap({'positive': 0, 'neutral': 0, 'negative': 0}),
        'keywords': []
      };
    }
  }

  // Add this helper method to ensure proper type conversion
  Map<String, double> _convertToDoubleMap(Map<String, dynamic> input) {
    return {
      'positive': (input['positive'] as num?)?.toDouble() ?? 0.0,
      'neutral': (input['neutral'] as num?)?.toDouble() ?? 0.0,
      'negative': (input['negative'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // Get total number of valid recordings from Supabase
  @pragma('vm:entry-point')
  Future<int> _getTotalRecordings() async {
    try {
      final response = await _client.storage.from('audio').list();
      final validFiles =
          response.where((file) => !_isPlaceholder(file.name)).toList();
      return validFiles.length;
    } catch (e) {
      return 0;
    }
  }

  // Check if the file is a placeholder
  @pragma('vm:entry-point')
  bool _isPlaceholder(String url) {
    // Check if the URL contains '.emptyFolderPlaceholder' to identify it as a placeholder
    return url.contains('.emptyFolderPlaceholder');
  }

  // Get total hours of audio analyzed
  @pragma('vm:entry-point')
  Future<double> _getTotalHours() async {
    try {
      final response = await _client.from('analytics').select('duration');
      print('Fetched durations: $response');

      if (response == null || response.isEmpty) {
        print('No duration records found');
        return 0.0;
      }

      // Sum up all durations (keeping in seconds)
      double totalSeconds = 0.0;
      for (var record in response) {
        if (record['duration'] != null) {
          double duration = (record['duration'] as num).toDouble();
          totalSeconds += duration;
        }
      }

      print('Total seconds calculated: $totalSeconds');
      return totalSeconds; // Return total seconds instead of converting to hours
    } catch (e) {
      print('Error calculating total duration: $e');
      return 0.0;
    }
  }

  // Modified _calculateAverageSentiment
  @pragma('vm:entry-point')
  Map<String, double> _calculateAverageSentiment(List<dynamic> data) {
    int sentimentCount = 0;
    final totals = data.fold<Map<String, double>>(
      {'positive': 0.0, 'neutral': 0.0, 'negative': 0.0},
      (sum, item) {
        final sentiment = (item['sentiment'] as Map? ?? {});
        if (sentiment.isNotEmpty) {
          sum['positive'] =
              sum['positive']! + (sentiment['positive'] as num? ?? 0);
          sum['neutral'] =
              sum['neutral']! + (sentiment['neutral'] as num? ?? 0);
          sum['negative'] =
              sum['negative']! + (sentiment['negative'] as num? ?? 0);
          sentimentCount++;
        }
        return sum;
      },
    );

    if (sentimentCount == 0) {
      return {'positive': 0.0, 'neutral': 0.0, 'negative': 0.0};
    }

    final averages = {
      'positive': (totals['positive'] ?? 0) / sentimentCount,
      'neutral': (totals['neutral']) ?? 0 / sentimentCount,
      'negative': (totals['negative'] ?? 0) / sentimentCount,
    };

    // Ensure values are within 0-100 range and are Doubles
    final normalizedAverages = {
      'positive': (averages['positive'] ?? 0).clamp(0, 100).toDouble(),
      'neutral': (averages['neutral'] ?? 0).clamp(0, 100).toDouble(),
      'negative': (averages['negative'] ?? 0).clamp(0, 100).toDouble(),
    };

    return normalizedAverages;
  }

  // 4. Add null safety to keyword processing
  @pragma('vm:entry-point')
  List<String> _getTopKeywords(List<dynamic> data) {
    final allKeywords = data
        .expand((item) => (item['keywords'] as List<dynamic>? ?? []))
        .whereType<String>()
        .map((keyword) => keyword.trim().toLowerCase())
        .toList();

    // Remove duplicates while preserving order
    final uniqueKeywords = LinkedHashSet<String>.from(allKeywords).toList();

    final keywordCounts = <String, int>{};
    for (final keyword in uniqueKeywords) {
      keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
    }

    final sortedKeywords = keywordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Clean up keywords to remove unwanted characters
    final cleanedKeywords = sortedKeywords.take(5).map((entry) {
      return entry.key.replaceAll(RegExp(r'[\[\]\(\)\{\}:,]'), '').trim();
    }).toList();

    return cleanedKeywords;
  }

  // Add this new method to delete audio and its associated data
  @pragma('vm:entry-point')
  Future<bool> deleteAudioFile(String audioUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(audioUrl);
      final fileName = uri.pathSegments.last;

      // Delete from storage
      await _client.storage.from('audio').remove([fileName]);

      // Delete associated analytics
      await _client.from('analytics').delete().eq('audio_url', audioUrl);

      print('Successfully deleted audio and analytics for: $fileName');
      return true;
    } catch (e) {
      print('Error deleting audio: $e');
      return false;
    }
  }
}
