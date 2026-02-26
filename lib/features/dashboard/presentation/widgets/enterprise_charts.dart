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

// ─── HOURLY ORDERS CHART ──────────────────────────────────────────────────
class HourlyOrdersChart extends StatelessWidget {
  final List<int> data;
  final bool isDarkMode;

  const HourlyOrdersChart({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (data.every((v) => v == 0)) {
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
          painter: LineChartPainter(
            data: data,
            isDarkMode: isDarkMode,
          ),
        );
      },
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<int> data;
  final bool isDarkMode;

  LineChartPainter({required this.data, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF1E88E5);
      
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
           const Color(0xFF1E88E5).withValues(alpha: 0.5),
           const Color(0xFF1E88E5).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final maxValue = max(1, data.reduce(max));
    final dx = size.width / (data.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
        final x = i * dx;
        final y = size.height - 20 - ((data[i] / maxValue) * (size.height - 40));
        
        if (i == 0) {
            path.moveTo(x, y);
            fillPath.moveTo(x, size.height - 20);
            fillPath.lineTo(x, y);
        } else {
            path.lineTo(x, y);
            fillPath.lineTo(x, y);
        }
    }
    
    fillPath.lineTo(size.width, size.height - 20);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // Draw Axis
    final axisPaint = Paint()
      ..color = isDarkMode ? Colors.white24 : Colors.black12
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 20), Offset(size.width, size.height - 20), axisPaint);

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (int i = 0; i < data.length; i += 4) {
      textPainter.text = TextSpan(
        text: '${i.toString().padLeft(2, '0')}:00',
        style: TextStyle(
          color: isDarkMode ? Colors.white54 : Colors.black54,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(i * dx - (textPainter.width / 2), size.height - 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isDarkMode != isDarkMode;
  }
}

// ─── CATEGORY DONUT CHART ─────────────────────────────────────────────────
class CategoryDonutChart extends StatelessWidget {
  final Map<String, double> data;
  final bool isDarkMode;

  const CategoryDonutChart({
    super.key,
    required this.data,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (data.values.every((v) => v == 0)) {
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
        return Row(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: DonutChartPainter(
                  data: data,
                  isDarkMode: isDarkMode,
                ),
              ),
            ),
            // Custom Legend
            SizedBox(
              width: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries.map((e) {
                  final i = data.keys.toList().indexOf(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: _getDonutColor(i), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key, 
                            style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white70 : Colors.black87), 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                     ],
                    )
                  );
                }).toList(),
              )
            )
          ]
        );
      }
    );
  }
  
  Color _getDonutColor(int index) {
      final colors = [
        const Color(0xFF673AB7), // Deep Purple
        const Color(0xFF009688), // Teal
        const Color(0xFFFF9800), // Orange
        const Color(0xFF607D8B), // Blue Grey
        const Color(0xFF4CAF50), // Green (fallback)
      ];
      return colors[index % colors.length];
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final bool isDarkMode;

  DonutChartPainter({required this.data, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
     final total = data.values.fold(0.0, (sum, v) => sum + v);
     if (total == 0) return;
     
     final center = Offset(size.width / 2, size.height / 2);
     final radius = min(size.width, size.height) / 2 - 10;
     final paint = Paint()
       ..style = PaintingStyle.stroke
       ..strokeWidth = 30;
       
     var startAngle = -pi / 2;
     
     var i = 0;
     for (var entry in data.entries) {
        final sweepAngle = (entry.value / total) * 2 * pi;
        paint.color = _getDonutColor(i);
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
        startAngle += sweepAngle;
        i++;
     }
     
     // Center Text
     final textPainter = TextPainter(
       text: TextSpan(
         text: 'Total\n100%',
         style: TextStyle(
           color: isDarkMode ? Colors.white : Colors.black87,
           fontSize: 12,
           fontWeight: FontWeight.bold,
         )
       ),
       textAlign: TextAlign.center,
       textDirection: TextDirection.ltr,
     );
     textPainter.layout();
     textPainter.paint(canvas, Offset(center.dx - (textPainter.width/2), center.dy - (textPainter.height/2)));
  }

  Color _getDonutColor(int index) {
      final colors = [
        const Color(0xFF673AB7), // Deep Purple
        const Color(0xFF009688), // Teal
        const Color(0xFFFF9800), // Orange
        const Color(0xFF607D8B), // Blue Grey
        const Color(0xFF4CAF50), // Green (fallback)
      ];
      return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.isDarkMode != isDarkMode;
  }
}
