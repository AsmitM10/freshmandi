import '../../core/supabase/supabase_client.dart';

class TaxSettings {
  final bool enabled;
  final double? percent;

  const TaxSettings({required this.enabled, this.percent});

  factory TaxSettings.fromJson(Map<String, dynamic> json) => TaxSettings(
        enabled: json['enabled'] as bool? ?? false,
        percent: (json['percent'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'percent': percent};
}

/// `admin_settings` is this admin app's own key/value settings table —
/// separate from `business_settings` (the wholesaler's identity shown on
/// customer invoices). See
/// supabase/migrations/20260830000001_business_console_integration.sql.
class SettingsRepository {
  Future<TaxSettings> fetchTaxSettings() async {
    final row = await supabase.from('admin_settings').select('value').eq('key', 'tax').maybeSingle();
    if (row == null) return const TaxSettings(enabled: false);
    return TaxSettings.fromJson(row['value'] as Map<String, dynamic>);
  }

  Future<void> saveTaxSettings(TaxSettings settings) async {
    await supabase.from('admin_settings').upsert({
      'key': 'tax',
      'value': settings.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
