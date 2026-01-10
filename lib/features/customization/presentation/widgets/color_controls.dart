import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_cubit.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_cubit.dart';
import 'package:sooq_merchant/features/customization/presentation/cubits/customization_preview_state.dart';

class ColorControls extends StatelessWidget {
  const ColorControls({super.key});

  void _pickColor(
    BuildContext context,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            enableAlpha: false,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
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

  Widget _colorTile({
    required BuildContext context,
    required String label,
    required Color color,
    required Function(Color) onChanged,
  }) {
    return ListTile(
      title: Text(label),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400),
        ),
      ),
      onTap: () => _pickColor(context, color, onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomizationPreviewCubit, CustomizationPreviewState>(
      builder: (context, state) {
        final colors = state.colors;
        final cubit = context.read<CustomizationPreviewCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _colorTile(
              context: context,
              label: 'Primary Color',
              color: colors.primary,
              onChanged: cubit.updatePrimary,
            ),
            _colorTile(
              context: context,
              label: 'Background Color',
              color: colors.background,
              onChanged: cubit.updateBackground,
            ),
            _colorTile(
              context: context,
              label: 'Button Color',
              color: colors.button,
              onChanged: cubit.updateButton,
            ),
            _colorTile(
              context: context,
              label: 'Secondary Color',
              color: colors.secondary,
              onChanged: cubit.updateSecondary,
            ),
            _colorTile(
              context: context,
              label: 'Success Color',
              color: colors.success,
              onChanged: cubit.updateSuccess,
            ),
            _colorTile(
              context: context,
              label: 'Text Color',
              color: colors.text,
              onChanged: cubit.updateText,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                context.read<CustomizationCubit>().emit(colors);
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
}
