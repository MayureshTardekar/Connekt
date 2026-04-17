import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/providers/community_provider.dart';
import '../../core/network/logger.dart';
import 'community_admin_screen.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CommunityChatScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'voice_note.m4a');
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      AppLogger.error('Recording Error: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    
    if (path != null) {
      await ref.read(communityRepositoryProvider).sendMessage(
        communityId: widget.communityId,
        type: 'voice',
        filePath: path,
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      await ref.read(communityRepositoryProvider).sendMessage(
        communityId: widget.communityId,
        type: 'image',
        filePath: image.path,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    ref.read(communityRepositoryProvider).sendMessage(
      communityId: widget.communityId,
      type: 'text',
      content: _messageController.text.trim(),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(communityMessagesProvider);
    final membershipStatusAsync = ref.watch(communityMembershipStatusProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Community Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.blueAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommunityAdminScreen(communityId: widget.communityId)),
            ),
          ),
        ],
      ),
      body: membershipStatusAsync.when(
        data: (status) {
          if (status != 'member') {
            return _buildAccessDenied(status);
          }
          return Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, r) => Text('Error: $e', style: const TextStyle(color: Colors.white)),
                ),
              ),
              _buildInputArea(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, r) => const Center(child: Text('Error loading status')),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['sender_id'] == ref.read(communityRepositoryProvider).supabase.auth.currentUser?.id;
    final type = message['message_type'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.zero : null,
            bottomLeft: !isMe ? Radius.zero : null,
          ),
        ),
        child: _buildMessageContent(message, type),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> message, String type) {
    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(message['file_url']),
            ),
            if (message['content'] != null) ...[
              const SizedBox(height: 8),
              Text(message['content'], style: const TextStyle(color: Colors.white)),
            ],
          ],
        );
      case 'voice':
        return VoiceMessagePlayer(url: message['file_url']);
      default:
        return Text(
          message['content'] ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.blueAccent),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.blueAccent, width: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPress: _startRecording,
            onLongPressUp: _stopAndSendRecording,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.redAccent : Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
            ),
          ),
          if (!_isRecording) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendMessage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessDenied(String? status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            const Text(
              'Private Community',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              status == 'pending' 
                  ? 'Your request is pending approval.' 
                  : 'You must join this community to see the messages.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 32),
            if (status != 'pending')
              ElevatedButton(
                onPressed: () => ref.read(communityRepositoryProvider).joinCommunity(widget.communityId, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('Request to Join'),
              ),
          ],
        ),
      ),
    );
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  const VoiceMessagePlayer({super.key, required this.url});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 30),
          onPressed: _togglePlay,
        ),
        Expanded(
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}
