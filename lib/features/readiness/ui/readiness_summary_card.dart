import 'package:flutter/material.dart';

import '../data/readiness_result.dart';

class ReadinessSummaryCard extends StatelessWidget {
  final ReadinessResult readiness;

  const ReadinessSummaryCard({
    super.key,
    required this.readiness,
  });

  Color get _statusColor {
    if (readiness.score >= 80) return const Color(0xFF22C55E);
    if (readiness.score >= 60) return const Color(0xFFFACC15);
    if (readiness.score >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final aiAdvice = readiness.aiAdvice;

    final summaryText = aiAdvice?.summary.trim().isNotEmpty == true
        ? aiAdvice!.summary
        : readiness.recommendation;

    final adviceText = aiAdvice?.advice.trim().isNotEmpty == true
        ? aiAdvice!.advice
        : readiness.recommendation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141415),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(statusColor),
          const SizedBox(height: 14),
          _buildProgress(statusColor),
          const SizedBox(height: 14),
          _buildStatus(statusColor),
          if (readiness.baseScore != null &&
              readiness.baseScore != readiness.score) ...[
            const SizedBox(height: 8),
            _buildBaseScoreNote(),
          ],
          const SizedBox(height: 14),
          _buildAiSummary(summaryText),
          if (aiAdvice?.explanation.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _buildTextSection(
              title: 'AI EXPLANATION',
              text: aiAdvice!.explanation,
              icon: Icons.psychology_outlined,
            ),
          ],
          const SizedBox(height: 14),
          _buildTextSection(
            title: 'RECOMMENDATION',
            text: adviceText,
            icon: Icons.tips_and_updates_outlined,
          ),
          if (readiness.intensityAdjustment != 0) ...[
            const SizedBox(height: 12),
            _buildIntensityChip(statusColor),
          ],
          if (aiAdvice?.safetyNote.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _buildSafetyNote(aiAdvice!.safetyNote),
          ],
          if (aiAdvice?.sources.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _buildSources(aiAdvice!.sources),
          ],
          if (readiness.historyContext != null) ...[
            const SizedBox(height: 14),
            _buildHistoryContext(readiness.historyContext!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Row(
      children: [
        const Icon(
          Icons.health_and_safety_outlined,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'TODAY READINESS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Text(
          '${readiness.score}/100',
          style: TextStyle(
            color: statusColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(Color statusColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: (readiness.score / 100).clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: Colors.white10,
        color: statusColor,
      ),
    );
  }

  Widget _buildStatus(Color statusColor) {
    return Text(
      readiness.status,
      style: TextStyle(
        color: statusColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildBaseScoreNote() {
    return Text(
      'Base score ${readiness.baseScore}/100 adjusted using your recent training history.',
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAiSummary(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFF2DE1C2),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection({
    required String title,
    required String text,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white38, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIntensityChip(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Intensity adjustment: ${readiness.intensityAdjustment}%',
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSafetyNote(String safetyNote) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF4444),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              safetyNote,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSources(List<String> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOURCES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sources.map((source) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                source,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHistoryContext(ReadinessHistoryContext history) {
    final items = <_HistoryItem>[
      if (history.sevenDayAverage != null)
        _HistoryItem('7-day avg', '${history.sevenDayAverage}/100'),
      if (history.yesterdayScore != null)
        _HistoryItem('Yesterday', '${history.yesterdayScore}/100'),
      if (history.previousWorkoutRpe != null)
        _HistoryItem('Last RPE', '${history.previousWorkoutRpe}/10'),
      if (history.previousWorkoutDurationMinutes != null)
        _HistoryItem(
          'Last duration',
          '${history.previousWorkoutDurationMinutes} min',
        ),
      if (history.daysSinceLastWorkout != null)
        _HistoryItem(
          'Last workout',
          '${history.daysSinceLastWorkout}d ago',
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTEXT',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                '${item.label}: ${item.value}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HistoryItem {
  final String label;
  final String value;

  const _HistoryItem(this.label, this.value);
}
