import 'package:flutter/foundation.dart';

class UcpNavigationState {
  final String tab;
  final String? subItem;

  const UcpNavigationState({
    required this.tab,
    this.subItem,
  });
}

class UcpStateService {
  UcpStateService._();

  static final ValueNotifier<UcpNavigationState> navigationState =
      ValueNotifier<UcpNavigationState>(const UcpNavigationState(tab: 'Tổng quan'));

  // Callbacks để Breadcrumb có thể điều khiển lại UcpScreen khi người dùng click vào breadcrumb
  static VoidCallback? onResetToOverview;
  static ValueChanged<int>? onSelectTab;
  static VoidCallback? onClearSubItem;

  static void setTab(String tabName) {
    navigationState.value = UcpNavigationState(tab: tabName, subItem: null);
  }

  static void setSubItem(String tabName, String subItemName) {
    navigationState.value = UcpNavigationState(tab: tabName, subItem: subItemName);
  }

  static void reset() {
    navigationState.value = const UcpNavigationState(tab: 'Tổng quan', subItem: null);
  }
}
