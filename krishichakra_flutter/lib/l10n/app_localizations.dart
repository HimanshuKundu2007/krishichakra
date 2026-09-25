import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('mr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KrishiChakra'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @markets.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get markets;

  /// No description provided for @myLots.
  ///
  /// In en, this message translates to:
  /// **'My Lots'**
  String get myLots;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @liveMandiPulse.
  ///
  /// In en, this message translates to:
  /// **'Live Mandi Pulse'**
  String get liveMandiPulse;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @whatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// No description provided for @sellProduceGetBuyerBids.
  ///
  /// In en, this message translates to:
  /// **'Sell Produce & Get Buyer Bids'**
  String get sellProduceGetBuyerBids;

  /// No description provided for @createHarvestLot.
  ///
  /// In en, this message translates to:
  /// **'Create Harvest Lot'**
  String get createHarvestLot;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get recommended;

  /// No description provided for @netProfitMandiCalculator.
  ///
  /// In en, this message translates to:
  /// **'Net Profit & Mandi Calculator'**
  String get netProfitMandiCalculator;

  /// No description provided for @findHighestPayingMandi.
  ///
  /// In en, this message translates to:
  /// **'Find Highest Paying Mandi'**
  String get findHighestPayingMandi;

  /// No description provided for @coldStorageInstantLoan.
  ///
  /// In en, this message translates to:
  /// **'Cold Storage & 70% Instant Cash Loan'**
  String get coldStorageInstantLoan;

  /// No description provided for @coldStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'e-NWR • MSWC • Book Storage & Apply for Loan'**
  String get coldStorageSubtitle;

  /// No description provided for @discountedTransport.
  ///
  /// In en, this message translates to:
  /// **'Discounted Return-Truck Transport'**
  String get discountedTransport;

  /// No description provided for @discountedTransportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'35% freight discount • Book Logistics'**
  String get discountedTransportSubtitle;

  /// No description provided for @verifiedFarmer.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED FARMER'**
  String get verifiedFarmer;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'[Change]'**
  String get change;

  /// No description provided for @govAgriStackReady.
  ///
  /// In en, this message translates to:
  /// **'Government Agri Stack Ready • e-NAM & MSWC Integrated'**
  String get govAgriStackReady;

  /// No description provided for @mandiLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'5G MandiLink'**
  String get mandiLinkSubtitle;

  /// No description provided for @topBid.
  ///
  /// In en, this message translates to:
  /// **'Top Bid'**
  String get topBid;

  /// No description provided for @reviewOffers.
  ///
  /// In en, this message translates to:
  /// **'Review Offers'**
  String get reviewOffers;

  /// No description provided for @trackTransit.
  ///
  /// In en, this message translates to:
  /// **'Track Transit'**
  String get trackTransit;

  /// No description provided for @tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak: \\\'Sell 20Q Onion\\\' or \\\'Check Vashi Bhav\\\''**
  String get tapToSpeak;

  /// No description provided for @loadingGovData.
  ///
  /// In en, this message translates to:
  /// **'Loading government market data...'**
  String get loadingGovData;

  /// No description provided for @govSourceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Government source temporarily unavailable.'**
  String get govSourceUnavailable;

  /// No description provided for @noMarketDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No market data available for this commodity.'**
  String get noMarketDataAvailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @liveMandiRates.
  ///
  /// In en, this message translates to:
  /// **'Live Mandi Rates'**
  String get liveMandiRates;

  /// No description provided for @searchCrop.
  ///
  /// In en, this message translates to:
  /// **'Search crop'**
  String get searchCrop;

  /// No description provided for @allCrops.
  ///
  /// In en, this message translates to:
  /// **'All Crops'**
  String get allCrops;

  /// No description provided for @within50km.
  ///
  /// In en, this message translates to:
  /// **'Within 50km'**
  String get within50km;

  /// No description provided for @within150km.
  ///
  /// In en, this message translates to:
  /// **'Within 150km'**
  String get within150km;

  /// No description provided for @allMaharashtra.
  ///
  /// In en, this message translates to:
  /// **'All Maharashtra'**
  String get allMaharashtra;

  /// No description provided for @allIndia.
  ///
  /// In en, this message translates to:
  /// **'All India'**
  String get allIndia;

  /// No description provided for @maharashtraFocus.
  ///
  /// In en, this message translates to:
  /// **'Maharashtra Focus'**
  String get maharashtraFocus;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @variety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get variety;

  /// No description provided for @allStates.
  ///
  /// In en, this message translates to:
  /// **'All States'**
  String get allStates;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All Districts'**
  String get allDistricts;

  /// No description provided for @allMarkets.
  ///
  /// In en, this message translates to:
  /// **'All Markets'**
  String get allMarkets;

  /// No description provided for @allVarieties.
  ///
  /// In en, this message translates to:
  /// **'All Varieties'**
  String get allVarieties;

  /// No description provided for @modalPrice.
  ///
  /// In en, this message translates to:
  /// **'Modal Price'**
  String get modalPrice;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @latestModal.
  ///
  /// In en, this message translates to:
  /// **'Latest Modal'**
  String get latestModal;

  /// No description provided for @periodMin.
  ///
  /// In en, this message translates to:
  /// **'Period Min'**
  String get periodMin;

  /// No description provided for @periodMax.
  ///
  /// In en, this message translates to:
  /// **'Period Max'**
  String get periodMax;

  /// No description provided for @avgModal.
  ///
  /// In en, this message translates to:
  /// **'Avg Modal'**
  String get avgModal;

  /// No description provided for @modalPriceMovement.
  ///
  /// In en, this message translates to:
  /// **'Modal Price Movement'**
  String get modalPriceMovement;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get days30;

  /// No description provided for @year1.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get year1;

  /// No description provided for @daysRecorded.
  ///
  /// In en, this message translates to:
  /// **'Days Recorded'**
  String get daysRecorded;

  /// No description provided for @govMarketPriceSummary.
  ///
  /// In en, this message translates to:
  /// **'Government Market Price Summary'**
  String get govMarketPriceSummary;

  /// No description provided for @arrivalPriceTimeline.
  ///
  /// In en, this message translates to:
  /// **'Arrival Price Timeline'**
  String get arrivalPriceTimeline;

  /// No description provided for @govDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Government data unavailable'**
  String get govDataUnavailable;

  /// No description provided for @noMarketReport.
  ///
  /// In en, this message translates to:
  /// **'No market report'**
  String get noMarketReport;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @govDataUnavailableForDate.
  ///
  /// In en, this message translates to:
  /// **'Government data unavailable for this date.'**
  String get govDataUnavailableForDate;

  /// No description provided for @sellProduce.
  ///
  /// In en, this message translates to:
  /// **'Sell Produce'**
  String get sellProduce;

  /// No description provided for @buyerBidsAndMatches.
  ///
  /// In en, this message translates to:
  /// **'Buyer Bids & Matches'**
  String get buyerBidsAndMatches;

  /// No description provided for @noBuyersMatched.
  ///
  /// In en, this message translates to:
  /// **'No Buyers Matched'**
  String get noBuyersMatched;

  /// No description provided for @noBuyersMatchedDesc.
  ///
  /// In en, this message translates to:
  /// **'No buyers currently match your lot. Try adjusting quantity or grade.'**
  String get noBuyersMatchedDesc;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get checkAgain;

  /// No description provided for @matchScore.
  ///
  /// In en, this message translates to:
  /// **'Match Score'**
  String get matchScore;

  /// No description provided for @quantityFit.
  ///
  /// In en, this message translates to:
  /// **'Quantity Fit'**
  String get quantityFit;

  /// No description provided for @qualityFit.
  ///
  /// In en, this message translates to:
  /// **'Quality Fit'**
  String get qualityFit;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @paymentReliability.
  ///
  /// In en, this message translates to:
  /// **'Payment Reliability'**
  String get paymentReliability;

  /// No description provided for @contactBuyer.
  ///
  /// In en, this message translates to:
  /// **'Contact Buyer'**
  String get contactBuyer;

  /// No description provided for @negotiateOffer.
  ///
  /// In en, this message translates to:
  /// **'Negotiate Offer'**
  String get negotiateOffer;

  /// No description provided for @myLotsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Lots'**
  String get myLotsTitle;

  /// No description provided for @noLotsYet.
  ///
  /// In en, this message translates to:
  /// **'No produce lots yet'**
  String get noLotsYet;

  /// No description provided for @createFirstLot.
  ///
  /// In en, this message translates to:
  /// **'Create your first lot to get buyer bids'**
  String get createFirstLot;

  /// No description provided for @createLot.
  ///
  /// In en, this message translates to:
  /// **'Create Lot'**
  String get createLot;

  /// No description provided for @lotDetails.
  ///
  /// In en, this message translates to:
  /// **'Lot Details'**
  String get lotDetails;

  /// No description provided for @commodity.
  ///
  /// In en, this message translates to:
  /// **'Commodity'**
  String get commodity;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @netRealizationCalculator.
  ///
  /// In en, this message translates to:
  /// **'Net Realization Calculator'**
  String get netRealizationCalculator;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @freightCost.
  ///
  /// In en, this message translates to:
  /// **'Freight Cost'**
  String get freightCost;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @netRealization.
  ///
  /// In en, this message translates to:
  /// **'Net Realization'**
  String get netRealization;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @farmerProfile.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile'**
  String get farmerProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get marathi;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get hindi;

  /// No description provided for @coldStorage.
  ///
  /// In en, this message translates to:
  /// **'Cold Storage'**
  String get coldStorage;

  /// No description provided for @bookStorage.
  ///
  /// In en, this message translates to:
  /// **'Book Storage'**
  String get bookStorage;

  /// No description provided for @storageAvailable.
  ///
  /// In en, this message translates to:
  /// **'Storage Available'**
  String get storageAvailable;

  /// No description provided for @applyForLoan.
  ///
  /// In en, this message translates to:
  /// **'Apply for Loan'**
  String get applyForLoan;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @bookTransport.
  ///
  /// In en, this message translates to:
  /// **'Book Transport'**
  String get bookTransport;

  /// No description provided for @availableTrucks.
  ///
  /// In en, this message translates to:
  /// **'Available Trucks'**
  String get availableTrucks;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @disputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get disputeTitle;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get chatbot;

  /// No description provided for @chatbotHint.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about crop prices...'**
  String get chatbotHint;

  /// No description provided for @fpoAggregation.
  ///
  /// In en, this message translates to:
  /// **'FPO Batch Aggregation'**
  String get fpoAggregation;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmAction;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @arrivalDate.
  ///
  /// In en, this message translates to:
  /// **'Arrival Date'**
  String get arrivalDate;

  /// No description provided for @arrivals.
  ///
  /// In en, this message translates to:
  /// **'Arrivals'**
  String get arrivals;

  /// No description provided for @totalArrivals.
  ///
  /// In en, this message translates to:
  /// **'Total Arrivals'**
  String get totalArrivals;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price History'**
  String get priceHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No price history available'**
  String get noHistory;

  /// No description provided for @commodityTomato.
  ///
  /// In en, this message translates to:
  /// **'Tomato'**
  String get commodityTomato;

  /// No description provided for @commodityOnion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get commodityOnion;

  /// No description provided for @commodityPotato.
  ///
  /// In en, this message translates to:
  /// **'Potato'**
  String get commodityPotato;

  /// No description provided for @commodityGuava.
  ///
  /// In en, this message translates to:
  /// **'Guava'**
  String get commodityGuava;

  /// No description provided for @commodityGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grapes'**
  String get commodityGrapes;

  /// No description provided for @commodityWheat.
  ///
  /// In en, this message translates to:
  /// **'Wheat'**
  String get commodityWheat;

  /// No description provided for @commoditySoybean.
  ///
  /// In en, this message translates to:
  /// **'Soybean'**
  String get commoditySoybean;

  /// No description provided for @commodityCotton.
  ///
  /// In en, this message translates to:
  /// **'Cotton'**
  String get commodityCotton;

  /// No description provided for @commodityPomegranate.
  ///
  /// In en, this message translates to:
  /// **'Pomegranate'**
  String get commodityPomegranate;

  /// No description provided for @commodityBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get commodityBanana;

  /// No description provided for @commodityMaize.
  ///
  /// In en, this message translates to:
  /// **'Maize'**
  String get commodityMaize;

  /// No description provided for @commodityRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get commodityRice;

  /// No description provided for @commodityGarlic.
  ///
  /// In en, this message translates to:
  /// **'Garlic'**
  String get commodityGarlic;

  /// No description provided for @commodityGinger.
  ///
  /// In en, this message translates to:
  /// **'Ginger'**
  String get commodityGinger;

  /// No description provided for @perQuintal.
  ///
  /// In en, this message translates to:
  /// **'/Q'**
  String get perQuintal;

  /// No description provided for @quintal.
  ///
  /// In en, this message translates to:
  /// **'Quintal'**
  String get quintal;

  /// No description provided for @consignmentSettlement.
  ///
  /// In en, this message translates to:
  /// **'Consignment Settlement'**
  String get consignmentSettlement;

  /// No description provided for @settlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Settlement Amount'**
  String get settlementAmount;

  /// No description provided for @voiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Voice Search'**
  String get voiceSearch;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @tapToStopListening.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get tapToStopListening;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @farmerAccount.
  ///
  /// In en, this message translates to:
  /// **'Farmer Account'**
  String get farmerAccount;

  /// No description provided for @landHolding.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get landHolding;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @fpoMembership.
  ///
  /// In en, this message translates to:
  /// **'FPO Membership'**
  String get fpoMembership;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @priceAlertSettings.
  ///
  /// In en, this message translates to:
  /// **'Price Alert Settings'**
  String get priceAlertSettings;

  /// No description provided for @downloadTransactionReport.
  ///
  /// In en, this message translates to:
  /// **'Download Transaction Report'**
  String get downloadTransactionReport;

  /// No description provided for @contactKisanAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Contact Kisan Advisor'**
  String get contactKisanAdvisor;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @languagePreference.
  ///
  /// In en, this message translates to:
  /// **'Language Preference'**
  String get languagePreference;

  /// No description provided for @officialAgmarknetRates.
  ///
  /// In en, this message translates to:
  /// **'Official Agmarknet / data.gov.in rates'**
  String get officialAgmarknetRates;

  /// No description provided for @refreshGovRates.
  ///
  /// In en, this message translates to:
  /// **'Refresh Gov Rates'**
  String get refreshGovRates;

  /// No description provided for @searchCropHint.
  ///
  /// In en, this message translates to:
  /// **'Search crop e.g. Onion, Tomato, Soybean'**
  String get searchCropHint;

  /// No description provided for @eNamVerified.
  ///
  /// In en, this message translates to:
  /// **'e-NAM Verified'**
  String get eNamVerified;

  /// No description provided for @maharashtraFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Maharashtra (Focus)'**
  String get maharashtraFocusLabel;

  /// No description provided for @allIndiaMandis.
  ///
  /// In en, this message translates to:
  /// **'All India (All Mandis)'**
  String get allIndiaMandis;

  /// No description provided for @allMaharashtraLabel.
  ///
  /// In en, this message translates to:
  /// **'All Maharashtra'**
  String get allMaharashtraLabel;

  /// No description provided for @allIndiaLabel.
  ///
  /// In en, this message translates to:
  /// **'All India'**
  String get allIndiaLabel;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllFilters;

  /// No description provided for @topModalRate.
  ///
  /// In en, this message translates to:
  /// **'Top Modal Rate'**
  String get topModalRate;

  /// No description provided for @noGovDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No government market data is currently available.'**
  String get noGovDataAvailable;

  /// No description provided for @noGovDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Official Agmarknet / data.gov.in rates have not yet been synchronized. No fake or demo prices are substituted.'**
  String get noGovDataSubtitle;

  /// No description provided for @synchronizeWithAgmarknet.
  ///
  /// In en, this message translates to:
  /// **'Synchronize with Agmarknet'**
  String get synchronizeWithAgmarknet;

  /// No description provided for @triggeringGovSync.
  ///
  /// In en, this message translates to:
  /// **'Triggering government mandi sync...'**
  String get triggeringGovSync;

  /// No description provided for @noMarketDataForCommodity.
  ///
  /// In en, this message translates to:
  /// **'No market data available for this commodity.'**
  String get noMarketDataForCommodity;

  /// No description provided for @showingLastAvailableData.
  ///
  /// In en, this message translates to:
  /// **'Showing last available government data'**
  String get showingLastAvailableData;

  /// No description provided for @liveTradeFeed.
  ///
  /// In en, this message translates to:
  /// **'Live Trade Feed'**
  String get liveTradeFeed;

  /// No description provided for @priceMovement.
  ///
  /// In en, this message translates to:
  /// **'Price Movement'**
  String get priceMovement;

  /// No description provided for @historicalPrices.
  ///
  /// In en, this message translates to:
  /// **'Historical Prices'**
  String get historicalPrices;

  /// No description provided for @calculateNetRealization.
  ///
  /// In en, this message translates to:
  /// **'Calculate Net Realization'**
  String get calculateNetRealization;

  /// No description provided for @myProduceLots.
  ///
  /// In en, this message translates to:
  /// **'My Produce Lots'**
  String get myProduceLots;

  /// No description provided for @newLot.
  ///
  /// In en, this message translates to:
  /// **'+ New Lot'**
  String get newLot;

  /// No description provided for @createProduceLot.
  ///
  /// In en, this message translates to:
  /// **'Create Produce Lot'**
  String get createProduceLot;

  /// No description provided for @viewBuyerBids.
  ///
  /// In en, this message translates to:
  /// **'View Buyer Bids'**
  String get viewBuyerBids;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @expectedPrice.
  ///
  /// In en, this message translates to:
  /// **'Expected Price'**
  String get expectedPrice;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @submitLot.
  ///
  /// In en, this message translates to:
  /// **'Submit Lot'**
  String get submitLot;

  /// No description provided for @buyerBidsMatches.
  ///
  /// In en, this message translates to:
  /// **'Buyer Bids & Matches'**
  String get buyerBidsMatches;

  /// No description provided for @offeredPrice.
  ///
  /// In en, this message translates to:
  /// **'Offered Price'**
  String get offeredPrice;

  /// No description provided for @acceptBid.
  ///
  /// In en, this message translates to:
  /// **'Accept Bid'**
  String get acceptBid;

  /// No description provided for @counterOffer.
  ///
  /// In en, this message translates to:
  /// **'Counter Offer'**
  String get counterOffer;

  /// No description provided for @verifiedBuyer.
  ///
  /// In en, this message translates to:
  /// **'Verified Buyer'**
  String get verifiedBuyer;

  /// No description provided for @matchingBuyers.
  ///
  /// In en, this message translates to:
  /// **'Matching verified buyers against lot specifications...'**
  String get matchingBuyers;

  /// No description provided for @netRealizationCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Net Realization Calculator'**
  String get netRealizationCalculatorTitle;

  /// No description provided for @selectCommodity.
  ///
  /// In en, this message translates to:
  /// **'Select Commodity'**
  String get selectCommodity;

  /// No description provided for @selectMandi.
  ///
  /// In en, this message translates to:
  /// **'Select Mandi'**
  String get selectMandi;

  /// No description provided for @quantityInQuintals.
  ///
  /// In en, this message translates to:
  /// **'Quantity (Quintals)'**
  String get quantityInQuintals;

  /// No description provided for @transportCost.
  ///
  /// In en, this message translates to:
  /// **'Transport Cost'**
  String get transportCost;

  /// No description provided for @commissionRate.
  ///
  /// In en, this message translates to:
  /// **'Commission Rate (%)'**
  String get commissionRate;

  /// No description provided for @otherDeductions.
  ///
  /// In en, this message translates to:
  /// **'Other Deductions'**
  String get otherDeductions;

  /// No description provided for @grossRealization.
  ///
  /// In en, this message translates to:
  /// **'Gross Realization'**
  String get grossRealization;

  /// No description provided for @totalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Total Deductions'**
  String get totalDeductions;

  /// No description provided for @netRealizationResult.
  ///
  /// In en, this message translates to:
  /// **'Net Realization'**
  String get netRealizationResult;

  /// No description provided for @profitPerQuintal.
  ///
  /// In en, this message translates to:
  /// **'Profit/Quintal'**
  String get profitPerQuintal;

  /// No description provided for @resetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetBtn;

  /// No description provided for @bestMandiComparison.
  ///
  /// In en, this message translates to:
  /// **'Best Mandi Comparison'**
  String get bestMandiComparison;

  /// No description provided for @chatWithKrishiAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Chat with Krishi Advisor'**
  String get chatWithKrishiAdvisor;

  /// No description provided for @typeYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type your question...'**
  String get typeYourQuestion;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @suggestedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested Questions'**
  String get suggestedQuestions;

  /// No description provided for @aiPrototypeBadge.
  ///
  /// In en, this message translates to:
  /// **'Rule-Based Prototype'**
  String get aiPrototypeBadge;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get enterPhone;

  /// No description provided for @getOtp.
  ///
  /// In en, this message translates to:
  /// **'Get OTP'**
  String get getOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify & Enter'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer / FPO'**
  String get farmer;

  /// No description provided for @buyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer / Trader'**
  String get buyer;

  /// No description provided for @transporter.
  ///
  /// In en, this message translates to:
  /// **'Transporter'**
  String get transporter;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select your role'**
  String get selectRole;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @trustedBy.
  ///
  /// In en, this message translates to:
  /// **'Trusted by 10,000+ farmers'**
  String get trustedBy;

  /// No description provided for @bookLogistics.
  ///
  /// In en, this message translates to:
  /// **'Book Logistics'**
  String get bookLogistics;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @dropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop Location'**
  String get dropLocation;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get estimatedCost;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @trackVehicle.
  ///
  /// In en, this message translates to:
  /// **'Track Vehicle'**
  String get trackVehicle;

  /// No description provided for @coldStorageBooking.
  ///
  /// In en, this message translates to:
  /// **'Cold Storage Booking'**
  String get coldStorageBooking;

  /// No description provided for @storageDuration.
  ///
  /// In en, this message translates to:
  /// **'Storage Duration'**
  String get storageDuration;

  /// No description provided for @storageCapacity.
  ///
  /// In en, this message translates to:
  /// **'Storage Capacity'**
  String get storageCapacity;

  /// No description provided for @applyNWR.
  ///
  /// In en, this message translates to:
  /// **'Apply for NWR Loan'**
  String get applyNWR;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @settlementSummary.
  ///
  /// In en, this message translates to:
  /// **'Settlement Summary'**
  String get settlementSummary;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get downloadInvoice;

  /// No description provided for @raiseDispute.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get raiseDispute;

  /// No description provided for @disputeDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue'**
  String get disputeDescription;

  /// No description provided for @submitDispute.
  ///
  /// In en, this message translates to:
  /// **'Submit Dispute'**
  String get submitDispute;

  /// No description provided for @disputeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted successfully'**
  String get disputeSubmitted;

  /// No description provided for @noDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes filed'**
  String get noDisputes;

  /// No description provided for @fpoBatchAggregation.
  ///
  /// In en, this message translates to:
  /// **'FPO Batch Aggregation'**
  String get fpoBatchAggregation;

  /// No description provided for @addFarmer.
  ///
  /// In en, this message translates to:
  /// **'Add Farmer'**
  String get addFarmer;

  /// No description provided for @totalBatch.
  ///
  /// In en, this message translates to:
  /// **'Total Batch'**
  String get totalBatch;

  /// No description provided for @farmersInBatch.
  ///
  /// In en, this message translates to:
  /// **'Farmers in Batch'**
  String get farmersInBatch;

  /// No description provided for @submitBatch.
  ///
  /// In en, this message translates to:
  /// **'Submit Batch'**
  String get submitBatch;

  /// No description provided for @batchSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Batch submitted successfully'**
  String get batchSubmitted;
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
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

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
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
