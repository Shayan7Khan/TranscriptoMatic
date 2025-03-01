import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transcriptomatic/services/database_service.dart';

final analysisProvider = FutureProvider.autoDispose((ref) async {
  return await DatabaseService().getAggregatedAnalysis();
});
