import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CommentsScreen extends StatefulWidget {
  final String postContent;
  final String mood;
  final Color moodColor;
  final int likes;

  const CommentsScreen({super.key, required this.postContent, required this.mood, required this.moodColor, required this.likes});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [
    {'id': '1', 'text': 'You\'re not alone in this. I feel the same way every exam season.', 'time': '10 min ago', 'likes': 24, 'isReply': false},
    {'id': '2', 'text': 'Honestly, same. But it gets better after midterms, trust me!', 'time': '25 min ago', 'likes': 12, 'isReply': false},
    {'id': '3', 'text': '@Anonymous_1 Exactly! Midterms are the worst part.', 'time': '22 min ago', 'likes': 5, 'isReply': true},
    {'id': '4', 'text': 'Try the study groups on this app — helped me a lot.', 'time': '1 hour ago', 'likes': 8, 'isReply': false},
  ];

  bool _isSaved = false;

  @override
  void dispose() { _commentController.dispose(); super.dispose(); }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() { 
      _comments.insert(0, {'id': DateTime.now().toString(), 'text': _commentController.text.trim(), 'time': 'Just now', 'likes': 0, 'isReply': _commentController.text.contains('@')}); 
      _commentController.clear(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0A1E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Comments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _isSaved ? AppTheme.anonPurple : Colors.white70),
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isSaved ? 'Post Saved' : 'Post Removed from Saved')));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  // Original post
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: widget.moodColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(widget.mood, style: TextStyle(color: widget.moodColor, fontSize: 11, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(widget.postContent, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.6)),
                        const SizedBox(height: 14),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.keyboard_double_arrow_up_rounded, size: 22, color: Colors.white.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text('${widget.likes}', style: TextStyle(color: widget.moodColor, fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_double_arrow_down_rounded, size: 22, color: Colors.white.withValues(alpha: 0.6)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  Icon(Icons.more_horiz, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Report', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${_comments.length} Comments', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(_comments.length, (index) {
                    final comment = _comments[index];
                    final isReply = comment['isReply'] as bool;
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 10, left: isReply ? 32 : 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(gradient: AppTheme.ghostGradient, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.visibility_off_rounded, size: 12, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text('Anon_${comment['id']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF8B5CF6))),
                              const Spacer(),
                              Text(comment['time'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(comment['text'] as String, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.thumb_up_outlined, size: 14, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text('${comment['likes']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 12),
                              Icon(Icons.thumb_down_outlined, size: 14, color: Colors.white54),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () {
                                  _commentController.text = '@Anon_${comment['id']} ';
                                  // In real app, focus the text field
                                },
                                child: Text('Reply', style: TextStyle(color: AppTheme.neutral[400], fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(border: InputBorder.none, hintText: 'Add anonymous comment...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.ghostGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppTheme.anonPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
