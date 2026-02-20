// ExecPrompt - AI LLM Mobile Client
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


import 'package:flutter/widgets.dart';

/// Layout tier breakpoints for adaptive UI.
///
/// PHONE   : < 600dp  — current layout unchanged
/// TABLET_S: 600–840dp — wider margins, maxWidth on chat
/// TABLET_L: 840–1200dp — persistent sidebar + chat (2-column)
/// DESKTOP : > 1200dp — sidebar + chat + detail panel (3-column)
enum LayoutTier {
  phone,
  tabletSmall,
  tabletLarge,
  desktop;

  static LayoutTier fromWidth(double width) {
    if (width >= 1200) return LayoutTier.desktop;
    if (width >= 840) return LayoutTier.tabletLarge;
    if (width >= 600) return LayoutTier.tabletSmall;
    return LayoutTier.phone;
  }

  bool get isPhone => this == LayoutTier.phone;
  bool get isTabletOrLarger => index >= LayoutTier.tabletSmall.index;
  bool get showSidebar => index >= LayoutTier.tabletLarge.index;
  bool get showDetailPanel => this == LayoutTier.desktop;
}

/// Responsive sizing helpers keyed by layout tier.
class ResponsiveSizes {
  final LayoutTier tier;
  const ResponsiveSizes(this.tier);

  // Sidebar width (TABLET-L and DESKTOP)
  double get sidebarWidth => tier == LayoutTier.desktop ? 280 : 280;

  // Detail panel width (DESKTOP only)
  double get detailPanelWidth => 320;

  // Max width for chat message bubbles
  double? get chatMaxWidth {
    switch (tier) {
      case LayoutTier.phone:
        return null; // full width
      case LayoutTier.tabletSmall:
        return 640;
      case LayoutTier.tabletLarge:
        return 720;
      case LayoutTier.desktop:
        return 720;
    }
  }

  // Content horizontal padding
  double get contentPadding {
    switch (tier) {
      case LayoutTier.phone:
        return 12;
      case LayoutTier.tabletSmall:
        return 20;
      case LayoutTier.tabletLarge:
        return 24;
      case LayoutTier.desktop:
        return 24;
    }
  }

  // Font sizes
  double get bodyFontSize {
    switch (tier) {
      case LayoutTier.phone:
        return 13;
      case LayoutTier.tabletSmall:
        return 14;
      case LayoutTier.tabletLarge:
      case LayoutTier.desktop:
        return 15;
    }
  }

  double get codeFontSize {
    switch (tier) {
      case LayoutTier.phone:
        return 12;
      case LayoutTier.tabletSmall:
        return 13;
      case LayoutTier.tabletLarge:
      case LayoutTier.desktop:
        return 14;
    }
  }

  double get labelFontSize {
    switch (tier) {
      case LayoutTier.phone:
        return 10;
      case LayoutTier.tabletSmall:
        return 11;
      case LayoutTier.tabletLarge:
      case LayoutTier.desktop:
        return 12;
    }
  }

  double get inputFontSize {
    switch (tier) {
      case LayoutTier.phone:
        return 14;
      case LayoutTier.tabletSmall:
        return 15;
      case LayoutTier.tabletLarge:
      case LayoutTier.desktop:
        return 16;
    }
  }

  double get messageBubblePadding {
    switch (tier) {
      case LayoutTier.phone:
        return 12;
      case LayoutTier.tabletSmall:
        return 14;
      case LayoutTier.tabletLarge:
      case LayoutTier.desktop:
        return 16;
    }
  }
}

/// Extension to get layout info from BuildContext.
extension ResponsiveContext on BuildContext {
  LayoutTier get layoutTier =>
      LayoutTier.fromWidth(MediaQuery.of(this).size.width);

  ResponsiveSizes get responsiveSizes =>
      ResponsiveSizes(layoutTier);

  bool get isTabletLayout =>
      layoutTier.showSidebar;
}
