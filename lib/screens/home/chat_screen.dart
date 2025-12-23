import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  late final ChatUser _currentUser;
  final ChatUser _botUser = ChatUser(id: 'bot', firstName: 'Trợ lý');

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _currentUser = ChatUser(
      id: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
      firstName: FirebaseAuth.instance.currentUser?.email ?? 'Bạn',
    );
    _messages.add(ChatMessage(
      user: _botUser,
      createdAt: DateTime.now(),
      text: 'Xin chào, tôi có thể hỗ trợ bạn kiểm tra đơn hàng hoặc gợi ý sản phẩm.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatbot')),
      body: DashChat(
        currentUser: _currentUser,
        messages: _messages,
        typingUsers: _isTyping ? [_botUser] : [],
        onSend: _handleSend,
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: 'Nhập tin nhắn...',
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              borderSide: BorderSide(color: Colors.green, width: 1.5),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              borderSide: BorderSide(color: Colors.green, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
              borderSide: BorderSide(color: Colors.green, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.green.withOpacity(0.05),
            counterText: '', // Hide default counter
          ),
          maxLength: 500, // Phase 1: Enforce max length in UI
          cursorStyle: const CursorStyle(color: Colors.green, width: 2),
          sendButtonBuilder: (send) => IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: send,
          ),
        ),
        messageOptions: const MessageOptions(
          showTime: true,
          currentUserContainerColor: Colors.green,
          currentUserTextColor: Colors.white,
          containerColor: Color(0xFFEEEEEE),
          textColor: Colors.black87,
        ),
      ),
    );
  }

  Future<void> _handleSend(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    final reply = await _chatService.sendMessage(message.text, _currentUser.id);

    setState(() {
      _isTyping = false;
      _messages.insert(
        0,
        ChatMessage(
          user: _botUser,
          createdAt: DateTime.now(),
          text: reply,
        ),
      );
    });
  }
}