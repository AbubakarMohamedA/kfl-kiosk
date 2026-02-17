import 'package:flutter/material.dart';
import 'dart:math';

class BranchRevenueChart extends StatelessWidget {
  final Map<String, double> data;
  final bool isDarkMode;

  const BranchRevenueChart({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.grey,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: BarChartPainter(
            data: data,
            isDarkMode: isDarkMode,
          ),
        );
      },
    );
  }
}

class BarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final bool isDarkMode;

  BarChartPainter({required this.data, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final maxValue = data.values.reduce(max);
    final barWidth = size.width / (data.length * 2);
    final spacing = size.width / (data.length * 2);

    var i = 0;
    for (var entry in data.entries) {
      final label = entry.key;
      final value = entry.value;
      final barHeight = (value / maxValue) * (size.height - 40); // Leave room for text

      final left = (i * (barWidth + spacing)) + spacing / 2;
      final top = size.height - barHeight - 20;
      final right = left + barWidth;
      final bottom = size.height - 20;

      // Draw Bar
      paint.color = _getColor(i);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, paint);

      // Draw Label
      textPainter.text = TextSpan(
        text: _truncateLabel(label),
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontSize: 10,
        ),
      );
      textPainter.layout(maxWidth: barWidth + spacing);
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, size.height - 15),
      );

      // Draw Value tooltip
      textPainter.text = TextSpan(
        text: _formatValue(value),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, top - 15),
      );

      i++;
    }
  }

  Color _getColor(int index) {
    final colors = [
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFFDD835), // Yellow
      const Color(0xFFE53935), // Red
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF00ACC1), // Cyan
    ];
    return colors[index % colors.length];
  }

  String _truncateLabel(String label) {
    if (label.length > 8) {
      return '${label.substring(0, 6)}..';
    }
    return label;
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isDarkMode != isDarkMode;
  }
}
