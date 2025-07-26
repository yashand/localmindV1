import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_state.dart';
import '../../models/user_profile.dart';
import '../../models/chat_message.dart';
import '../../services/llm_service.dart';
import '../../services/voice_service.dart';
import '../../services/automation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/mode_indicator.dart';
import '../widgets/input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      content: "LocalMind initialized. Your privacy-first assistant is ready.",
      isUser: false,
      timestamp: DateTime.now().subtract(Duration(seconds: 30)),
      mode: 'personal',
    ),
  ];
  
  String currentMode = 'personal'; // or 'work'
  bool isConnected = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final llmService = context.read<LLMService>();
    final voiceService = context.read<VoiceService>();
    
    await llmService.initialize();
    await voiceService.initialize();
    
    // Auto-switch mode based on time
    context.read<AppState>().autoSwitchMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PalantirTheme.backgroundDeep,
      body: Column(
        children: [
          // Status Bar
          _buildStatusBar(),
          
          // Messages Area
          Expanded(
            child: _buildMessagesArea(),
          ),
          
          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 50, 20, 15),
      decoration: BoxDecoration(
        color: PalantirTheme.backgroundCard,
        border: Border(
          bottom: BorderSide(
            color: PalantirTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Connection Indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? PalantirTheme.successGreen : PalantirTheme.accentOrange,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            isConnected ? 'CONNECTED' : 'OFFLINE',
            style: TextStyle(
              color: PalantirTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          
          Spacer(),
          
          // Mode Indicator
          Consumer<AppState>(
            builder: (context, appState, child) {
              return ModeIndicator(
                mode: appState.currentMode.name,
                onTap: () => _toggleMode(appState),
              );
            },
          ),
          
          SizedBox(width: 16),
          
          // Settings Button
          IconButton(
            onPressed: () => _openSettings(),
            icon: Icon(
              Icons.settings_outlined,
              color: PalantirTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return MessageBubble(message: messages[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: PalantirTheme.backgroundSurface,
              border: Border.all(color: PalantirTheme.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 32,
              color: PalantirTheme.accentTeal,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'LocalMind Ready',
            style: TextStyle(
              color: PalantirTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your privacy-first AI assistant.\nStart a conversation or use voice input.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PalantirTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24),
          if (!isConnected)
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: PalantirTheme.accentOrange.withOpacity(0.1),
                border: Border.all(color: PalantirTheme.accentOrange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: PalantirTheme.accentOrange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ollama connection offline.\nUsing fallback responses.',
                      style: TextStyle(
                        color: PalantirTheme.accentOrange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PalantirTheme.backgroundCard,
        border: Border(
          top: BorderSide(
            color: PalantirTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: InputBar(
        controller: _messageController,
        onSend: _sendMessage,
        onVoicePress: _startVoiceInput,
        isLoading: isLoading,
      ),
    );
  }

  void _toggleMode(AppState appState) {
    final newMode = appState.currentMode == AppMode.work ? AppMode.personal : AppMode.work;
    appState.switchMode(newMode);
    setState(() {
      currentMode = newMode.name;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || isLoading) return;

    _messageController.clear();
    setState(() => isLoading = true);

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      mode: context.read<AppState>().currentMode.name,
    );

    setState(() {
      messages.add(userMessage);
    });

    _scrollToBottom();

    try {
      // Check if this is an automation command
      final automationService = context.read<AutomationService>();
      final commands = automationService.parseCommand(text);
      
      String response;
      if (commands.length > 1 || _isAutomationCommand(text)) {
        // Execute automation commands
        final results = await automationService.executeMultipleCommands(commands);
        final successCount = results.where((r) => r).length;
        response = 'Executed $successCount of ${commands.length} commands successfully.';
      } else {
        // Get AI response
        final llmService = context.read<LLMService>();
        final userProfile = context.read<UserProfile>();
        final appState = context.read<AppState>();
        
        response = await llmService.generateResponse(
          text,
          userProfile,
          appState.currentMode.name,
          conversationHistory: messages.take(10).toList(),
        );
      }

      // Add AI response
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        mode: context.read<AppState>().currentMode.name,
      );

      setState(() {
        messages.add(aiMessage);
      });

      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        mode: context.read<AppState>().currentMode.name,
      );

      setState(() {
        messages.add(errorMessage);
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _isAutomationCommand(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('open') ||
           lowerText.contains('turn on') ||
           lowerText.contains('turn off') ||
           lowerText.contains('enable') ||
           lowerText.contains('disable');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startVoiceInput() {
    // Implementation for voice input
  }

  void _openSettings() {
    // Implementation for settings navigation
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}