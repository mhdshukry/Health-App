const genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

const activityTypeOptions = [
  'walking',
  'running',
  'cycling',
  'workout',
  'yoga',
  'stretching',
];

const goalTypeOptions = [
  'steps',
  'kg',
  'workouts',
  'km',
  'minutes',
  'calories',
];

const reminderRepeatOptions = ['once', 'daily', 'weekly'];

const vitalCategoryOptions = [
  'blood_pressure',
  'heart_rate',
  'blood_glucose',
  'oxygen',
  'temperature',
  'hydration',
  'sleep',
  'mood',
  'pain',
];

const moodOptions = ['Great', 'Good', 'Okay', 'Stressed', 'Low', 'Tired'];

String optionLabel(String value) => value.isEmpty
    ? value
    : value
        .split('_')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
