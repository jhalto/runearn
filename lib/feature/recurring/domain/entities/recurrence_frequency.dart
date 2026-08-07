enum RecurrenceFrequency { daily, weekly, monthly, yearly }

extension RecurrenceFrequencyX on RecurrenceFrequency {
  String get label => switch (this) {
    RecurrenceFrequency.daily => 'Daily',
    RecurrenceFrequency.weekly => 'Weekly',
    RecurrenceFrequency.monthly => 'Monthly',
    RecurrenceFrequency.yearly => 'Yearly',
  };
}
