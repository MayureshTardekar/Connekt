import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PostGhostScreen extends StatefulWidget {
  const PostGhostScreen({super.key});

  @override
  State<PostGhostScreen> createState() => _PostGhostScreenState();
}

class _PostGhostScreenState extends State<PostGhostScreen> {
  String? _selectedMood;
  int _charCount = 0;
  final int _maxChars = 500;
  bool _isEphemeral = false;
  bool _isSensitive = false;
  bool _isPoll = false;

  final List<Map<String, dynamic>> _moods = [
    {
      'label': 'Stressed',
      'icon': Icons.sentiment_very_dissatisfied_rounded,
      'color': const Color(0xFFDC2626),
    },
    {
      'label': 'Happy',
      'icon': Icons.sentiment_very_satisfied_rounded,
      'color': const Color(0xFF059669),
    },
    {
      'label': 'Confused',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFFD97706),
    },
    {
      'label': 'Venting',
      'icon': Icons.whatshot_rounded,
      'color': const Color(0xFF7E22CE),
    },
    {
      'label': 'Motivated',
      'icon': Icons.rocket_launch_rounded,
      'color': const Color(0xFF2563EB),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0533),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Ghost Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anonymous badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_off_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'This post is completely anonymous',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Mood selector
            const Text(
              'How are you feeling?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedMood = mood['label'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (mood['color'] as Color)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mood['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.white60,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mood['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Text area
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'What\'s on your mind?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_charCount}/$_maxChars',
                  style: TextStyle(
                    color: _charCount > _maxChars
                        ? AppColors.error
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                maxLines: 6,
                onChanged: (val) => setState(() => _charCount = val.length),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts, feelings, or just vent...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Advanced options
            const Text(
              'Post Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildToggleOption(
              icon: Icons.timer_outlined,
              title: 'Ephemeral Post',
              subtitle: 'Destroys itself after 24 hours',
              value: _isEphemeral,
              onChanged: (val) => setState(() => _isEphemeral = val),
            ),
            const SizedBox(height: 12),
            _buildToggleOption(
              icon: Icons.warning_amber_rounded,
              title: 'Sensitive Content',
              subtitle: 'Adds a trigger warning blur',
              value: _isSensitive,
              onChanged: (val) => setState(() => _isSensitive = val),
            ),
            const SizedBox(height: 12),
            _buildToggleOption(
              icon: Icons.poll_outlined,
              title: 'Add Anonymous Poll',
              subtitle: 'Cannot be edited once posted',
              value: _isPoll,
              onChanged: (val) => setState(() => _isPoll = val),
            ),

            if (_isPoll) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildPollOptionField('Option 1'),
                    const SizedBox(height: 8),
                    _buildPollOptionField('Option 2'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add another option',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.visibility_off_rounded, size: 20),
                label: const Text(
                  'Post Anonymously',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7E22CE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF7E22CE),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPollOptionField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30),
        ),
      ),
    );
  }
}
