import 'package:flutter/material.dart';
import 'package:ftms/core/models/device_types.dart';
import '../config/live_data_display_config.dart';
import '../config/live_data_field_config.dart';
import '../models/live_data_field_value.dart';
import 'live_data_field_widget.dart';

/// Shared widget for displaying FTMS live data fields according to config.
class FtmsLiveDataDisplayWidget extends StatelessWidget {
  final LiveDataDisplayConfig config;
  final Map<String, LiveDataFieldValue> paramValueMap;
  final Map<String, dynamic>? targets;
  final Color? defaultColor;
  final DeviceType? machineType;
  const FtmsLiveDataDisplayWidget({
    super.key,
    required this.config,
    required this.paramValueMap,
    this.targets,
    this.defaultColor,
    this.machineType,
  });

  @override
  Widget build(BuildContext context) {
    final supported = config.fields.where((f) => paramValueMap[f.name] != null).toList();
    final speedos = supported.where((f) => f.display == 'speedometer').toList();
    final numbers = supported.where((f) => f.display != 'speedometer').toList();

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: speedos.map((f) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _buildFieldWidget(f),
              ),
            )).toList(),
          ),
        ),
        if (numbers.isNotEmpty)
          SizedBox(
            height: 60,
            child: Row(
              children: numbers.map((f) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildFieldWidget(f),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldWidget(LiveDataFieldConfig field) {
    final param = paramValueMap[field.name];
    final target = targets != null ? targets![field.name] : null;
    return LiveDataFieldWidget(
      field: field,
      param: param,
      target: target,
      defaultColor: defaultColor,
      machineType: machineType,
    );
  }
}
