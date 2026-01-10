import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_cubit.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_cubit.dart';

class CustomizationControls extends StatelessWidget {
  const CustomizationControls({super.key});

  void _openColorPicker(
    BuildContext context,
    Color current,
    Function(Color) onChange,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick color'),
        content: ColorPicker(
          pickerColor: current,
          onColorChanged: onChange,
          enableAlpha: false,
          labelTypes: const [],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _colorTile(
    BuildContext context, {
    required String label,
    required Color color,
    required Function(Color) onChange,
  }) {
    return ListTile(
      title: Text(label),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
      onTap: () => _openColorPicker(context, color, onChange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewCubit = context.watch<CustomizationPreviewCubit>();
    final colors = previewCubit.state.colors;
    return Column(
      children: [
        _colorTile(
          context,
          label: 'Primary Color',
          color: colors.primary,
          onChange: previewCubit.updatePrimary,
        ),
        _colorTile(
          context,
          label: 'Background Color',
          color: colors.background,
          onChange: previewCubit.updateBackground,
        ),
        _colorTile(
          context,
          label: 'Button Color',
          color: colors.button,
          onChange: previewCubit.updateButton,
        ),

        const Spacer(),

        const SizedBox(height: 8),

        ElevatedButton(
          onPressed: () {
            context.read<CustomizationCubit>().applyTheme(colors);
            Navigator.pop(context);
          },
          child: const Text('Save Changes'),
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}
