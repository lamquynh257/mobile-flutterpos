import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi')
  ];

  /// No description provided for @main_title.
  ///
  /// In en, this message translates to:
  /// **'POS app'**
  String get main_title;

  /// No description provided for @generic_deleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get generic_deleteQuestion;

  /// No description provided for @generic_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get generic_yes;

  /// No description provided for @generic_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get generic_no;

  /// No description provided for @generic_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get generic_confirm;

  /// No description provided for @generic_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get generic_cancel;

  /// No description provided for @generic_empty.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get generic_empty;

  /// No description provided for @lobby.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get lobby;

  /// No description provided for @lobby_drawerHeader.
  ///
  /// In en, this message translates to:
  /// **'Simple POS'**
  String get lobby_drawerHeader;

  /// No description provided for @lobby_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get lobby_report;

  /// No description provided for @lobby_journal.
  ///
  /// In en, this message translates to:
  /// **'Expense Journal'**
  String get lobby_journal;

  /// No description provided for @lobby_menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit menu'**
  String get lobby_menuEdit;

  /// No description provided for @details_discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get details_discount;

  /// No description provided for @details_discountTxt.
  ///
  /// In en, this message translates to:
  /// **'Total: {total}, discounted: {discountPct}%'**
  String details_discountTxt(String total, String discountPct);

  /// No description provided for @details_liDeleted.
  ///
  /// In en, this message translates to:
  /// **'(deleted)'**
  String get details_liDeleted;

  /// No description provided for @details_customerPay.
  ///
  /// In en, this message translates to:
  /// **'Customer pay'**
  String get details_customerPay;

  /// No description provided for @details_notEnough.
  ///
  /// In en, this message translates to:
  /// **'Not enough'**
  String get details_notEnough;

  /// No description provided for @menu_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get menu_confirm;

  /// No description provided for @menu_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get menu_undo;

  /// No description provided for @edit_menu_node.
  ///
  /// In en, this message translates to:
  /// **'Click to set table name'**
  String get edit_menu_node;

  /// No description provided for @edit_menu_filterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by dish name..'**
  String get edit_menu_filterHint;

  /// No description provided for @edit_menu_formLabel.
  ///
  /// In en, this message translates to:
  /// **'Dish'**
  String get edit_menu_formLabel;

  /// No description provided for @edit_menu_formPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get edit_menu_formPrice;

  /// No description provided for @history_toggleDiscount.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount Rate'**
  String get history_toggleDiscount;

  /// No description provided for @history_delPopUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Ignore this order?'**
  String get history_delPopUpTitle;

  /// No description provided for @history_rangePickerHelpTxt.
  ///
  /// In en, this message translates to:
  /// **'Select range'**
  String get history_rangePickerHelpTxt;

  /// No description provided for @journal_entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get journal_entry;

  /// No description provided for @journal_entryHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your entry'**
  String get journal_entryHint;

  /// No description provided for @journal_entryReqTxt.
  ///
  /// In en, this message translates to:
  /// **'Entry description is required'**
  String get journal_entryReqTxt;

  /// No description provided for @journal_amt.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get journal_amt;

  /// No description provided for @journal_datetime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get journal_datetime;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
