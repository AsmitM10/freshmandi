// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'फ्रेशमंडी';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get navHome => 'होम';

  @override
  String get navShop => 'दुकान';

  @override
  String get navHistory => 'इतिहास';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsSubtitle =>
      'अपने खाते और ऐप प्राथमिकताओं को प्रबंधित करें';

  @override
  String get settingsBusinessDetailsTitle => 'व्यवसाय विवरण';

  @override
  String get settingsBusinessDetailsSubtitle =>
      'अपनी व्यवसाय जानकारी देखें और प्रबंधित करें';

  @override
  String get settingsPrivacyPolicyTitle => 'गोपनीयता नीति';

  @override
  String get settingsPrivacyPolicySubtitle => 'हमारी गोपनीयता नीति पढ़ें';

  @override
  String get settingsAboutUsTitle => 'हमारे बारे में';

  @override
  String get settingsAboutUsSubtitle => 'हमारे ऐप और टीम के बारे में और जानें';

  @override
  String get settingsLanguageTitle => 'भाषा';

  @override
  String get settingsLanguageSubtitle => 'अपनी पसंदीदा भाषा बदलें';

  @override
  String get settingsReturnOrderTitle => 'ऑर्डर वापस करें';

  @override
  String get settingsReturnOrderSubtitle =>
      'रिटर्न नीति देखें और अनुरोध दर्ज करें';

  @override
  String get settingsTermsTitle => 'नियम और शर्तें';

  @override
  String get settingsTermsSubtitle => 'अपने अधिकार और जिम्मेदारियां जानें।';

  @override
  String get settingsHelpTitle => 'मदद चाहिए?';

  @override
  String get settingsHelpSubtitle => 'हम आपकी सहायता के लिए यहाँ हैं।';

  @override
  String settingsComingSoon(String label) {
    return '$label जल्द ही उपलब्ध होगा';
  }

  @override
  String get languageScreenTitle => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get homeGreetingSubtitle => 'आज के अपने रूटीन का पालन करें';

  @override
  String get homeDefaultRestaurantName => 'रेस्टोरेंट';

  @override
  String get homeBrowseCategory => 'श्रेणियां देखें';

  @override
  String get homeFrequentlyOrdered => 'अक्सर ऑर्डर किए गए';

  @override
  String get homeFrequentlyOrderedEmpty =>
      'आपके पहले ऑर्डर के बाद अक्सर मंगाई जाने वाली वस्तुएं यहाँ दिखाई देंगी।';

  @override
  String get shopTitle => 'दुकान';

  @override
  String get shopSearchHint => 'सब्ज़ियां, फल खोजें...';

  @override
  String get shopLoadError =>
      'वस्तुएं लोड नहीं हो सकीं। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get shopNoSearchResults => 'आपकी खोज से कोई वस्तु मेल नहीं खाती।';

  @override
  String get shopNoCategoryItems => 'इस श्रेणी में अभी कोई वस्तु नहीं है।';

  @override
  String get categoryIndianVegetables => 'भारतीय सब्ज़ियां';

  @override
  String get categoryFruits => 'फल';

  @override
  String get categoryExoticVeg => 'विदेशी सब्ज़ियां';

  @override
  String get cartTitle => 'कार्ट';

  @override
  String get cartAddItem => 'वस्तु जोड़ें';

  @override
  String get cartPlaceOrder => 'ऑर्डर करें';

  @override
  String get cartTotalItems => 'कुल वस्तुएं';

  @override
  String get cartEmpty => 'आपका कार्ट खाली है।';

  @override
  String get cartBrowseShop => 'दुकान देखें';

  @override
  String get cartLoadError =>
      'आपका कार्ट लोड नहीं हो सका। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get historyTitle => 'इतिहास';

  @override
  String get historySubtitle => 'रोज़ ताज़ा और हाथ से चुनी गई सब्ज़ियां';

  @override
  String get historyTabAll => 'सभी ऑर्डर';

  @override
  String get historyTabTransaction => 'लेन-देन';

  @override
  String get historyTabPending => 'लंबित इनवॉइस';

  @override
  String get historyEmptyAll => 'अभी तक कोई ऑर्डर नहीं';

  @override
  String get historyEmptyTransaction => 'अभी तक कोई लेन-देन नहीं';

  @override
  String get historyEmptyPending => 'कोई लंबित इनवॉइस नहीं';

  @override
  String get historyLoadError =>
      'इतिहास लोड नहीं हो सका। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get invoiceTitle => 'इनवॉइस';

  @override
  String get orderNumberLabel => 'ऑर्डर नंबर';

  @override
  String get priceLabel => 'मूल्य';

  @override
  String get itemsLabel => 'वस्तुएं';

  @override
  String get recognizedOrder => 'पहचाना गया ऑर्डर';

  @override
  String get quantityLabel => 'मात्रा';

  @override
  String get liveLabel => 'लाइव';

  @override
  String get orderViewDetails => 'विवरण देखें';

  @override
  String get orderRepeat => 'ऑर्डर दोहराएं';

  @override
  String get orderPayNow => 'अभी भुगतान करें';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusPaid => 'भुगतान हो गया';

  @override
  String get statusUnpaid => 'भुगतान बाकी';

  @override
  String get invoiceLoadError =>
      'यह ऑर्डर लोड नहीं हो सका। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get invoiceItemsLoadError => 'इस ऑर्डर की वस्तुएं लोड नहीं हो सकीं।';

  @override
  String get invoiceNoItems => 'इस ऑर्डर के लिए कोई वस्तु नहीं मिली।';

  @override
  String get invoiceNotAvailableYet =>
      'ऑर्डर की पुष्टि होने के बाद इनवॉइस उपलब्ध होगा।';

  @override
  String get invoiceDownloadSuccess => 'इनवॉइस सफलतापूर्वक डाउनलोड हो गया।';

  @override
  String get invoiceDownloadFailure =>
      'इनवॉइस डाउनलोड नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get invoiceWaitingTitle => 'पुष्टि की प्रतीक्षा है';

  @override
  String get invoiceWaitingBody =>
      'थोक विक्रेता द्वारा इस ऑर्डर की पुष्टि होने पर अंतिम राशि और इनवॉइस उपलब्ध होंगे।';

  @override
  String get voiceOrderTitle => 'वॉइस ऑर्डर';

  @override
  String get voiceOrderSubtitle => 'माइक पर टैप करें और अपना ऑर्डर बोलें';

  @override
  String get voiceOrderHint =>
      'इस तरह बोलें \"20 किलो टमाटर\" या \"कल का ऑर्डर रिपीट करो\"';

  @override
  String get voiceGenerateList => 'सूची बनाएं';

  @override
  String get voiceErrorNoSpeech =>
      'हमें कोई ऑर्डर सुनाई नहीं दिया। कृपया पुनः प्रयास करें।';

  @override
  String get voiceErrorPermission =>
      'वॉइस ऑर्डरिंग के लिए माइक्रोफ़ोन की अनुमति आवश्यक है।';

  @override
  String get voiceErrorUnavailable =>
      'इस डिवाइस पर वॉइस ऑर्डरिंग उपलब्ध नहीं है।';

  @override
  String get voiceErrorGeneric =>
      'सुनते समय कुछ गड़बड़ हो गई। कृपया पुनः प्रयास करें।';

  @override
  String get voiceErrorNoItems => 'आपके ऑर्डर से कोई वस्तु नहीं मिली।';

  @override
  String get voiceErrorCatalog =>
      'वस्तु सूची लोड नहीं हो सकी। अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String voiceAddedToCart(int added, int unmatched) {
    return 'आपके कार्ट में $added वस्तुएं जोड़ी गईं। $unmatched वस्तुओं की पहचान नहीं हो सकी।';
  }
}
