import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme.dart';

// ---------------------------------------------------------------------------
// Study Timer Widget — embeddable countdown timer for study sessions.
// ---------------------------------------------------------------------------

const _kTotalStudyMinutesKey = 'total_study_minutes';

class StudyTimerWidget extends ConsumerStatefulWidget {
  const StudyTimerWidget({super.key});

  @override
  ConsumerState<StudyTimerWidget> createState() => _StudyTimerWidgetState();
}

class _StudyTimerWidgetState extends ConsumerState<StudyTimerWidget> {
  static const _presets = [5, 10, 15, 20, 30];

  int _selectedMinutes = 10;
  int _remainingSeconds = 10 * 60;
  bool _isRunning = false;
  bool _hasStarted = false;
  Timer? _timer;
  int _totalStudyMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadTotal();
  }

  Future<void> _loadTotal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _totalStudyMinutes = prefs.getInt(_kTotalStudyMinutesKey) ?? 0;
      });
    }
  }

  Future<void> _persistTotal(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kTotalStudyMinutesKey, minutes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    final total = _selectedMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  String get _formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _hasStarted = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() {
        _isRunning = true;
        _hasStarted = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds <= 1) {
          _timer?.cancel();
          final earned = _selectedMinutes;
          setState(() {
            _remainingSeconds = 0;
            _isRunning = false;
            _totalStudyMinutes += earned;
          });
          _persistTotal(_totalStudyMinutes);
          _showCompletionDialog();
        } else {
          setState(() => _remainingSeconds--);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isRunning = false;
      _hasStarted = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Great study session! \u{1F4D6}',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: Text(
          'You studied for $_selectedMinutes minutes.\n'
          'Total study time: $_totalStudyMinutes minutes.',
          style: GoogleFonts.lora(),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reset();
            },
            style: FilledButton.styleFrom(
              backgroundColor: BrandColors.brown,
              foregroundColor: BrandColors.cream,
            ),
            child: Text('Done', style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B1E19) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: BrandColors.brownMid.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.brown.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text('\u{23F1}\u{FE0F}', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Study Timer',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? BrandColors.cream : BrandColors.dark,
                ),
              ),
              const Spacer(),
              Text(
                '${_totalStudyMinutes}m total',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: BrandColors.brownMid.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Circular progress + time
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _TimerRingPainter(
                progress: _progress,
                trackColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : BrandColors.brownMid.withValues(alpha: 0.1),
                progressColor: BrandColors.gold,
                strokeWidth: 8,
              ),
              child: Center(
                child: Text(
                  _formattedTime,
                  style: GoogleFonts.lora(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? BrandColors.cream : BrandColors.dark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Preset chips
          Wrap(
            spacing: 8,
            children: _presets.map((m) {
              final selected = m == _selectedMinutes;
              return ChoiceChip(
                label: Text('${m}m',
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? BrandColors.cream : BrandColors.brownMid,
                    )),
                selected: selected,
                selectedColor: BrandColors.brown,
                backgroundColor: isDark
                    ? const Color(0xFF3E2723)
                    : BrandColors.cream,
                side: BorderSide(
                  color: selected
                      ? BrandColors.brown
                      : BrandColors.brownMid.withValues(alpha: 0.25),
                ),
                onSelected: _isRunning ? null : (_) => _selectPreset(m),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play / Pause
              FilledButton.icon(
                onPressed: _remainingSeconds > 0 ? _toggleTimer : null,
                icon: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 22,
                ),
                label: Text(_isRunning ? 'Pause' : (_hasStarted ? 'Resume' : 'Start'),
                    style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.brown,
                  foregroundColor: BrandColors.cream,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
              // Reset
              OutlinedButton.icon(
                onPressed: _hasStarted ? _reset : null,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text('Reset',
                    style: GoogleFonts.lora(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.brownMid,
                  side: BorderSide(
                      color: BrandColors.brownMid.withValues(alpha: 0.3)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timer Ring Painter
// ---------------------------------------------------------------------------

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [
            progressColor,
            progressColor.withValues(alpha: 0.7),
            progressColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress;
}
