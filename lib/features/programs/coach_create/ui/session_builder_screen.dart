import 'package:flutter/material.dart';

import '../models/program_builder_data.dart';
import 'exercise_builder_screen.dart';
import 'block_builder_screen.dart';

class SessionBuilderScreen extends StatefulWidget {
  final ProgramBuilderData programData;
  final int blockIndex;

  const SessionBuilderScreen({
    super.key,
    required this.programData,
    required this.blockIndex,
  });

  @override
  State<SessionBuilderScreen> createState() => _SessionBuilderScreenState();
}

class _SessionBuilderScreenState extends State<SessionBuilderScreen> {
  late TextEditingController _sessionNameController;

  ProgramBlockData get block => widget.programData.blocks[widget.blockIndex];

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController();

    if (block.sessions.isEmpty) {
      block.sessions = [
        ProgramSessionData(
          id: '01',
          title: 'LOWER BODY POWER DAY',
          focus: 'STRENGTH FOCUS',
        ),
        ProgramSessionData(
          id: '02',
          title: 'UPPER BODY VELOCITY',
          focus: 'SPEED FOCUS',
        ),
        ProgramSessionData(
          id: '03',
          title: 'CORE ROTATIONAL WORK',
          focus: 'TRANSFER FOCUS',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  void _addSession() {
    final name = _sessionNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      final newId = (block.sessions.length + 1).toString().padLeft(2, '0');
      block.sessions.add(
        ProgramSessionData(
          id: newId,
          title: name.toUpperCase(),
          focus: 'NEW SESSION',
        ),
      );
      _sessionNameController.clear();
    });
  }

  void _confirmDeleteSession(int index) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D21),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Session',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Do you want to delete this session?',
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
                setState(() {
                  block.sessions.removeAt(index);
                  for (var i = 0; i < block.sessions.length; i++) {
                    block.sessions[i].id = (i + 1).toString().padLeft(2, '0');
                  }
                });
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          block.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'MANAGE SESSIONS',
                          style: TextStyle(
                            color: accentTeal,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TRAINING DAYS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${block.sessions.length} SESSIONS DEFINED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: block.sessions.length,
                      itemBuilder: (context, index) {
                        return _buildSessionCard(block.sessions[index], index);
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'NEW SESSION NAME',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNewSessionInput(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
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
                        'SAVE & RETURN TO BLOCKS',
                        style: TextStyle(
                          color: Color(0xFF070B0D),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.check,
                        color: Color(0xFF070B0D),
                        size: 20,
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

  Widget _buildSessionCard(ProgramSessionData session, int index) {
    const surfaceColor = Color(0xFF0F1115);
    const borderColor = Color(0xFF1E2127);
    const accentTeal = Color(0xFF1CE0BF);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseBuilderScreen(
              programData: widget.programData,
              blockIndex: widget.blockIndex,
              sessionIndex: index,
            ),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(
                  session.id,
                  style: const TextStyle(
                    color: accentTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.focus} • ${session.exercises.length} EXERCISES',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.14),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: Colors.white12, size: 20),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white24,
                size: 20,
              ),
              onPressed: () => _confirmDeleteSession(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewSessionInput() {
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
                  controller: _sessionNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g., Active Recovery Drills',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.1),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addSession(),
                ),
              ),
              GestureDetector(
                onTap: _addSession,
                child: Container(
                  width: 36,
                  height: 36,
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
