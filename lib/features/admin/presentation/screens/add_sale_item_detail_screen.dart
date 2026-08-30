import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../../items/domain/catalog_item.dart';
import '../../domain/sale_line_item.dart';

/// Quantity + price entry for one already-picked catalog item, on its way
/// into an admin sale — a real pushed screen (not a bottom sheet) matching
/// the Figma "Add Items to Sale" export. Unit is shown, not offered as a
/// real dropdown — the catalog stores exactly one unit per item, so a
/// working multi-option picker would have nothing real to offer.
class AddSaleItemDetailScreen extends StatefulWidget {
  const AddSaleItemDetailScreen({super.key, required this.item});

  final CatalogItem item;

  @override
  State<AddSaleItemDetailScreen> createState() =>
      _AddSaleItemDetailScreenState();
}

class _AddSaleItemDetailScreenState extends State<AddSaleItemDetailScreen> {
  late final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _confirm() {
    final quantity = int.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Enter a valid quantity');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid price');
      return;
    }
    Navigator.of(context).pop(
      SaleLineItem(
        itemId: widget.item.id,
        itemName: widget.item.name,
        unit: widget.item.unit,
        quantity: quantity,
        rate: price,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/icon_back_chevron.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Items to Sale',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/icon_kebab_menu.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () =>
                showAppSnackBar(context, 'More options are coming soon.'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadonlyBox(label: 'ITEM NAME', value: widget.item.name),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EditableBox(
                      label: 'QUANTITY',
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReadonlyBox(
                      label: 'UNIT',
                      value: widget.item.unit,
                      trailing: SvgPicture.asset(
                        'assets/icons/icon_chevron_down.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EditableBox(
                label: 'PRICE',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: '₹',
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
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

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _EditableBox extends StatelessWidget {
  const _EditableBox({
    required this.label,
    required this.controller,
    required this.keyboardType,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 10,
              fontFamily: 'Poppins',
              letterSpacing: 1,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              suffixText: suffix,
            ),
          ),
        ],
      ),
    );
  }
}
