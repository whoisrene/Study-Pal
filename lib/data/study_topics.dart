/// Topic chips shown throughout the sidebar + home dashboard.
/// Kept centralized so onboarding and DB seeding agree.
const List<String> kDefaultStudyTopics = [
  'Motivation Blogs',
  'Study Tips',
  'Time Management',
];

/// Every topic the picker can toggle (includes defaults + extras).
const List<String> kAllStudyTopicChoices = [
  ...kDefaultStudyTopics,
  'Subject Help',
  'Exam Prep',
  'Wellness',
  'Success Stories',
  'Learning Resources',
];
