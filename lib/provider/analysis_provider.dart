import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final analysisStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  // Use broadcast stream to allow multiple listeners
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  final databaseService = DatabaseService();
  Timer? timer;

  // Initial load
  _loadData(databaseService, controller);

  // Set up periodic refresh
  timer = Timer.periodic(const Duration(seconds: 2), (_) {
    if (!controller.isClosed) {
      _loadData(databaseService, controller);
    }
  });

  // Proper cleanup
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

Future<void> _loadData(DatabaseService service,
    StreamController<Map<String, dynamic>> controller) async {
  if (controller.isClosed) return;

  try {
    final data = await service.getAggregatedAnalysis();
    if (!controller.isClosed) {
      controller.add(data);
    }
  } catch (e) {
    print('Error loading analysis data: $e');
    if (!controller.isClosed) {
      controller.addError(e);
    }
  }
}

// Keep the old provider reference for backward compatibility
final analysisProvider = analysisStreamProvider;
