// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get main_title => 'POS app';

  @override
  String get generic_deleteQuestion => 'Delete?';

  @override
  String get generic_yes => 'Yes';

  @override
  String get generic_no => 'No';

  @override
  String get generic_confirm => 'Confirm';

  @override
  String get generic_cancel => 'Cancel';

  @override
  String get generic_empty => 'No data found';

  @override
  String get lobby => 'Lobby';

  @override
  String get lobby_drawerHeader => 'Simple POS';

  @override
  String get lobby_report => 'Report';

  @override
  String get lobby_journal => 'Expense Journal';

  @override
  String get lobby_menuEdit => 'Edit menu';

  @override
  String get details_discount => 'Discount';

  @override
  String details_discountTxt(String total, String discountPct) {
    return 'Total: $total, discounted: $discountPct%';
  }

  @override
  String get details_liDeleted => '(deleted)';

  @override
  String get details_customerPay => 'Customer pay';

  @override
  String get details_notEnough => 'Not enough';

  @override
  String get menu_confirm => 'Confirm Order';

  @override
  String get menu_undo => 'Undo';

  @override
  String get edit_menu_node => 'Click to set table name';

  @override
  String get edit_menu_filterHint => 'Filter by dish name..';

  @override
  String get edit_menu_formLabel => 'Dish';

  @override
  String get edit_menu_formPrice => 'Price';

  @override
  String get history_toggleDiscount => 'Apply Discount Rate';

  @override
  String get history_delPopUpTitle => 'Ignore this order?';

  @override
  String get history_rangePickerHelpTxt => 'Select range';

  @override
  String get journal_entry => 'Entry';

  @override
  String get journal_entryHint => 'Describe your entry';

  @override
  String get journal_entryReqTxt => 'Entry description is required';

  @override
  String get journal_amt => 'Amount';

  @override
  String get journal_datetime => 'Time';
}
