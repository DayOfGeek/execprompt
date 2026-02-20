# ExecPrompt Flutter Style Guide

## Overview
This style guide documents the cyberpunk/futurism aesthetic of ExecPrompt, enabling you to create Flutter applications with the same distinctive terminal-inspired look and feel. The ExecPrompt design philosophy centers on retro-futuristic CRT terminal aesthetics combined with modern Material 3 design principles.

**Brand Identity:** DayOfGeek.com  
**Design Philosophy:** Cyberpunk Terminal / Retro-Futurism  
**Primary Inspiration:** Classic phosphor CRT terminals, synthwave aesthetics, cyberpunk interfaces

---

## Table of Contents
1. [Color Palettes](#color-palettes)
2. [Typography](#typography)
3. [Component Styling](#component-styling)
4. [Layout Principles](#layout-principles)
5. [Animations & Interactions](#animations--interactions)
6. [Theme Implementation](#theme-implementation)
7. [Code Examples](#code-examples)

---

## Color Palettes

ExecPrompt offers five distinctive cyberpunk-themed color palettes. Each palette follows the same structural roles but with different hues.

### Color Role System
Each theme uses a structured color system with specific semantic roles:

```dart
class CyberTermColors {
  final Color background;      // Main app background (darkest)
  final Color surface;         // Cards, panels, elevated surfaces
  final Color surfaceLight;    // Slightly lighter surfaces
  final Color primary;         // Primary accent (bright, glowing)
  final Color primaryDim;      // Dimmed primary for secondary elements
  final Color textColor;       // Main text (matches primary)
  final Color textDim;         // Secondary/helper text
  final Color accent;          // Highlight/emphasis color
  final Color error;           // Error states
  final Color border;          // Borders and dividers
  final Color userBubble;      // User message background
  final Color botBubble;       // Bot/system message background
  final Color inputFill;       // Input field background
  final Color drawerBg;        // Navigation drawer background
}
```

### Theme Palettes

#### 1. P1 Green (Classic Terminal)
**Description:** Classic green phosphor terminal - the original cyberpunk aesthetic
```dart
background:    #0A0F0A  // Deep dark green-black
surface:       #0F1A0F  // Dark green surface
primary:       #33FF33  // Bright phosphor green
accent:        #66FF66  // Lighter green highlight
textColor:     #33FF33  // Green on black
border:        #1A3A1A  // Dark green borders
```

#### 2. P3 Amber (Warm Terminal)
**Description:** Warm amber terminal inspired by vintage monitors
```dart
background:    #0F0A00  // Deep warm black
surface:       #1A1200  // Dark amber surface
primary:       #FFB300  // Bright amber/gold
accent:        #FFD54F  // Light golden yellow
textColor:     #FFB300  // Amber text
border:        #3A2A00  // Dark amber borders
```

#### 3. P4 White (Cool Modern)
**Description:** Cool bright terminal with blue-white phosphor
```dart
background:    #0A0A0F  // Deep blue-black
surface:       #12121A  // Dark blue-gray surface
primary:       #E0E0FF  // Bright cool white
accent:        #FFFFFF  // Pure white
textColor:     #E0E0FF  // Cool white text
border:        #2A2A3A  // Blue-gray borders
```

#### 4. Neon Cyan (Cyberpunk Edge)
**Description:** Vibrant cyan with magenta accents - pure cyberpunk
```dart
background:    #050A0F  // Deep cyan-black
surface:       #0A1520  // Dark cyan surface
primary:       #00FFFF  // Electric cyan
accent:        #FF00FF  // Hot magenta
textColor:     #00FFFF  // Cyan text
border:        #0A2A3A  // Dark cyan borders
```

#### 5. Synthwave (80s Retro)
**Description:** Purple and pink synthwave vibes - 80s retro-futurism
```dart
background:    #0F0A1A  // Deep purple-black
surface:       #1A1030  // Dark purple surface
primary:       #FF66FF  // Hot pink/magenta
accent:        #00FFFF  // Cyan highlight
textColor:     #E0B0FF  // Light purple text
border:        #2A1A3A  // Dark purple borders
```

### Color Usage Guidelines

**DO:**
- Use primary colors for interactive elements and key UI components
- Use dimmed variants for secondary/disabled states
- Maintain high contrast for accessibility (min 4.5:1 for text)
- Use accent colors sparingly for emphasis
- Keep backgrounds very dark for authentic CRT effect

**DON'T:**
- Mix warm and cool colors within the same theme
- Use gradients (terminal aesthetic is flat)
- Add shadows or depth effects (keep it flat and sharp)
- Use rounded corners (terminals are rectangular)

---

## Typography

### Font Family
**Primary Font:** [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
- **Type:** Monospace
- **License:** OFL (Open Font License)
- **Why:** Developer-focused, excellent readability, supports ligatures

**Implementation:**
```dart
import 'package:google_fonts/google_fonts.dart';

// Get the text theme
final monoTextTheme = GoogleFonts.jetBrainsMonoTextTheme();

// Individual text styles
TextStyle myStyle = GoogleFonts.jetBrainsMono(
  fontSize: 13,
  fontWeight: FontWeight.normal,
  color: colors.textColor,
);
```

### Type Scale

| Element | Size | Weight | Use Case |
|---------|------|--------|----------|
| H1 | 18px | Bold | Dialog titles, major headings |
| H2 | 16px | Bold | Section headers, app bar titles |
| H3 | 14px | Bold | Subsection headers |
| Body | 13px | Normal | Primary content, messages |
| Caption | 12px | Normal | Code blocks, metadata |
| Small | 11px | Normal | Helper text, timestamps |
| Tiny | 10px | Bold | Tags, labels, action buttons |
| Micro | 9px | Normal | Fine print, status indicators |

### Text Styling Conventions

**Headers:**
```dart
// Use primary color for headers
Text(
  'SECTION HEADER',
  style: mono.copyWith(
    color: colors.primary,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2, // Slight spacing for all-caps
  ),
)
```

**Body Text:**
```dart
// Regular text uses textColor
Text(
  'Regular message content',
  style: mono.copyWith(
    color: colors.textColor,
    fontSize: 13,
    height: 1.5, // Line height for readability
  ),
)
```

**Dimmed/Secondary Text:**
```dart
// Use textDim for helper text
Text(
  'Helper or metadata',
  style: mono.copyWith(
    color: colors.textDim,
    fontSize: 11,
  ),
)
```

**Terminal-Style Labels:**
```dart
// Bracketed labels in all caps
Text(
  '[LABEL]',
  style: mono.copyWith(
    color: colors.primaryDim,
    fontSize: 10,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## Component Styling

### Cards & Containers

**Design Principles:**
- Zero border radius (sharp rectangular edges)
- Flat design (no elevation/shadows)
- Minimal borders (1px, subtle color)
- Dark backgrounds with slight variation

```dart
Container(
  decoration: BoxDecoration(
    color: colors.surface,
    border: Border.all(color: colors.border, width: 1),
    borderRadius: BorderRadius.zero, // Always zero!
  ),
  padding: const EdgeInsets.all(12),
  child: content,
)
```

### Message Bubbles

Message bubbles are a core component with specific styling:

```dart
Container(
  decoration: BoxDecoration(
    color: isUser ? colors.userBubble : colors.botBubble,
    border: Border(
      left: BorderSide(
        color: isUser ? colors.accent : colors.primary,
        width: 2, // Thicker left border as accent
      ),
      top: BorderSide(color: colors.border, width: 0.5),
      bottom: BorderSide(color: colors.border, width: 0.5),
    ),
  ),
  // Content with header and body
)
```

**Message Header Pattern:**
```dart
// Header with tag, timestamp, and actions
Row(
  children: [
    Text('[USR]', style: tagStyle), // Or [SYS]
    SizedBox(width: 8),
    Text('12:34:56', style: timestampStyle),
    Spacer(),
    // Action buttons: [CP] [ED] [RT] [RM]
  ],
)
```

### Buttons

**Primary Button (Filled):**
```dart
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: colors.primary,
    foregroundColor: colors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    textStyle: mono.copyWith(fontWeight: FontWeight.bold),
  ),
  onPressed: onPressed,
  child: Text('ACTION'),
)
```

**Secondary Button (Outlined):**
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: colors.primary,
    side: BorderSide(color: colors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  ),
  onPressed: onPressed,
  child: Text('Cancel'),
)
```

**Text Button (Minimal):**
```dart
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: colors.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  ),
  onPressed: onPressed,
  child: Text('[ACTION]'),
)
```

**Custom Terminal Action Button:**
```dart
InkWell(
  onTap: onTap,
  child: Text(
    '[XX]', // 2-letter code
    style: mono.copyWith(
      color: actionColor,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### Input Fields

```dart
TextField(
  style: mono.copyWith(
    color: colors.textColor,
    fontSize: 13,
  ),
  decoration: InputDecoration(
    hintText: 'Enter command...',
    hintStyle: mono.copyWith(color: colors.textDim),
    filled: true,
    fillColor: colors.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.primary, width: 2),
    ),
    contentPadding: EdgeInsets.all(10),
  ),
)
```

**Prompt Indicator Pattern:**
```dart
// Terminal-style input with "> " prompt
Row(
  children: [
    Text(
      '> ',
      style: mono.copyWith(
        color: colors.primary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
    Expanded(child: inputField),
  ],
)
```

### Lists & Tiles

```dart
ListTile(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  leading: Icon(Icons.code, color: colors.primaryDim),
  title: Text(
    'Item Title',
    style: mono.copyWith(color: colors.textColor, fontSize: 13),
  ),
  subtitle: Text(
    'Metadata',
    style: mono.copyWith(color: colors.textDim, fontSize: 11),
  ),
  trailing: Icon(Icons.chevron_right, color: colors.primaryDim),
  onTap: onTap,
)
```

### Dialogs

```dart
AlertDialog(
  backgroundColor: colors.surface,
  shape: RoundedRectangleBorder(
    side: BorderSide(color: colors.primary, width: 1),
    borderRadius: BorderRadius.zero,
  ),
  title: Text(
    '▸ DIALOG TITLE',
    style: mono.copyWith(
      color: colors.primary,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
  ),
  content: Text(
    'Dialog content',
    style: mono.copyWith(color: colors.textDim, fontSize: 12),
  ),
  actions: [
    TextButton(
      child: Text('[CANCEL]'),
      onPressed: () => Navigator.pop(context),
    ),
    TextButton(
      child: Text('[CONFIRM]'),
      onPressed: onConfirm,
    ),
  ],
)
```

### Dividers & Borders

```dart
// Horizontal divider
Container(height: 1, color: colors.border)

// Vertical divider
Container(width: 1, color: colors.border)

// Section border
Container(
  decoration: BoxDecoration(
    border: Border(
      top: BorderSide(color: colors.border, width: 1),
    ),
  ),
)
```

### App Bar

```dart
AppBar(
  backgroundColor: colors.background,
  foregroundColor: colors.primary,
  elevation: 0,
  centerTitle: false,
  title: Text(
    'EXECPROMPT',
    style: mono.copyWith(
      color: colors.primary,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
  iconTheme: IconThemeData(color: colors.primary),
  shape: Border(
    bottom: BorderSide(color: colors.border, width: 1),
  ),
)
```

---

## Layout Principles

### Spacing System
Use consistent 4px-based spacing:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Tight spacing |
| sm | 8px | Default inner padding |
| md | 12px | Standard padding |
| lg | 16px | Section spacing |
| xl | 24px | Large gaps |

```dart
// Standard container padding
Padding(padding: const EdgeInsets.all(8))

// Section margins
Padding(padding: const EdgeInsets.symmetric(vertical: 12))
```

### Terminal Grid Layout
Think in terms of character grid:
- Elements should align on consistent baseline
- Avoid asymmetric padding
- Use uniform gaps between sections

### Responsive Breakpoints
```dart
final isNarrow = MediaQuery.of(context).size.width < 600;
final isMedium = MediaQuery.of(context).size.width < 900;
final isWide = MediaQuery.of(context).size.width >= 900;

// Example responsive layout
if (isWide) {
  // Two-column layout
} else {
  // Single column with drawer
}
```

### Safe Areas
Always respect safe areas on mobile:
```dart
SafeArea(
  child: content,
)
```

---

## Animations & Interactions

### Haptic Feedback
Add tactile feedback for actions:
```dart
import 'package:flutter/services.dart';

// Light tap
HapticFeedback.lightImpact();

// Medium interaction
HapticFeedback.mediumImpact();

// Heavy action
HapticFeedback.heavyImpact();
```

### Blinking Cursor
The signature animated element:
```dart
class BlinkingCursor extends StatefulWidget {
  final Color? color;
  final double fontSize;
  
  // Animates block cursor: █
  // Duration: 530ms
  // Opacity: 1.0 to 0.2
  // Curve: easeInOut
}

// Usage
BlinkingCursor(
  color: colors.primary,
  fontSize: 13,
)
```

### Loading States
```dart
// For async operations
CircularProgressIndicator(
  strokeWidth: 2,
  color: colors.primary,
)

// Inline loading with cursor
Row(
  children: [
    Text('Processing'),
    BlinkingCursor(),
  ],
)
```

### Page Transitions
Use instant/cupertino transitions (no material fade):
```dart
pageTransitionsTheme: PageTransitionsTheme(
  builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  },
)
```

### Interaction States

**Hover (Desktop/Web):**
- Subtle brightness increase
- No elaborate effects
- Keep it minimal

**Pressed:**
- Use color opacity changes
- No scale transforms
- Flat design throughout

**Disabled:**
- Reduce opacity to 0.3-0.5
- Use textDim color
- No color transformations

---

## Theme Implementation

### Complete Theme Builder

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildCyberTermTheme(CyberTermColors colors) {
  final monoTextTheme = GoogleFonts.jetBrainsMonoTextTheme();

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: colors.background,
    
    colorScheme: ColorScheme.dark(
      primary: colors.primary,
      onPrimary: colors.background,
      secondary: colors.accent,
      surface: colors.surface,
      onSurface: colors.textColor,
      error: colors.error,
    ),
    
    textTheme: monoTextTheme.apply(
      bodyColor: colors.textColor,
      displayColor: colors.textColor,
    ),
    
    // Component themes...
    // (See full implementation in cyberterm_theme.dart)
  );
}
```

### Accessing Theme in Widgets

```dart
// Get standard theme
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;

// Get CyberTerm specific colors
final colors = theme.cyberTermColors;

// Get mono font
final mono = GoogleFonts.jetBrainsMono();
```

### Theme Switching
```dart
// Store current theme
final themeProvider = StateProvider<CyberTermTheme>(
  (ref) => CyberTermTheme.p1Green,
);

// Apply theme
MaterialApp(
  theme: buildCyberTermTheme(
    getThemeColors(ref.watch(themeProvider)),
  ),
)
```

---

## Code Examples

### Complete Message Bubble Example

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerminalMessageBubble extends StatelessWidget {
  final String role; // 'user' or 'system'
  final String content;
  final DateTime timestamp;
  
  const TerminalMessageBubble({
    required this.role,
    required this.content,
    required this.timestamp,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    final isUser = role == 'user';
    final tag = isUser ? 'USR' : 'SYS';
    final tagColor = isUser ? colors.accent : colors.primary;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isUser ? colors.userBubble : colors.botBubble,
        border: Border(
          left: BorderSide(color: tagColor, width: 2),
          top: BorderSide(color: colors.border, width: 0.5),
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '[$tag]',
                  style: mono.copyWith(
                    color: tagColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  _formatTime(timestamp),
                  style: mono.copyWith(
                    color: colors.textDim,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              content,
              style: mono.copyWith(
                color: colors.textColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}
```

### Terminal Input Field Example

```dart
class TerminalInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  
  const TerminalInput({
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Prompt
          Text(
            '> ',
            style: mono.copyWith(
              color: colors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Input
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: mono.copyWith(
                color: colors.textColor,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Enter command...',
                hintStyle: mono.copyWith(color: colors.textDim),
                filled: true,
                fillColor: colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: colors.primary, width: 1),
                ),
                contentPadding: EdgeInsets.all(10),
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          SizedBox(width: 6),
          // Send button
          InkWell(
            onTap: enabled ? onSend : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: enabled ? colors.primary : colors.border,
                ),
              ),
              child: Text(
                '[↵]',
                style: mono.copyWith(
                  color: enabled ? colors.primary : colors.textDim,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Best Practices

### DO:
✅ Use JetBrains Mono for all text  
✅ Keep borders sharp (BorderRadius.zero)  
✅ Maintain flat design (elevation: 0)  
✅ Use monochrome color schemes  
✅ Add haptic feedback to interactions  
✅ Use terminal-style labels [XX]  
✅ Keep backgrounds very dark  
✅ Use high contrast text  
✅ Add blinking cursor for loading  
✅ Use ▸ and ▾ for expand/collapse  

### DON'T:
❌ Mix multiple font families  
❌ Use rounded corners  
❌ Add shadows or elevation  
❌ Use gradients  
❌ Mix warm and cool colors  
❌ Use low contrast combinations  
❌ Ignore safe areas on mobile  
❌ Forget haptic feedback  
❌ Use colored icons (use monochrome)  
❌ Add unnecessary animations  

---

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## Quick Start Template

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(CyberTermApp());
}

class CyberTermApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberTerm App',
      theme: buildCyberTermTheme(getP1GreenColors()),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('TERMINAL'),
      ),
      body: Column(
        children: [
          // Your content here
        ],
      ),
    );
  }
}
```

---

## Resources

- **Font:** [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
- **Color Tool:** [Coolors.co](https://coolors.co/) for palette generation
- **Icons:** Material Icons (monochrome only)
- **Reference:** See `lib/presentation/theme/cyberterm_theme.dart` in ExecPrompt repo

---

## Credits

**Design System:** ExecPrompt by DayOfGeek.com  
**Aesthetic:** Cyberpunk / Retro-Futurism / Terminal  
**License:** Style guide provided as-is for creating consistent DayOfGeek applications

---

*Last Updated: February 2026*  
*Version: 1.0*
