import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../items/domain/catalog_item.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../../../orders/domain/history_tab.dart';
import '../../../orders/domain/order_history_entry.dart';
import '../../../orders/domain/order_line_item.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

/// Return Order — reached from Settings. There is no return/refund concept
/// anywhere in the schema yet (no table, no repository method), so this
/// screen is a real, functional *form* built on real order/item data (the
/// restaurant's most recent order, its real line items, real quantities)
/// but "Submit Return Request" is UI-only for now — same "coming soon"
/// treatment as Business Details' Edit Profile. The Figma reference also
/// shows a per-item price column and a fabricated "Returnable until" date;
/// both are dropped rather than invented, per the no-item-price rule and
/// the project's "flag missing data, don't fabricate it" rule respectively.
class ReturnOrderScreen extends ConsumerWidget {
  const ReturnOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyControllerProvider(HistoryTab.allOrders));

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(child: _buildBody(context, ref, historyState)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, HistoryState state) {
    if (state.isLoading && state.entries.isEmpty) {
      return const LoadingState();
    }
    if (state.error != null && state.entries.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_outlined,
        message: "Couldn't load your orders.",
        action: TextButton(
          onPressed: () => ref.read(historyControllerProvider(HistoryTab.allOrders).notifier).retry(),
          child: const Text('Retry'),
        ),
      );
    }
    if (state.entries.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_return_outlined,
        message: 'No orders yet to return items from.',
      );
    }
    return _ReturnOrderBody(key: ValueKey(state.entries.first.orderId), order: state.entries.first);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText, size: 20),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Return Order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _ReturnOrderBody extends ConsumerStatefulWidget {
  const _ReturnOrderBody({super.key, required this.order});

  final OrderHistoryEntry order;

  @override
  ConsumerState<_ReturnOrderBody> createState() => _ReturnOrderBodyState();
}

class _ReturnOrderBodyState extends ConsumerState<_ReturnOrderBody> {
  int _selectedIndex = 0;
  bool _expanded = false;
  String? _reason;
  int _quantity = 1;
  final _notesController = TextEditingController();

  static const _reasons = [
    'Damaged item',
    'Wrong item delivered',
    'Quality issue',
    'Excess quantity received',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _selectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _expanded = false;
      _quantity = 1;
    });
  }

  void _pickReason() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.bottomSheetTopRadius)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            for (final reason in _reasons)
              ListTile(
                title: Text(
                  reason,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(reason),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _reason = picked);
  }

  void _handleSubmit() {
    if (_reason == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Please select a reason for the return')));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text("Return requests are coming soon. We'll notify you once this is live.")),
      );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(orderItemsProvider(widget.order.orderId));
    final catalog = ref.watch(catalogProvider).valueOrNull ?? const <CatalogItem>[];

    return itemsAsync.when(
      loading: () => const LoadingState(),
      error: (error, _) => EmptyState(
        icon: Icons.wifi_off_outlined,
        message: "Couldn't load this order's items.",
        action: TextButton(
          onPressed: () => ref.refresh(orderItemsProvider(widget.order.orderId)),
          child: const Text('Retry'),
        ),
      ),
      data: (lines) {
        if (lines.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_return_outlined,
            message: 'This order has no items to return.',
          );
        }
        final selectedIndex = _selectedIndex < lines.length ? _selectedIndex : 0;
        final selectedLine = lines[selectedIndex];

        return ListView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.bottomNavHeight + AppSpacing.base),
          children: [
            _OrderBadge(order: widget.order),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Select Item to Return'),
            const SizedBox(height: AppSpacing.base),
            _ItemSelectorCard(
              lines: lines,
              catalog: catalog,
              selectedIndex: selectedIndex,
              expanded: _expanded,
              onToggleExpanded: () => setState(() => _expanded = !_expanded),
              onSelect: _selectItem,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Reason for return'),
            const SizedBox(height: AppSpacing.base),
            _ReasonSelector(reason: _reason, onTap: _pickReason),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Return quantity'),
            const SizedBox(height: AppSpacing.base),
            _ReturnQuantityRow(
              quantity: _quantity,
              maxQuantity: selectedLine.quantity,
              unit: selectedLine.unit,
              onIncrement: _quantity < selectedLine.quantity
                  ? () => setState(() => _quantity++)
                  : null,
              onDecrement: _quantity > 1 ? () => setState(() => _quantity--) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle('Additional notes (optional)'),
            const SizedBox(height: AppSpacing.base),
            _NotesField(controller: _notesController),
            const SizedBox(height: AppSpacing.xl),
            _SubmitButton(onTap: _handleSubmit),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryText,
        fontSize: 16,
        fontFamily: AppTextStyles.urbanistFontFamily,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.order});

  final OrderHistoryEntry order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.surfaceWhite, shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.ctaText,
                    fontSize: 16,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppColors.ctaText, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMMM yyyy, hh:mm a').format(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.ctaText,
                        fontSize: 12,
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const _CheckBadge(),
        ],
      ),
    );
  }
}

