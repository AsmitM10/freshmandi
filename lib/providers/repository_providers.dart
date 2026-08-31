import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/repositories/customers_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/items_repository.dart';
import '../data/repositories/orders_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/transactions_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());
final categoriesRepositoryProvider = Provider((ref) => CategoriesRepository());
final itemsRepositoryProvider = Provider((ref) => ItemsRepository());
final customersRepositoryProvider = Provider((ref) => CustomersRepository());
final ordersRepositoryProvider = Provider((ref) => OrdersRepository());
final transactionsRepositoryProvider = Provider((ref) => TransactionsRepository());
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());
