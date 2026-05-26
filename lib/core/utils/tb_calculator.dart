class TBCalculator {
  // TB treatment phases and durations
  static const Map<String, int> phaseDurations = {
    'intensive': 56, // 2 months
    'continuation': 112, // 4 months
  };

  static const int totalDays = 168; // 6 months total

  /// Get current treatment phase
  /// Returns 'intensive' or 'continuation'
  static String getCurrentPhase(int dayNumber) {
    if (dayNumber <= phaseDurations['intensive']!) {
      return 'intensive';
    }
    return 'continuation';
  }

  /// Get the day number within the current phase
  /// Returns 1-56 for intensive, 1-112 for continuation
  static int getDayInPhase(int dayNumber) {
    final currentPhase = getCurrentPhase(dayNumber);
    if (currentPhase == 'intensive') {
      return dayNumber;
    }
    return dayNumber - phaseDurations['intensive']!;
  }

  /// Calculate which day of treatment it is (1-168)
  /// Given a start date and current date
  static int getDayNumber(DateTime startDate, DateTime currentDate) {
    final difference = currentDate.difference(startDate).inDays;
    final day = difference + 1; // Day 1 is the start date
    return day.clamp(1, totalDays);
  }

  /// Get days remaining in current phase
  static int getDaysRemaining(int dayNumber) {
    final currentPhase = getCurrentPhase(dayNumber);
    final phaseDuration = phaseDurations[currentPhase]!;
    final dayInPhase = getDayInPhase(dayNumber);
    return (phaseDuration - dayInPhase).clamp(0, phaseDuration);
  }

  /// Calculate treatment completion date
  /// Given a start date, returns the expected completion date
  static DateTime getCompletionDate(DateTime startDate) {
    return startDate.add(const Duration(days: totalDays));
  }

  /// Get medications for a specific phase
  /// Returns list of medication codes (R, H, Z, E) used in that phase
  static List<String> getMedicationsForPhase(String phase) {
    switch (phase) {
      case 'intensive':
        return ['R', 'H', 'Z', 'E']; // RHZE intensive phase
      case 'continuation':
        return ['R', 'H']; // RH continuation phase
      default:
        return [];
    }
  }

  /// Calculate completion percentage (0.0 to 1.0)
  static double getProgressPercentage(int dayNumber) {
    return (dayNumber / totalDays).clamp(0.0, 1.0);
  }

  /// Check if should transition to next phase
  static bool shouldTransitionPhase(int dayNumber) {
    return dayNumber == phaseDurations['intensive']! + 1;
  }

  /// Check if treatment is overdue
  /// Given a start date and current date
  static bool isOverdue(DateTime startDate, DateTime currentDate) {
    final completionDate = getCompletionDate(startDate);
    return currentDate.isAfter(completionDate);
  }

  /// Format days for display (e.g., "Day 45")
  static String formatDayDisplay(int dayNumber) {
    return 'Day $dayNumber';
  }

  /// Format phase for display (e.g., "Intensive Phase (2 months)")
  static String formatPhaseDisplay(String phase) {
    switch (phase) {
      case 'intensive':
        return 'Intensive Phase (2 months)';
      case 'continuation':
        return 'Continuation Phase (4 months)';
      default:
        return 'Unknown Phase';
    }
  }

  /// Get formatted remaining time string
  /// Returns "X days" or "Complete"
  static String getFormattedRemainingTime(int dayNumber) {
    if (dayNumber >= totalDays) {
      return 'Complete';
    }
    final remaining = getDaysRemaining(dayNumber);
    return '$remaining days';
  }

  /// Check if treatment is completed
  static bool isCompleted(int dayNumber) {
    return dayNumber >= totalDays;
  }
}
