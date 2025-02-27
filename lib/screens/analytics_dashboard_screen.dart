// Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'package:transcriptomatic/provider/theme_provider.dart';

//Widgets
import '../widgets/app_bar_widget.dart';

class AnalyticsDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(name: "Analytics Dashboard"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, "Analytics Dashboard"),
              SizedBox(height: 16),
              _buildSummaryCards(context),
              SizedBox(height: 24),
              _buildSentimentAnalysis(context),
              SizedBox(height: 24),
              Center(child: _buildTopKeywords(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge, // Replaces headline6
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(context, "Total Recordings", "156")),
        SizedBox(width: 16),
        Expanded(child: _buildSummaryCard(context, "Hours Analyzed", "42.5")),
      ],
    );
  }

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

  Widget _buildSentimentAnalysis(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sentiment Analysis",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSentimentIndicator(context, "Positive", 45, Colors.green),
                _buildSentimentIndicator(context, "Neutral", 35, Colors.orange),
                _buildSentimentIndicator(context, "Negative", 20, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildTopKeywords(BuildContext context) {
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
              children: [
                _buildKeywordChip(context, "Reading (1.5)"),
                _buildKeywordChip(context, "Reading (2.5)"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordChip(BuildContext context, String keyword) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16), // Rounded corners
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
              color: isDarkMode
                  ? Colors.white
                  : Colors.blue, // Text color based on theme
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
