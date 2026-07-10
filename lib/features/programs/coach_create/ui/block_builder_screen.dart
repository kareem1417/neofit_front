import 'package:flutter/material.dart';

import '../models/program_builder_data.dart';
import 'session_builder_screen.dart';
import 'show_program_details_before_publish_screen.dart';

class BlockBuilderScreen extends StatefulWidget {
  final ProgramBuilderData programData;

  const BlockBuilderScreen({
    super.key,
    required this.programData,
  });

  @override
  State<BlockBuilderScreen> createState() => _BlockBuilderScreenState();
}

class _BlockBuilderScreenState extends State<BlockBuilderScreen> {
  late TextEditingController _blockNameController;

  @override
  void initState() {
    super.initState();
    _blockNameController = TextEditingController();

    if (widget.programData.blocks.isEmpty) {
      widget.programData.blocks = [
        ProgramBlockData(title: 'ACCUMULATION PHASE', weekStart: 1, weekEnd: 2),
        ProgramBlockData(title: 'INTENSIFICATION', weekStart: 3, weekEnd: 4),
        ProgramBlockData(title: 'PEAKING BLOCK', weekStart: 5, weekEnd: 6),
      ];
    }
  }

  @override
  void dispose() {
    _blockNameController.dispose();
    super.dispose();
  }

  void _addBlock() {
    final name = _blockNameController.text.trim();

    if (name.isEmpty) return;

    final lastWeek = widget.programData.blocks.isEmpty
        ? 0
        : widget.programData.blocks.last.weekEnd;

    setState(() {
      widget.programData.blocks.add(
        ProgramBlockData(
          title: name.toUpperCase(),
          weekStart: lastWeek + 1,
          weekEnd: lastWeek + 2,
        ),
      );
      _blockNameController.clear();
    });
  }

  void _confirmDeleteBlock(int index) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Block',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Do you want to delete the block?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'No',
                style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => widget.programData.blocks.removeAt(index));
                Navigator.pop(context);
              },
              child: const Text(
                'Yes',
                style: TextStyle(
                  color: Color(0xFF1CE0BF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B0D);
    const accentTeal = Color(0xFF1CE0BF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'CREATE PROGRAM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Text(
                    'STEP 2/3',
                    style: TextStyle(
                      color: accentTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                Container(
                  height: 2,
                  width: MediaQuery.of(context).size.width * 0.66,
                  color: accentTeal,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'PROGRAM BLOCKS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Divide your program into phases. Each block contains sessions and exercises.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.programData.blocks.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildBlockCard(
                            widget.programData.blocks[index],
                            index,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildAddBlockButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowProgramDetailsBeforePublishScreen(
                        programData: widget.programData,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: accentTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SHOW PROGRAM DETAILS',
                        style: TextStyle(
                          color: Color(0xFF070B0D),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF070B0D),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockCard(ProgramBlockData block, int index) {
    const surfaceColor = Color(0xFF0F1115);
    const borderColor = Color(0xFF1E2127);
    const accentTeal = Color(0xFF1CE0BF);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionBuilderScreen(
              programData: widget.programData,
              blockIndex: index,
            ),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.layers_outlined,
                color: accentTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${block.weeks} • ${block.sessions.length} SESSIONS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.18),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white24,
                size: 20,
              ),
              onPressed: () => _confirmDeleteBlock(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBlockButton() {
    const accentTeal = Color(0xFF1CE0BF);

    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: CustomPaint(
        painter: DashedRectPainter(
          color: Colors.white.withValues(alpha: 0.1),
          strokeWidth: 1.5,
          gap: 6,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _blockNameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ADD NEW BLOCK',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.1),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addBlock(),
                ),
              ),
              GestureDetector(
                onTap: _addBlock,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: accentTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF070B0D),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    const radius = 24.0;
    path.addRRect(
      RRect.fromLTRBR(
          0, 0, size.width, size.height, const Radius.circular(radius)),
    );

    final dashPath = Path();
    const dashWidth = 10.0;
    final dashSpace = gap;
    var distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedRectPainter oldDelegate) => false;
}
