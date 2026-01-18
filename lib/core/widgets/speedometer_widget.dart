import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ftms/core/config/live_data_field_format_strategy.dart';
import 'package:ftms/core/config/live_data_field_config.dart';
import 'package:ftms/core/utils/i18n_utils.dart';
import '../models/live_data_field_value.dart';
import 'live_data_icon_registry.dart';
import '../../l10n/app_localizations.dart';

/// Widget for displaying a value as a speedometer (gauge).
class SpeedometerWidget extends StatelessWidget {
  final LiveDataFieldConfig displayField;
  final LiveDataFieldValue? param;
  final Color color;
  final ({double lower, double upper})? targetInterval;

  const SpeedometerWidget(
      {super.key,
      required this.displayField,
      this.param,
      this.color = Colors.blue,
      this.targetInterval});

  @override
  Widget build(BuildContext context) {
    double? min =
        (displayField.min is num) ? (displayField.min as num).toDouble() : null;
    double? max =
        (displayField.max is num) ? (displayField.max as num).toDouble() : null;
    
    IconData? iconData = getLiveDataIcon(displayField.icon);
    
    if (param == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(getFieldLabel(displayField, Localizations.localeOf(context).languageCode), style: const TextStyle(fontWeight: FontWeight.bold)),
              if (iconData != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Icon(iconData, size: 16, color: Colors.grey[600]),
                ),
            ],
          ),
          Text(AppLocalizations.of(context)!.noData, style: const TextStyle(color: Colors.grey)),
        ],
      );
    }
    
    final scaledValue = param!.getScaledValue();
    
    // if there is a formatter, then use the field format strategy to init a variable
    // with the formatted value
    String formattedValue = '${scaledValue.toStringAsFixed(0)} ${displayField.unit}';
    if (displayField.formatter != null) {
      final formatterStrategy =
          LiveDataFieldFormatter.getStrategy(displayField.formatter!);
      if (formatterStrategy != null) {
        formattedValue = formatterStrategy.format(
            field: displayField, paramValue: scaledValue);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final gaugeWidth = w.isFinite ? w * 0.9 : 120.0;
        final gaugeHeight = h.isFinite ? (h - 40).clamp(40.0, h * 0.7) : 65.0;
        final labelSize = (gaugeWidth / 8).clamp(12.0, 18.0);
        final valueSize = (gaugeWidth / 5).clamp(16.0, 32.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(getFieldLabel(displayField, Localizations.localeOf(context).languageCode),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: labelSize)),
                if (iconData != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Icon(iconData, size: labelSize, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: gaugeWidth,
                    height: gaugeHeight,
                    child: CustomPaint(
                      painter: _GaugePainter(scaledValue.toDouble(), min!, max!, color, targetInterval: targetInterval),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(formattedValue, style: TextStyle(fontSize: valueSize, color: color, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final ({double lower, double upper})? targetInterval;

  _GaugePainter(this.value, this.min, this.max, this.color, {this.targetInterval});

  @override
  void paint(Canvas canvas, Size size) {
    // Use the smaller dimension to ensure a perfect circle
    final diameter = math.min(size.width, size.height);
    final radius = diameter / 2;
    final strokeWidth = (diameter / 15).clamp(6.0, 20.0);
    // Center the circle in the available space

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Create a square rect centered in the available space for a perfect circle
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: diameter,
      height: diameter,
    );
    
    // Draw background arc
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
    
    // Draw target range if available
    if (targetInterval != null) {
      final targetPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth * 1.5
        ..style = PaintingStyle.stroke;
      
      // Handle inverted ranges (where max < min, like pace values)
      final bool isInverted = max < min;
      final double targetLowerNormalized;
      final double targetUpperNormalized;
      final double targetStartAngle;
      final double targetSweep;
      
      if (isInverted) {
        // For inverted ranges, normalize the values and invert the position
        targetLowerNormalized = ((targetInterval!.lower - max) / (min - max)).clamp(0, 1);
        targetUpperNormalized = ((targetInterval!.upper - max) / (min - max)).clamp(0, 1);
        targetStartAngle = 3.14 + (1 - targetUpperNormalized) * 3.14;
        targetSweep = (targetUpperNormalized - targetLowerNormalized) * 3.14;
      } else {
        // Normal ranges
        targetLowerNormalized = ((targetInterval!.lower - min) / (max - min)).clamp(0, 1);
        targetUpperNormalized = ((targetInterval!.upper - min) / (max - min)).clamp(0, 1);
        targetStartAngle = 3.14 + targetLowerNormalized * 3.14;
        targetSweep = (targetUpperNormalized - targetLowerNormalized) * 3.14;
      }
      
      canvas.drawArc(rect, targetStartAngle, targetSweep, false, targetPaint);
    }
    // Draw value arc
    final paintValue = Paint()
      ..color = color // Utilise la couleur passée au constructeur
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Handle inverted ranges (where max < min, like pace values)
    final bool isInverted = max < min;
    final double normalizedValue;
    final double sweep;
    final double angle;
    
    if (isInverted) {
      // For inverted ranges, normalize the value and invert the position
      normalizedValue = ((value - max) / (min - max)).clamp(0, 1);
      sweep = (1 - normalizedValue) * 3.14;
      angle = 3.14 + (1 - normalizedValue) * 3.14;
    } else {
      // Normal ranges
      normalizedValue = ((value - min) / (max - min)).clamp(0, 1);
      sweep = normalizedValue * 3.14;
      angle = 3.14 + normalizedValue * 3.14;
    }
    
    canvas.drawArc(rect, 3.14, sweep, false, paintValue);
    
    // Draw hour hand (needle)
    final center = Offset(centerX, centerY);
    final needleLength = radius * 0.7; // 70% of the radius
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );
    
    final needlePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = (diameter / 40).clamp(2.0, 6.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Draw the needle line
    canvas.drawLine(center, needleEnd, needlePaint);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, (diameter / 30).clamp(3.0, 8.0), centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
