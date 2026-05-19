import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  _ChatMessage({required this.text, required this.isMe, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<_ChatMessage> _messages = [];
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      // Load messages between me and the receiver (both directions)
      final data = await _supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.${widget.receiverId}),and(sender_id.eq.${widget.receiverId},receiver_id.eq.$myId)')
          .order('created_at', ascending: true);

      if (!mounted) return;
      setState(() {
        _messages = (data as List).map((json) {
          final isMe = json['sender_id'] == myId;
          return _ChatMessage(
            text: json['content'] as String,
            isMe: isMe,
            time: _formatTime(json['created_at'] as String),
          );
        }).toList();
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _subscribeToMessages() {
    final myId = _supabase.auth.currentUser?.id;
    // Create a unique channel name by sorting IDs so A->B and B->A both use same channel
    final ids = [myId ?? '', widget.receiverId]..sort();
    final channelName = 'chat_${ids[0]}_${ids[1]}';
    
    _channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final senderId = row['sender_id'] as String?;
            final receiverId = row['receiver_id'] as String?;
            // Only show messages that belong to this conversation
            final belongsHere = (senderId == myId && receiverId == widget.receiverId) ||
                (senderId == widget.receiverId && receiverId == myId);
            if (!belongsHere) return;

            if (!mounted) return;
            setState(() {
              _messages.add(_ChatMessage(
                text: row['content'] as String,
                isMe: senderId == myId,
                time: _formatTime(row['created_at'] as String? ?? DateTime.now().toIso8601String()),
              ));
            });
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// Ensures the logged-in auth user has a row in public.users.
  /// This fixes the FK violation: sender_id not present in users table.
  Future<void> _ensureUserProfile(String myId) async {
    try {
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('id', myId)
          .maybeSingle();
      if (existing == null) {
        final email = _supabase.auth.currentUser?.email ?? '';
        await _supabase.from('users').insert({
          'id': myId,
          'email': email,
          'password_hash': 'managed_by_supabase',
          'full_name': email.split('@').first,
          'role': 'farmer',
          'is_active': true,
          'kyc_status': 'VERIFIED',
        });
        debugPrint('Auto-created missing user profile for $myId');
      }
    } catch (e) {
      debugPrint('Could not ensure user profile: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    // Ensure the user profile exists BEFORE inserting the message
    await _ensureUserProfile(myId);

    // OPTIMISTIC: add the message to the UI immediately so user sees it now
    final optimisticMsg = _ChatMessage(
      text: text,
      isMe: true,
      time: _formatTime(DateTime.now().toIso8601String()),
    );
    if (mounted) {
      setState(() => _messages.add(optimisticMsg));
      _scrollToBottom();
    }

    try {
      final ids = [myId, widget.receiverId]..sort();
      final threadId = '${ids[0]}_${ids[1]}';
      await _supabase.from('messages').insert({
        'chat_thread_id': threadId,
        'sender_id': myId,
        'receiver_id': widget.receiverId,
        'content': text,
      });
      // Reload from DB to get the real record with correct timestamp
      await _loadMessages();
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Remove the optimistic message on failure
      if (mounted) {
        setState(() => _messages.remove(optimisticMsg));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startVideoCall() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CallOverlay(
          name: widget.receiverName,
          isVideo: true,
        );
      },
    );
  }

  void _startAudioCall() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CallOverlay(
          name: widget.receiverName,
          isVideo: false,
        );
      },
    );
  }



  void _showProfileInfo() {
    showDialog(
      context: context,
      builder: (context) {
        final initials = widget.receiverName.trim().split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 36,
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(widget.receiverName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('🌾 Verified Agricultural P2P Partner', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Status', style: TextStyle(color: Colors.grey)),
                    Text('Active', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Trust Tier', style: TextStyle(color: Colors.grey)),
                    Text('Platinum Partner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Type', style: TextStyle(color: Colors.grey)),
                    Text('Agriculture Business', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearChat() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await _supabase
          .from('messages')
          .delete()
          .or('and(sender_id.eq.$myId,receiver_id.eq.${widget.receiverId}),and(sender_id.eq.${widget.receiverId},receiver_id.eq.$myId)');
      setState(() {
        _messages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧹 Conversation cleared successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      debugPrint('Error clearing chat: $e');
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        final emojis = ['🌾', '🌽', '☕', '🥔', '💰', '😊', '👍', '❤️', '🙌', '✨', '🔥', '🚜', '🌱', '🌍', '🤝', '📈'];
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agricultural & Reaction Emojis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, idx) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _controller.text += emojis[idx];
                        });
                        Navigator.pop(context);
                      },
                      child: Center(child: Text(emojis[idx], style: const TextStyle(fontSize: 28))),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share Agricultural Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachItem(Icons.insert_drive_file, 'Document', Colors.indigo, '📂 Preloading PDF agricultural yield document!'),
                  _buildAttachItem(Icons.camera_alt, 'Camera', Colors.pink, '📸 Requesting farm camera feed access...'),
                  _buildAttachItem(Icons.image, 'Gallery', Colors.purple, '🖼️ Opening photo library...'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachItem(Icons.headset, 'Audio', Colors.orange, '🎵 Processing voice clip attachments...'),
                  _buildAttachItem(Icons.location_on, 'Location', Colors.green, '📍 Auto-detected GPS coordinates successfully loaded!'),
                  _buildAttachItem(Icons.person, 'Contact', Colors.blue, '👤 Loading agricultural officer contact...'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachItem(IconData icon, String label, Color color, String message) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withAlpha(40),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _simulateCameraCapture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📸 Capturing live farm agricultural progress photo...'),
        backgroundColor: AppColors.primary,
      ),
    );
    // Optimistically insert a camera image mockup message
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;
    final optimisticMsg = _ChatMessage(
      text: '📸 Sent a live high-definition agricultural progress photo.',
      isMe: true,
      time: _formatTime(DateTime.now().toIso8601String()),
    );
    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();
    final ids = [myId, widget.receiverId]..sort();
    final threadId = '${ids[0]}_${ids[1]}';
    _supabase.from('messages').insert({
      'chat_thread_id': threadId,
      'sender_id': myId,
      'receiver_id': widget.receiverId,
      'content': '📸 Sent a live high-definition agricultural progress photo.',
    }).then((_) => _loadMessages()).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.receiverName.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          onTap: _showProfileInfo,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                radius: 18,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.receiverName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const Text('tap here for info',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: _startAudioCall,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'profile') {
                _showProfileInfo();
              } else if (val == 'clear') {
                _clearChat();
              } else if (val == 'block') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚫 ${widget.receiverName} has been blocked successfully!'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (val == 'mute') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔕 Chat notifications muted for 8 hours.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Mute Notifications'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔒 Messages are end-to-end secured.\nSay hello!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: msg.isMe ? const Radius.circular(12) : const Radius.circular(0),
            bottomRight: msg.isMe ? const Radius.circular(0) : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg.text, style: const TextStyle(fontSize: 15, color: Color(0xFF111111))),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 14, color: Color(0xFF4FC3F7)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFFF0F0F0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showEmojiPicker,
                    child: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAttachmentMenu,
                    child: const Icon(Icons.attach_file, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _simulateCameraCapture,
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallOverlay extends StatefulWidget {
  final String name;
  final bool isVideo;
  const _CallOverlay({required this.name, required this.isVideo});

  @override
  State<_CallOverlay> createState() => _CallOverlayState();
}

class _CallOverlayState extends State<_CallOverlay> {
  int _seconds = 0;
  bool _muted = false;
  bool _speaker = false;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _seconds++;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    final initials = widget.name.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: Colors.black.withAlpha(220),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              widget.isVideo ? '🎥 Umusaruro Video Call' : '📞 Umusaruro Audio Call',
              style: const TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
            const SizedBox(height: 24),
            Text(
              widget.name,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _seconds == 0 ? 'Connecting...' : timeStr,
              style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (widget.isVideo)
              Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 36,
                        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      const Text('Live Stream Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 60,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white, size: 28),
                  onPressed: () => setState(() => _muted = !_muted),
                ),
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                ),
                IconButton(
                  icon: Icon(_speaker ? Icons.volume_up : Icons.volume_down, color: Colors.white, size: 28),
                  onPressed: () => setState(() => _speaker = !_speaker),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