/// "This order is selected" badge on [_OrderBadge] — green rounded-square
/// chip with a teal circle-outline check, per the reference icon (not part
/// of the app's existing token set, so the teal is a small local addition).
class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  static const _teal = Color(0xFF2FD1D9);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 17,
        height: 17,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _teal, width: 1.5)),
        child: SvgPicture.asset(
          'assets/icons/icon_check.svg',
          width: 8,
          height: 6,
          colorFilter: const ColorFilter.mode(_teal, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _ItemSelectorCard extends StatelessWidget {
  const _ItemSelectorCard({
    required this.lines,
    required this.catalog,
    required this.selectedIndex,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onSelect,
  });

  final List<OrderLineItem> lines;
  final List<CatalogItem> catalog;
  final int selectedIndex;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onSelect;

  String? _imageUrl(String? itemId) {
    if (itemId == null) return null;
    for (final item in catalog) {
      if (item.id == itemId) return item.imageUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          _ItemRow(
            line: lines[selectedIndex],
            imageUrl: _imageUrl(lines[selectedIndex].itemId),
            selected: true,
            onTap: null,
          ),
          if (lines.length > 1) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),
            _ViewAllButton(expanded: expanded, onTap: onToggleExpanded),
            if (expanded) ...[
              const SizedBox(height: 8),
              for (var i = 0; i < lines.length; i++)
                if (i != selectedIndex)
                  _ItemRow(
                    line: lines[i],
                    imageUrl: _imageUrl(lines[i].itemId),
                    selected: false,
                    onTap: () => onSelect(i),
                  ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.line, required this.imageUrl, required this.selected, this.onTap});

  final OrderLineItem line;
  final String? imageUrl;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: imageUrl == null || imageUrl!.isEmpty
                    ? _imageFallback()
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, _, _) => _imageFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.itemName,
                    style: AppTextStyles.itemName.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('${line.quantity} ${line.unit}'.trim(), style: AppTextStyles.caption),
                ],
              ),
            ),
            if (selected)
              SvgPicture.asset(
                'assets/icons/icon_check.svg',
                width: 17,
                height: 12,
                colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.placeholder, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.inputBackground,
      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.placeholder, size: 18),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonSelector extends StatelessWidget {
  const _ReasonSelector({required this.reason, required this.onTap});

  final String? reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppColors.placeholder, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason ?? 'Select a reason',
                style: TextStyle(
                  color: reason == null ? AppColors.placeholder : AppColors.primaryText,
                  fontSize: 14,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ReturnQuantityRow extends StatelessWidget {
  const _ReturnQuantityRow({
    required this.quantity,
    required this.maxQuantity,
    required this.unit,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final int maxQuantity;
  final String unit;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  // Not part of the app's shared token set anywhere else — a small inline
  // addition for this one "Max: N unit" chip, same treatment as
  // AppColors.error/success being flagged as non-Figma additions.
  static const _chipBackground = Color(0xFFFCEEDD);
  static const _chipText = Color(0xFFB56A1D);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepperButton(icon: Icons.remove, onTap: onDecrement),
              SizedBox(
                width: 28,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    fontFamily: AppTextStyles.urbanistFontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StepperButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _chipBackground, borderRadius: BorderRadius.circular(50)),
          child: Text(
            'Max: $maxQuantity $unit'.trim(),
            style: const TextStyle(
              color: _chipText,
              fontSize: 12,
              fontFamily: AppTextStyles.fontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 14,
          color: onTap == null ? AppColors.placeholder.withValues(alpha: 0.4) : AppColors.secondary,
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      style: const TextStyle(
        color: AppColors.primaryText,
        fontSize: 14,
        fontFamily: AppTextStyles.fontFamily,
      ),
      decoration: InputDecoration(
        hintText: 'Type your message',
        hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.primaryCtaHeight,
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: const Center(
            child: Text(
              'Submit Return Request',
              style: TextStyle(
                color: AppColors.ctaText,
                fontSize: 16,
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
