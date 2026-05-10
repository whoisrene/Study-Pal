import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/study_pal_store.dart';
import '../data/study_topics.dart';
import '../services/auth_service.dart';
import '../splash_gate.dart';

import 'sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({
    super.key,
    required this.store,
    required this.profile,
  });

  final StudyPalStore store;
  final UserProfile profile;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _currentPage = 'home';
  late UserProfile _profile;
  List<String> _selectedTopics = const [];
  int _streakCount = 0;
  DateTime? _lastCheckIn;
  late Future<List<HomeworkItem>> _homeworkFuture;
  final _homeworkTitle = TextEditingController();
  final _homeworkNotes = TextEditingController();
  DateTime? _pickedDueDate;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _selectedTopics = List<String>.from(kDefaultStudyTopics);
    _streakCount = widget.profile.streakCount;
    _lastCheckIn = widget.profile.lastCheckIn;

    _homeworkFuture = widget.store.listHomework(_profile.dbId);
    _bootstrapFromDatabase();
  }

  Future<void> _bootstrapFromDatabase() async {
    final topics = await widget.store.topicLabels(_profile.dbId);
    final streak = await widget.store.readStreak(_profile.dbId);

    setState(() {
      _selectedTopics = topics.toList(growable: true);
      _streakCount = streak.$1;
      _lastCheckIn = streak.$2;
    });
  }

  Future<void> _refreshProfile() async {
    final hydrated = await widget.store.refreshProfile(_profile);
    if (!mounted) return;
    setState(() => _profile = hydrated);
  }

  @override
  void dispose() {
    _homeworkTitle.dispose();
    _homeworkNotes.dispose();
    super.dispose();
  }

  Future<void> _reloadHomeworkList() async {
    setState(() {
      _homeworkFuture = widget.store.listHomework(_profile.dbId);
    });
  }

  Future<void> _persistTopicSelection() async {
    await widget.store.replaceTopicLabels(_profile.dbId, List<String>.from(_selectedTopics));
  }

  Future<void> _persistStreakValues() async {
    await widget.store.writeStreak(_profile.dbId, _streakCount, _lastCheckIn);
    await _refreshProfile();
  }

  Future<void> _signOut() async {
    await AuthService.signOutCurrentUser();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SplashGate(store: widget.store),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5E6D3),
        child: Row(
          children: [
            Sidebar(
              displayName: _profile.displayName,
              email: _profile.email,
              streakCount: _streakCount,
              onLogout: () {
                _signOut();
              },
              onNavigate: (page) {
                setState(() => _currentPage = page);
              },
              onCheckIn: _handleCheckIn,
              selectedTopics: _selectedTopics,
              onTopicsChanged: (topics) {
                setState(() => _selectedTopics = topics);
                _persistTopicSelection();
              },
            ),
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
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
    final firstName = _profile.displayName.split(' ').firstWhere(
          (token) => token.isNotEmpty,
          orElse: () => _profile.displayName,
        );

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                  'Welcome back, $firstName!',
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
      'Learning Resources': 'Explore curated resources to enhance your learning journey.',
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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _pickedDueDate ?? now.add(const Duration(days: 3)),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFD4A574))),
        child: child!,
      ),
    );

    setState(() {
      _pickedDueDate = selected;
    });
  }

  Widget _buildAddHomeworkPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, size: 52, color: Color(0xFFD4A574)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4423),
                      ),
                    ),
                    Text(
                      'Everything here lives in SQLite (or SharedPreferences fallback for web)',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8B6F47)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          TextField(
            controller: _homeworkTitle,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _homeworkNotes,
            maxLines: 3,
            decoration: InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickDueDate,
                icon: Icon(Icons.calendar_today_outlined, color: Color(0xFFD4A574)),
                label: Text(
                  _pickedDueDate == null
                      ? 'Add due date'
                      : 'Due ${_pickedDueDate!.year}-${_pickedDueDate!.month}-${_pickedDueDate!.day}',
                  style: TextStyle(color: Color(0xFF6B4423)),
                ),
              ),
              SizedBox(width: 12),
              TextButton(
                onPressed: () => setState(() => _pickedDueDate = null),
                child: Text('Clear due date', style: TextStyle(color: Color(0xFF8B6F47))),
              ),
            ],
          ),
          SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFFD4A574),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            onPressed: () async {
              final title = _homeworkTitle.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFFD4A574),
                    content: Text('Give the assignment a short title first.'),
                  ),
                );
                return;
              }

              await widget.store.addHomework(
                _profile.dbId,
                title: title,
                notes: _homeworkNotes.text,
                dueAt: _pickedDueDate,
              );

              _homeworkTitle.clear();
              _homeworkNotes.clear();
              setState(() => _pickedDueDate = null);
              await _reloadHomeworkList();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFFD4A574),
                  content: Text('Saved homework to local database.'),
                ),
              );
            },
            child: Text('Save to database'),
          ),
          SizedBox(height: 36),
          Text(
            'Upcoming homework',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4423),
            ),
          ),
          SizedBox(height: 12),
          FutureBuilder<List<HomeworkItem>>(
            future: _homeworkFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Padding(padding: EdgeInsets.only(top: 24), child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return Text(
                  'Nothing scheduled yet.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF8B6F47), fontStyle: FontStyle.italic),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Material(
                    color: Colors.white,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(14),
                    child: CheckboxListTile(
                      value: item.completed,
                      onChanged: (_) async {
                        await widget.store.setHomeworkCompleted(item.id, !item.completed);
                        await _reloadHomeworkList();
                      },
                      title: Text(
                        item.title,
                        style: TextStyle(decoration: item.completed ? TextDecoration.lineThrough : null),
                      ),
                      subtitle: Text(
                        [
                          if (item.dueAt != null) 'Due ${item.dueAt!.month}/${item.dueAt!.day}',
                          if (item.notes != null && item.notes!.trim().isNotEmpty) item.notes!.trim(),
                        ].join(' • '),
                        style: TextStyle(color: Color(0xFF8B6F47)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _handleCheckIn() {
    final now = DateTime.now();

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
        _streakCount += 1;
      } else {
        _streakCount = 1;
      }
    } else {
      _streakCount = 1;
    }

    _lastCheckIn = now;
    _persistStreakValues();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Check-in complete! Streak: $_streakCount days'),
        backgroundColor: Color(0xFFD4A574),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }
}
