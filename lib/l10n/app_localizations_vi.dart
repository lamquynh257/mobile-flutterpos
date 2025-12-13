// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get main_title => 'Chương trình POS';

  @override
  String get generic_deleteQuestion => 'Xóa?';

  @override
  String get generic_yes => 'Có';

  @override
  String get generic_no => 'Không';

  @override
  String get generic_confirm => 'Xác nhận';

  @override
  String get generic_cancel => 'Hủy';

  @override
  String get generic_empty => 'Không có dữ liệu';

  @override
  String get lobby => 'Sảnh';

  @override
  String get lobby_drawerHeader => 'POS';

  @override
  String get lobby_report => 'Báo cáo';

  @override
  String get lobby_journal => 'Nhật ký nhập hàng';

  @override
  String get lobby_menuEdit => 'Chỉnh sửa thực đơn';

  @override
  String get details_discount => 'Khuyến mãi';

  @override
  String details_discountTxt(String total, String discountPct) {
    return 'Tổng: $total, giảm: $discountPct%';
  }

  @override
  String get details_liDeleted => '(đã xóa)';

  @override
  String get details_customerPay => 'Khách trả';

  @override
  String get details_notEnough => 'Không đủ';

  @override
  String get menu_confirm => 'Xác nhận đơn';

  @override
  String get menu_undo => 'Undo';

  @override
  String get edit_menu_node => 'Bấm để đặt tên bàn';

  @override
  String get edit_menu_filterHint => 'Lọc bằng tên món..';

  @override
  String get edit_menu_formLabel => 'Tên món';

  @override
  String get edit_menu_formPrice => 'Giá';

  @override
  String get history_toggleDiscount => 'Áp giá KM';

  @override
  String get history_delPopUpTitle => 'Bỏ qua đơn này?';

  @override
  String get history_rangePickerHelpTxt => 'Chọn khoản ngày';

  @override
  String get journal_entry => 'Mục';

  @override
  String get journal_entryHint => 'Mô tả đơn';

  @override
  String get journal_entryReqTxt => 'Mô tả không được rỗng';

  @override
  String get journal_amt => 'Đơn giá';

  @override
  String get journal_datetime => 'Thời gian';
}
