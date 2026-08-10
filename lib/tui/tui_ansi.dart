import 'dart:io';

/// ANSI styling, color palettes, and box-drawing primitives for Vaivart TUI.
class TuiAnsi {
  // Styles
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';

  // 256-Color Palette
  static const String cyan = '\x1B[38;5;51m';
  static const String neonPurple = '\x1B[38;5;141m';
  static const String emerald = '\x1B[38;5;49m';
  static const String gold = '\x1B[38;5;220m';
  static const String white = '\x1B[38;5;255m';
  static const String gray = '\x1B[38;5;244m';
  static const String darkGray = '\x1B[38;5;238m';
  static const String coralRed = '\x1B[38;5;203m';
  static const String skyBlue = '\x1B[38;5;117m';

  // Background Colors
  static const String bgDarkPanel = '\x1B[48;5;236m';
  static const String bgMidnight = '\x1B[48;5;234m';
  static const String bgCyanHeader = '\x1B[48;5;24m';

  /// Clear standard terminal output buffer and move cursor to top-left (0,0)
  static void clearScreen() {
    if (stdout.supportsAnsiEscapes) {
      stdout.write('\x1B[2J\x1B[H');
    }
  }

  /// Print stylized ASCII banner for Vaivart
  static String getBanner() {
    final sb = StringBuffer();
    sb.writeln('$cyan$bold  ██╗   ██╗ █████╗ ██╗██╗   ██╗█████╗ ██████╗ ████████╗$reset');
    sb.writeln('$cyan$bold  ██║   ██║██╔══██╗██║██║   ██║██╔══██╗██╔══██╗╚══██╔══╝$reset');
    sb.writeln('$neonPurple$bold  ██║   ██║███████║██║██║   ██║███████║██████╔╝   ██║   $reset');
    sb.writeln('$neonPurple$bold  ╚██╗ ██╔╝██╔══██║██║╚██╗ ██╔╝██╔══██║██╔══██╗   ██║   $reset');
    sb.writeln('$skyBlue$bold   ╚████╔╝ ██║  ██║██║ ╚████╔╝ ██║  ██║██║  ██║   ██║   $reset');
    sb.writeln('$skyBlue$bold    ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   $reset');
    sb.writeln('$dim$gray  ────────────── Offline Universal File Converter TUI ──────────────$reset\n');
    return sb.toString();
  }

  /// Format status badge
  static String statusBadge(String status, {bool success = true, bool warning = false}) {
    if (warning) {
      return '$gold$bold[ $status ]$reset';
    }
    if (success) {
      return '$emerald$bold[ $status ]$reset';
    }
    return '$coralRed$bold[ $status ]$reset';
  }

  /// Render stylized Progress Bar
  static String progressBar(double ratio, {int width = 30}) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final filled = (clampedRatio * width).round();
    final empty = width - filled;
    final pct = (clampedRatio * 100).toInt();

    final barStr = '${'█' * filled}${'░' * empty}';
    return '$cyan[$emerald$barStr$cyan] $gold$pct%$reset';
  }

  /// Wrap content lines inside a unicode boxed card frame
  static String drawBox({
    required String title,
    required List<String> content,
    int width = 72,
    String borderColor = cyan,
  }) {
    final sb = StringBuffer();
    final titleFormatted = ' $bold$white$title$reset ';
    final visibleTitleLen = title.length + 2;
    final topDashCount = (width - visibleTitleLen - 2).clamp(2, 200);

    sb.writeln('$borderColor╔$reset$titleFormatted$borderColor${'═' * topDashCount}╗$reset');
    for (final line in content) {
      sb.writeln('$borderColor║$reset $line');
    }
    sb.writeln('$borderColor╚${'═' * (width - 2)}╝$reset');
    return sb.toString();
  }
}
