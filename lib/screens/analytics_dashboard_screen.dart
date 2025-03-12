//Packages
import 'package:flutter/material.dart';

//Widgets
import '../widgets/app_bar_widget.dart';

//Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:transcriptomatic/provider/theme_provider.dart';
import '../provider/analysis_provider.dart';

class AnalyticsDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisProvider);

    return Scaffold(
      appBar: AppBarWidget(name: "Analytics Dashboard"),
      body: analysisAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (data) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, "Analytics Dashboard"),
                SizedBox(height: 16),
                _buildSummaryCards(context, data),
                SizedBox(height: 24),
                _buildSentimentAnalysis(context, data['sentiment']),
                SizedBox(height: 24),
                Center(
                    child: _buildTopKeywords(context,
                        (data['keywords'] as List<dynamic>).cast<String>())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //function to build section title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  //function to build summary cards
  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
            child: _buildSummaryCard(context, "Total Recordings",
                data['totalRecordings'].toString())),
        SizedBox(width: 16),
        Expanded(
            child: _buildSummaryCard(context, "Hours Analyzed",
                data['totalHours'].toStringAsFixed(1))),
      ],
    );
  }

  //function to build summary card
  Widget _buildSummaryCard(BuildContext context, String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //function to build sentiment analysis
  Widget _buildSentimentAnalysis(BuildContext context, dynamic sentimentData) {
    // Convert the sentiment data to proper type
    final Map<String, double> sentiment = Map<String, double>.from(
        (sentimentData as Map).map((key, value) =>
            MapEntry(key.toString(), (value as num).toDouble())));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sentiment Analysis",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSentimentIndicator(
                  context,
                  "Positive",
                  sentiment['positive']?.toInt() ?? 0,
                  Colors.green,
                ),
                _buildSentimentIndicator(
                  context,
                  "Neutral",
                  sentiment['neutral']?.toInt() ?? 0,
                  Colors.orange,
                ),
                _buildSentimentIndicator(
                  context,
                  "Negative",
                  sentiment['negative']?.toInt() ?? 0,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //function to build sentiment indicator
  Widget _buildSentimentIndicator(
    BuildContext context,
    String label,
    int percentage,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          "$percentage%",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  //function to build top keywords
  Widget _buildTopKeywords(BuildContext context, List<String> keywords) {
    print('Keywords data: $keywords'); // Debug statement
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Top Keywords", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keywords
                  .take(5)
                  .map((keyword) => _buildKeywordChip(context, keyword))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  //function to build keyword chip
  Widget _buildKeywordChip(BuildContext context, String keyword) {
    final themeProvider =
        legacy_provider.Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.blue.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        keyword,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.blue,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
