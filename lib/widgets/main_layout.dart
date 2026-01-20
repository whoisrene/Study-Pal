import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentPage = 'home';
  List<String> _selectedTopics = [
    'Motivation Blogs',
    'Study Tips',
    'Time Management',
  ];
  int _streakCount = 7;
  DateTime? _lastCheckIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFF5E6D3),
        child: Row(
          children: [
            // Sidebar
            Sidebar(
              onNavigate: (page) {
                setState(() => _currentPage = page);
              },
              onCheckIn: _handleCheckIn,
              selectedTopics: _selectedTopics,
              onTopicsChanged: (topics) {
                setState(() => _selectedTopics = topics);
                _saveSelectedTopics();
              },
              streakCount: _streakCount,
            ),
            
            // Main Content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final topics = prefs.getStringList('selected_topics');
    if (topics != null && topics.isNotEmpty) {
      setState(() => _selectedTopics = topics);
    }

    _streakCount = prefs.getInt('streak_count') ?? 0;
    final last = prefs.getString('last_checkin');
    if (last != null) {
      _lastCheckIn = DateTime.tryParse(last);
    }
    setState(() {});
  }

  Future<void> _saveSelectedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_topics', _selectedTopics);
  }

  Future<void> _saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak_count', _streakCount);
    if (_lastCheckIn != null) await prefs.setString('last_checkin', _lastCheckIn!.toIso8601String());
  }

  Widget _buildMainContent() {
    switch (_currentPage) {
      case 'home':
        return _buildHomePage();
      case 'chatrooms':
        return _buildChatRoomsPage();
      case 'add_homework':
        return _buildAddHomeworkPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, Alex!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4423),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening with your studies today',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8B6F47),
              ),
            ),
            SizedBox(height: 32),

            // Content based on selected topics
            ..._selectedTopics.map((topic) => _buildTopicSection(topic)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSection(String topic) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD4A574).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTopicIcon(topic),
                SizedBox(width: 12),
                Text(
                  topic,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4423),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              _getTopicContent(topic),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8B6F47),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTopicIcon(String topic) {
    final icons = {
      'Motivation Blogs': Icons.lightbulb_outline,
      'Study Tips': Icons.school_outlined,
      'Time Management': Icons.schedule_outlined,
      'Subject Help': Icons.help_outline,
      'Exam Prep': Icons.assignment_outlined,
      'Wellness': Icons.favorite_outline,
      'Success Stories': Icons.star_outline,
      'Learning Resources': Icons.library_books_outlined,
    };

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFD4A574).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icons[topic] ?? Icons.article_outlined,
        color: Color(0xFFD4A574),
        size: 20,
      ),
    );
  }

  String _getTopicContent(String topic) {
    final content = {
      'Motivation Blogs':
          '"Success is not final, failure is not fatal." Keep pushing through challenges!',
      'Study Tips':
          'Try the Pomodoro Technique: Study for 25 minutes, then take a 5-minute break.',
      'Time Management':
          'Start your day by prioritizing tasks. What are your top 3 goals today?',
      'Subject Help':
          'Need help with a specific subject? Check out our community forums!',
      'Exam Prep':
          'Create a study schedule 2 weeks before your exams for best results.',
      'Wellness':
          'Remember to take care of yourself! Get enough sleep and stay hydrated.',
      'Success Stories':
          'Read inspiring stories from students who improved their grades significantly.',
      'Learning Resources':
        'Explore curated resources to enhance your learning journey.',
    };

    return content[topic] ?? 'Content coming soon...';
  }

  Widget _buildChatRoomsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Color(0xFFD4A574),
          ),
          SizedBox(height: 16),
          Text(
            'Chatrooms',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4423),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect with other students and share your learning journey',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B6F47),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddHomeworkPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 64,
            color: Color(0xFFD4A574),
          ),
          SizedBox(height: 16),
          Text(
            'Add Homework',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4423),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a new homework task and stay on top of your assignments',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B6F47),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCheckIn() {
    final now = DateTime.now();

    // If already checked in today, show message
    if (_lastCheckIn != null && _isSameDate(_lastCheckIn!, now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already checked in today.'),
          backgroundColor: Color(0xFFD4A574),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_lastCheckIn != null) {
      final difference = now.difference(_lastCheckIn!).inDays;
      if (difference == 1) {
        _streakCount += 1; // continue streak
      } else {
        _streakCount = 1; // reset
      }
    } else {
      _streakCount = 1;
    }

    _lastCheckIn = now;
    _saveStreak();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check-in complete! Streak: $_streakCount days'),
        backgroundColor: Color(0xFFD4A574),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
