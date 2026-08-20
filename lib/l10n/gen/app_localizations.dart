import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FreshMandi'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and app preferences'**
  String get settingsSubtitle;

  /// No description provided for @settingsBusinessDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get settingsBusinessDetailsTitle;

  /// No description provided for @settingsBusinessDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage business information'**
  String get settingsBusinessDetailsSubtitle;

  /// No description provided for @settingsPrivacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicyTitle;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsAboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get settingsAboutUsTitle;

  /// No description provided for @settingsAboutUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn more about our app and team'**
  String get settingsAboutUsSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your preferred language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsReturnOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Order'**
  String get settingsReturnOrderTitle;

  /// No description provided for @settingsReturnOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View return policy and raise a request'**
  String get settingsReturnOrderSubtitle;

  /// No description provided for @settingsTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get settingsTermsTitle;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Know your rights and responsibilities.'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a help?'**
  String get settingsHelpTitle;

  /// No description provided for @settingsHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here for you.'**
  String get settingsHelpSubtitle;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{label} is coming soon'**
  String settingsComingSoon(String label);

  /// No description provided for @languageScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageScreenTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get languageHindi;

  /// No description provided for @homeGreetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow your routine for today'**
  String get homeGreetingSubtitle;

  /// No description provided for @homeDefaultRestaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get homeDefaultRestaurantName;

  /// No description provided for @homeBrowseCategory.
  ///
  /// In en, this message translates to:
  /// **'Browse Category'**
  String get homeBrowseCategory;

  /// No description provided for @homeFrequentlyOrdered.
  ///
  /// In en, this message translates to:
  /// **'Frequently Ordered'**
  String get homeFrequentlyOrdered;

  /// No description provided for @homeFrequentlyOrderedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Items you order often will show up here after your first order.'**
  String get homeFrequentlyOrderedEmpty;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Vegetables, Fruits...'**
  String get shopSearchHint;

  /// No description provided for @shopLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load items. Check your connection and try again.'**
  String get shopLoadError;

  /// No description provided for @shopNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No items match your search.'**
  String get shopNoSearchResults;

  /// No description provided for @shopNoCategoryItems.
  ///
  /// In en, this message translates to:
  /// **'No items in this category yet.'**
  String get shopNoCategoryItems;

  /// No description provided for @categoryIndianVegetables.
  ///
  /// In en, this message translates to:
  /// **'Indian Vegetables'**
  String get categoryIndianVegetables;

  /// No description provided for @categoryFruits.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get categoryFruits;

  /// No description provided for @categoryExoticVeg.
  ///
  /// In en, this message translates to:
  /// **'Exotic Veg'**
  String get categoryExoticVeg;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get cartAddItem;

  /// No description provided for @cartPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get cartPlaceOrder;

  /// No description provided for @cartTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get cartTotalItems;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get cartEmpty;

  /// No description provided for @cartBrowseShop.
  ///
  /// In en, this message translates to:
  /// **'Browse Shop'**
  String get cartBrowseShop;

  /// No description provided for @cartLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your cart. Check your connection and try again.'**
  String get cartLoadError;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Farm freshed and handpicked daily'**
  String get historySubtitle;

  /// No description provided for @historyTabAll.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get historyTabAll;

  /// No description provided for @historyTabTransaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get historyTabTransaction;

  /// No description provided for @historyTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Invoice'**
  String get historyTabPending;

  /// No description provided for @historyEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get historyEmptyAll;

  /// No description provided for @historyEmptyTransaction.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get historyEmptyTransaction;

  /// No description provided for @historyEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'No pending invoices'**
  String get historyEmptyPending;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load history. Check your connection and try again.'**
  String get historyLoadError;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTitle;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'ORDER NO.'**
  String get orderNumberLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get priceLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'ITEMS'**
  String get itemsLabel;

  /// No description provided for @recognizedOrder.
  ///
  /// In en, this message translates to:
  /// **'Recognized Order'**
  String get recognizedOrder;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @liveLabel.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveLabel;

  /// No description provided for @orderViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get orderViewDetails;

  /// No description provided for @orderRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat Order'**
  String get orderRepeat;

  /// No description provided for @orderPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get orderPayNow;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statusUnpaid;

  /// No description provided for @invoiceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order. Check your connection and try again.'**
  String get invoiceLoadError;

  /// No description provided for @invoiceItemsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order\'s items.'**
  String get invoiceItemsLoadError;

  /// No description provided for @invoiceNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items found for this order.'**
  String get invoiceNoItems;

  /// No description provided for @invoiceNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Invoice will be available after order confirmation.'**
  String get invoiceNotAvailableYet;

  /// No description provided for @invoiceDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invoice downloaded successfully.'**
  String get invoiceDownloadSuccess;

  /// No description provided for @invoiceDownloadFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to download invoice. Please try again.'**
  String get invoiceDownloadFailure;

  /// No description provided for @invoiceWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get invoiceWaitingTitle;

  /// No description provided for @invoiceWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The final amount and invoice will be available once the wholesaler confirms this order.'**
  String get invoiceWaitingBody;

  /// No description provided for @voiceOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Order'**
  String get voiceOrderTitle;

  /// No description provided for @voiceOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic and speak your order items'**
  String get voiceOrderSubtitle;

  /// No description provided for @voiceOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Speak like \"20 kilo tamatar\" or \"kal ka order repeat  karo\"'**
  String get voiceOrderHint;

  /// No description provided for @voiceGenerateList.
  ///
  /// In en, this message translates to:
  /// **'Generate List'**
  String get voiceGenerateList;

  /// No description provided for @voiceErrorNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t hear an order. Please try again.'**
  String get voiceErrorNoSpeech;

  /// No description provided for @voiceErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to use voice ordering.'**
  String get voiceErrorPermission;

  /// No description provided for @voiceErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice ordering isn\'t available on this device.'**
  String get voiceErrorUnavailable;

  /// No description provided for @voiceErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while listening. Please try again.'**
  String get voiceErrorGeneric;

  /// No description provided for @voiceErrorNoItems.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any items from your order.'**
  String get voiceErrorNoItems;

  /// No description provided for @voiceErrorCatalog.
  ///
  /// In en, this message translates to:
  /// **'Could not load the item catalog. Check your connection and try again.'**
  String get voiceErrorCatalog;

  /// No description provided for @voiceAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {added} item(s) to your cart. Couldn\'t identify {unmatched} item(s).'**
  String voiceAddedToCart(int added, int unmatched);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
