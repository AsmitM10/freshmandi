import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customers_providers.dart';
import '../../widgets/empty_state.dart';

class CustomersListScreen extends ConsumerWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(filteredCustomersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s2),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search business, contact or phone…'),
              onChanged: (v) => ref.read(customersSearchProvider.notifier).state = v,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(allCustomersProvider)),
              data: (customers) {
                if (customers.isEmpty) {
                  return const EmptyStateView(icon: Icons.people_outline, title: 'No customers found', body: 'Try a different search.');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allCustomersProvider),
                  child: ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: AppColors.navy50, child: Text(_initials(c.businessName))),
                        title: Text(c.businessName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${c.contactName} · ${c.phone}'),
                        trailing: c.outstandingBalance > 0
                            ? Text(formatInr(c.outstandingBalance), style: const TextStyle(color: AppColors.warn600, fontWeight: FontWeight.w700))
                            : null,
                        onTap: () => context.push('/admin/customers/${c.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
