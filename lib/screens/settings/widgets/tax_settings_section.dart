import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/settings_providers.dart';

/// Tax Settings — kept deliberately simple per approved scope: an
/// Enabled/Disabled toggle and one rate. No assumed/hard-coded rate, no
/// GST-specific fields, no tax reports/ledgers/filing. Structured (see
/// TaxSettings + app_settings table) so more rates could be added later
/// without a rebuild.
class TaxSettingsSection extends ConsumerStatefulWidget {
  const TaxSettingsSection({super.key});

  @override
  ConsumerState<TaxSettingsSection> createState() => _TaxSettingsSectionState();
}

class _TaxSettingsSectionState extends ConsumerState<TaxSettingsSection> {
  bool? _enabled;
  final _percentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _percentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).saveTaxSettings(TaxSettings(
            enabled: _enabled ?? false,
            percent: double.tryParse(_percentCtrl.text),
          ));
      ref.invalidate(taxSettingsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tax settings saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taxAsync = ref.watch(taxSettingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: taxAsync.when(
          loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          error: (e, _) => Text('Could not load tax settings: $e'),
          data: (tax) {
            _enabled ??= tax.enabled;
            if (_percentCtrl.text.isEmpty && tax.percent != null) {
              _percentCtrl.text = tax.percent!.toString();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tax settings', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s1),
                const Text('Turn tax on and set the rate to apply.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tax', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text('Apply a tax rate to transactions', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(value: _enabled!, onChanged: (v) => setState(() => _enabled = v)),
                  ],
                ),
                if (_enabled == true) ...[
                  const SizedBox(height: AppSpacing.s3),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _percentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Tax percentage', suffixText: '%'),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.s3),
                    child: Text('Tax is currently disabled — no rate is applied.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ),
                const SizedBox(height: AppSpacing.s4),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save changes'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
