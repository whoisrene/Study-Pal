import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final Function(String) onNavigate;
  final VoidCallback onCheckIn;
  final List<String> selectedTopics;
  final Function(List<String>) onTopicsChanged;
  final int streakCount;

  const Sidebar({
    super.key,
    required this.onNavigate,
    required this.onCheckIn,
    required this.selectedTopics,
    required this.onTopicsChanged,
    this.streakCount = 0,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  bool _showTopicSelector = false;
  late final AnimationController _holdController;
  double _holdProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    )..addListener(() {
        setState(() {
          _holdProgress = _holdController.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // completed hold
          widget.onCheckIn();
          _resetHold();
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Color(0xFFFBF8F3),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4A574).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 24),
            
            // Profile Section
            _buildProfileSection(),
            SizedBox(height: 24),

            // Check-In Button
            _buildCheckInButton(),
            SizedBox(height: 32),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Color(0xFFD4A574).withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
            SizedBox(height: 16),

            // Navigation Options
            _buildNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => widget.onNavigate('home'),
            ),
            _buildNavItem(
              icon: Icons.group_outlined,
              label: 'Chatrooms',
              onTap: () => widget.onNavigate('chatrooms'),
            ),
            _buildNavItem(
              icon: Icons.add_circle_outline,
              label: 'Add Homework',
              onTap: () => widget.onNavigate('add_homework'),
            ),
            SizedBox(height: 24),

            // Divider
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Color(0xFFD4A574).withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
            SizedBox(height: 16),

            // Topics Section
            _buildTopicsHeader(),
            SizedBox(height: 12),
            
            if (_showTopicSelector)
              _buildTopicSelector()
            else
              _buildTopicsList(),
            
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
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
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Profile Avatar with circular progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      value: _holdProgress,
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFD4A574)),
                      backgroundColor: Color(0xFFFAF6F2),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFD4A574),
                          Color(0xFFC19A6B),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFD4A574).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // User Name
              Text(
                'Alex Johnson',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4423),
                ),
              ),
              SizedBox(height: 4),

              // Email
              Text(
                'alex@example.com',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B6F47),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

                  // Streak Info
                  _buildStreakInfo(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: Colors.orange,
          ),
          SizedBox(width: 6),
          Text(
            'Streak: ${widget.streakCount} days',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4423),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTapDown: (_) {
          // start hold animation
          _holdController.forward(from: 0.0);
        },
        onTapUp: (_) {
          // cancel if not completed
          if (!_holdController.isCompleted) _resetHold();
        },
        onTapCancel: () {
          if (!_holdController.isCompleted) _resetHold();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(Color(0xFFD4A574), Color(0xFFB07A3E), _holdProgress)!,
                Color.lerp(Color(0xFFC19A6B), Color(0xFF8C6C44), _holdProgress)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4A574).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Hold to Check-In',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetHold() {
    _holdController.stop();
    _holdController.reset();
    setState(() {
      _holdProgress = 0.0;
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4A574).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Color(0xFFD4A574),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B4423),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicsHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your Topics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4423),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _showTopicSelector = !_showTopicSelector);
            },
            child: Icon(
              _showTopicSelector ? Icons.close : Icons.edit_outlined,
              size: 18,
              color: Color(0xFFD4A574),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.selectedTopics.isEmpty
            ? [
                Text(
                  'No topics selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B6F47),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ]
            : widget.selectedTopics
                .map((topic) => _buildTopicChip(topic, true))
                .toList(),
      ),
    );
  }

  Widget _buildTopicSelector() {
    final allTopics = [
      'Motivation Blogs',
      'Study Tips',
      'Time Management',
      'Subject Help',
      'Exam Prep',
      'Wellness',
      'Success Stories',
      'Learning Resources',
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFD4A574).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTopics
                  .map((topic) => _buildTopicChip(topic, false))
                  .toList(),
            ),
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _showTopicSelector = false);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFFD4A574).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4A574),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicChip(String topic, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final updated = List<String>.from(widget.selectedTopics);
        if (isSelected) {
          updated.remove(topic);
        } else {
          updated.add(topic);
        }
        widget.onTopicsChanged(updated);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFD4A574) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(
                  color: Color(0xFFD4A574).withValues(alpha: 0.3),
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFD4A574).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          topic,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Color(0xFF6B4423),
          ),
        ),
      ),
    );
  }
}
