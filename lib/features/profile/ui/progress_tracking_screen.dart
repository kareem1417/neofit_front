import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../programs/data/programs_service.dart';

class ProgressModel {
  final String testName;
  final String unit;
  final bool higherIsBetter;
  final List<ProgressPoint> dataPoints;

  const ProgressModel({
    required this.testName,
    required this.unit,
    required this.higherIsBetter,
    required this.dataPoints,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      testName: json['test_name']?.toString() ?? 'Test',
      unit: json['unit']?.toString() ?? '',
      higherIsBetter: json['higher_is_better'] == true,
      dataPoints: (json['data_points'] as List<dynamic>? ?? [])
          .map((e) => ProgressPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  ProgressPoint? get baseline {
    if (dataPoints.isEmpty) return null;
    return dataPoints.first;
  }

  ProgressPoint? get current {
    if (dataPoints.isEmpty) return null;
    return dataPoints.last;
  }

  double get improvement {
    final first = baseline;
    final last = current;

    if (first == null || last == null) return 0;

    return last.rawValue - first.rawValue;
  }
}

class ProgressPoint {
  final DateTime? date;
  final double rawValue;
  final String snapshotType;
  final int percentile;

  const ProgressPoint({
    this.date,
    required this.rawValue,
    required this.snapshotType,
    required this.percentile,
  });

  factory ProgressPoint.fromJson(Map<String, dynamic> json) {
    return ProgressPoint(
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      rawValue: double.tryParse(json['raw_value']?.toString() ?? '') ?? 0,
      snapshotType: json['snapshot_type']?.toString() ?? '',
      percentile: int.tryParse(json['percentile']?.toString() ?? '') ?? 0,
    );
  }
}

class ProgressTrackingScreen extends StatefulWidget {
  final int? initialAttributeTestId;
  final List<Map<String, dynamic>>? availableTests;

  const ProgressTrackingScreen({
    super.key,
    this.initialAttributeTestId,
    this.availableTests,
  });

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  static const Color bgColor = Color(0xFF09090B);
  static const Color primaryCyan = Color(0xFF2DE1C2);
  static const Color textGrey = Color(0xFF8A8A8E);
  static const Color cardBg = Color(0xFF141415);

  late final ProgramsService _service;

  List<Map<String, dynamic>> _tests = [];
  int? _selectedTestId;
  Future<ProgressModel>? _progressFuture;

  Future<ProgressModel> _getProgress(int testId) async {
    final data = await _service.getProgressData(testId);
    return ProgressModel.fromJson(data);
  }

  @override
  void initState() {
    super.initState();

    _service = ProgramsService(apiClient: context.read<ApiClient>());
    _tests = widget.availableTests ?? [];

    _selectedTestId = widget.initialAttributeTestId ??
        (_tests.isNotEmpty
            ? int.tryParse(_tests.first['attribute_test_id']?.toString() ??
                _tests.first['id']?.toString() ??
                '')
            : null);

    if (_selectedTestId != null) {
      _progressFuture = _getProgress(_selectedTestId!);
    }
  }

  void _loadProgress(int testId) {
    setState(() {
      _selectedTestId = testId;
      _progressFuture = _getProgress(testId);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _progressFuture == null
                  ? _buildNoTestState()
                  : FutureBuilder<ProgressModel>(
                      future: _progressFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: primaryCyan,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildError(snapshot.error.toString());
                        }

                        final progress = snapshot.data!;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTestSelector(progress),
                              const SizedBox(height: 24),
                              _buildChartCard(progress),
                              const SizedBox(height: 24),
                              _buildStats(progress),
                              const SizedBox(height: 24),
                              _buildSnapshots(progress),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'YOUR PROGRESS 📈',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNoTestState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No tests available yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load progress',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSelector(ProgressModel progress) {
    if (_tests.isEmpty) {
      return _infoCard(
        child: Row(
          children: [
            const Text(
              'Test',
              style: TextStyle(color: textGrey),
            ),
            const Spacer(),
            Text(
              progress.testName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedTestId,
      dropdownColor: cardBg,
      decoration: InputDecoration(
        labelText: 'Test',
        labelStyle: const TextStyle(color: textGrey),
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      items: _tests
          .map((test) {
            final id = int.tryParse(
              test['attribute_test_id']?.toString() ??
                  test['id']?.toString() ??
                  '',
            );

            final name = test['test_name']?.toString() ??
                test['name']?.toString() ??
                'Test';

            return DropdownMenuItem<int>(
              value: id,
              child: Text(name),
            );
          })
          .where((item) => item.value != null)
          .toList(),
      onChanged: (id) {
        if (id != null) _loadProgress(id);
      },
    );
  }

  Widget _buildChartCard(ProgressModel progress) {
    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: CustomPaint(
        painter: _ProgressChartPainter(
          points: progress.dataPoints,
          color: primaryCyan,
          unit: progress.unit,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildStats(ProgressModel progress) {
    final baseline = progress.baseline;
    final current = progress.current;

    final improvement = progress.improvement;
    final sign = improvement >= 0 ? '+' : '';

    final baselinePercent = baseline?.percentile ?? 0;
    final currentPercent = current?.percentile ?? 0;

    return _infoCard(
      child: Column(
        children: [
          _statRow(
            'Baseline',
            baseline == null
                ? '--'
                : '${baseline.rawValue.toStringAsFixed(1)} ${progress.unit}',
          ),
          _statRow(
            'Current',
            current == null
                ? '--'
                : '${current.rawValue.toStringAsFixed(1)} ${progress.unit} ($sign${improvement.toStringAsFixed(1)})',
            valueColor: improvement >= 0 ? primaryCyan : Colors.redAccent,
          ),
          _statRow(
            'Percentile',
            '$baselinePercent% → $currentPercent%',
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshots(ProgressModel progress) {
    final points = progress.dataPoints.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT SNAPSHOTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        ...points.map((point) {
          final baseline = progress.baseline;
          final delta =
              baseline == null ? 0 : point.rawValue - baseline.rawValue;

          final isBaseline = point == progress.baseline;
          final sign = delta >= 0 ? '+' : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(
                  isBaseline
                      ? Icons.circle_outlined
                      : delta >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                  color: isBaseline
                      ? Colors.white38
                      : delta >= 0
                          ? primaryCyan
                          : Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isBaseline
                        ? '${_formatDate(point.date)}: Baseline'
                        : '${_formatDate(point.date)}: $sign${delta.toStringAsFixed(1)} ${progress.unit}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${point.percentile}%',
                  style: const TextStyle(
                    color: textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _statRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  final List<ProgressPoint> points;
  final Color color;
  final String unit;

  _ProgressChartPainter({
    required this.points,
    required this.color,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const leftPadding = 46.0;
    const bottomPadding = 30.0;
    const topPadding = 18.0;
    const rightPadding = 12.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final origin = Offset(leftPadding, size.height - bottomPadding);

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      origin,
      axisPaint,
    );
    canvas.drawLine(
      origin,
      Offset(size.width - rightPadding, origin.dy),
      axisPaint,
    );

    if (points.isEmpty) return;

    final values = points.map((e) => e.rawValue).toList();
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = max(maxValue - minValue, 1);

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = leftPadding +
          (points.length == 1
              ? chartWidth / 2
              : chartWidth * i / (points.length - 1));

      final normalized = (points[i].rawValue - minValue) / range;
      final y = origin.dy - normalized * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 5, dotPaint);

      final label = points[i].date == null
          ? ''
          : '${points[i].date!.month}/${points[i].date!.day}';

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, origin.dy + 8),
      );
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < 4; i++) {
      final value = minValue + (range * i / 3);
      final y = origin.dy - chartHeight * i / 3;

      textPainter.text = TextSpan(
        text: '${value.toStringAsFixed(0)}$unit',
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        axisPaint..color = Colors.white.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) => true;
}
