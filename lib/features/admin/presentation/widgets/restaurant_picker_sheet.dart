import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/admin_restaurant_option.dart';
import '../providers/admin_sales_providers.dart';

/// Search/pick an existing approved restaurant for "Add Sale" — there's no
/// ad-hoc/walk-in customer concept, every sale attaches to a real
/// registered restaurant (orders.restaurant_id is a required foreign key).
Future<AdminRestaurantOption?> showRestaurantPickerSheet(BuildContext context) {
  return showModalBottomSheet<AdminRestaurantOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _RestaurantPickerContent(),
  );
}

class _RestaurantPickerContent extends ConsumerStatefulWidget {
  const _RestaurantPickerContent();

  @override
  ConsumerState<_RestaurantPickerContent> createState() =>
      _RestaurantPickerContentState();
}

class _RestaurantPickerContentState
    extends ConsumerState<_RestaurantPickerContent> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<AdminRestaurantOption>? _results;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(adminSalesRepositoryProvider)
          .searchRestaurants(query);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Customer',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.placeholder,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search restaurant name...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.placeholder,
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _results == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return const Center(
        child: Text(
          'Could not load restaurants.',
          style: TextStyle(color: AppColors.placeholder, fontFamily: 'Poppins'),
        ),
      );
    }
    final results = _results ?? const [];
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No approved restaurants match.',
          style: TextStyle(color: AppColors.placeholder, fontFamily: 'Poppins'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: results.length,
      separatorBuilder: (context, index) =>
          const Divider(color: AppColors.cardBorder, height: 1),
      itemBuilder: (context, index) {
        final restaurant = results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            restaurant.restaurantName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            restaurant.phoneNumber,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          onTap: () => Navigator.of(context).pop(restaurant),
        );
      },
    );
  }
}
