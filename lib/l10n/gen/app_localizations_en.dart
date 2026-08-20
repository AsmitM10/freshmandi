// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FreshMandi';

  @override
  String get retry => 'Retry';

  @override
  String get navHome => 'Home';

  @override
  String get navShop => 'Shop';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage your account and app preferences';

  @override
  String get settingsBusinessDetailsTitle => 'Business Details';

  @override
  String get settingsBusinessDetailsSubtitle =>
      'View and manage business information';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'Read our privacy policy';

  @override
  String get settingsAboutUsTitle => 'About Us';

  @override
  String get settingsAboutUsSubtitle => 'Learn more about our app and team';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Change your preferred language';

  @override
  String get settingsReturnOrderTitle => 'Return Order';

  @override
  String get settingsReturnOrderSubtitle =>
      'View return policy and raise a request';

  @override
  String get settingsTermsTitle => 'Terms and Conditions';

  @override
  String get settingsTermsSubtitle => 'Know your rights and responsibilities.';

  @override
  String get settingsHelpTitle => 'Need a help?';

  @override
  String get settingsHelpSubtitle => 'We\'re here for you.';

  @override
  String settingsComingSoon(String label) {
    return '$label is coming soon';
  }

  @override
  String get languageScreenTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get homeGreetingSubtitle => 'Follow your routine for today';

  @override
  String get homeDefaultRestaurantName => 'Restaurant';

  @override
  String get homeBrowseCategory => 'Browse Category';

  @override
  String get homeFrequentlyOrdered => 'Frequently Ordered';

  @override
  String get homeFrequentlyOrderedEmpty =>
      'Items you order often will show up here after your first order.';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopSearchHint => 'Search Vegetables, Fruits...';

  @override
  String get shopLoadError =>
      'Couldn\'t load items. Check your connection and try again.';

  @override
  String get shopNoSearchResults => 'No items match your search.';

  @override
  String get shopNoCategoryItems => 'No items in this category yet.';

  @override
  String get categoryIndianVegetables => 'Indian Vegetables';

  @override
  String get categoryFruits => 'Fruits';

  @override
  String get categoryExoticVeg => 'Exotic Veg';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartAddItem => 'Add Item';

  @override
  String get cartPlaceOrder => 'Place Order';

  @override
  String get cartTotalItems => 'Total Items';

  @override
  String get cartEmpty => 'Your cart is empty.';

  @override
  String get cartBrowseShop => 'Browse Shop';

  @override
  String get cartLoadError =>
      'Couldn\'t load your cart. Check your connection and try again.';

  @override
  String get historyTitle => 'History';

  @override
  String get historySubtitle => 'Farm freshed and handpicked daily';

  @override
  String get historyTabAll => 'All Orders';

  @override
  String get historyTabTransaction => 'Transaction';

  @override
  String get historyTabPending => 'Pending Invoice';

  @override
  String get historyEmptyAll => 'No orders yet';

  @override
  String get historyEmptyTransaction => 'No transactions yet';

  @override
  String get historyEmptyPending => 'No pending invoices';

  @override
  String get historyLoadError =>
      'Couldn\'t load history. Check your connection and try again.';

  @override
  String get invoiceTitle => 'Invoice';

  @override
  String get orderNumberLabel => 'ORDER NO.';

  @override
  String get priceLabel => 'PRICE';

  @override
  String get itemsLabel => 'ITEMS';

  @override
  String get recognizedOrder => 'Recognized Order';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get liveLabel => 'Live';

  @override
  String get orderViewDetails => 'View Details';

  @override
  String get orderRepeat => 'Repeat Order';

  @override
  String get orderPayNow => 'Pay Now';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusUnpaid => 'Unpaid';

  @override
  String get invoiceLoadError =>
      'Couldn\'t load this order. Check your connection and try again.';

  @override
  String get invoiceItemsLoadError => 'Couldn\'t load this order\'s items.';

  @override
  String get invoiceNoItems => 'No items found for this order.';

  @override
  String get invoiceNotAvailableYet =>
      'Invoice will be available after order confirmation.';

  @override
  String get invoiceDownloadSuccess => 'Invoice downloaded successfully.';

  @override
  String get invoiceDownloadFailure =>
      'Unable to download invoice. Please try again.';

  @override
  String get invoiceWaitingTitle => 'Waiting for confirmation';

  @override
  String get invoiceWaitingBody =>
      'The final amount and invoice will be available once the wholesaler confirms this order.';

  @override
  String get voiceOrderTitle => 'Voice Order';

  @override
  String get voiceOrderSubtitle => 'Tap the mic and speak your order items';

  @override
  String get voiceOrderHint =>
      'Speak like \"20 kilo tamatar\" or \"kal ka order repeat  karo\"';

  @override
  String get voiceGenerateList => 'Generate List';

  @override
  String get voiceErrorNoSpeech =>
      'We couldn\'t hear an order. Please try again.';

  @override
  String get voiceErrorPermission =>
      'Microphone permission is required to use voice ordering.';

  @override
  String get voiceErrorUnavailable =>
      'Voice ordering isn\'t available on this device.';

  @override
  String get voiceErrorGeneric =>
      'Something went wrong while listening. Please try again.';

  @override
  String get voiceErrorNoItems =>
      'We couldn\'t find any items from your order.';

  @override
  String get voiceErrorCatalog =>
      'Could not load the item catalog. Check your connection and try again.';

  @override
  String voiceAddedToCart(int added, int unmatched) {
    return 'Added $added item(s) to your cart. Couldn\'t identify $unmatched item(s).';
  }
}
