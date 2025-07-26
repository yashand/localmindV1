import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../services/llm_service.dart';
import '../services/voice_service.dart';
import '../services/automation_service.dart';
import '../utils/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mode_toggle.dart';
import '../widgets/voice_input_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

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
      appBar: AppBar(
        title: const Text('LocalMind'),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text(
                    appState.isConnectedToOllama ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: appState.isConnectedToOllama 
                      ? AppTheme.successColor.withOpacity(0.2)
                      : AppTheme.errorColor.withOpacity(0.2),
                  side: BorderSide(
                    color: appState.isConnectedToOllama 
                        ? AppTheme.successColor 
                        : AppTheme.errorColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ModeToggleWidget(),
          Expanded(
            child: _buildChatList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to LocalMind',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your privacy-focused AI assistant.\nStart a conversation or use voice input.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AppState>(
            builder: (context, appState, child) {
              if (!appState.isConnectedToOllama) {
                return Card(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber, color: AppTheme.warningColor),
                        SizedBox(width: 8),
                        Text('Ollama connection offline.\nUsing fallback responses.'),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            VoiceInputButton(
              onVoiceResult: (text) {
                _messageController.text = text;
                _sendMessage();
              },
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isLoading ? null : _sendMessage,
              child: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() => _isLoading = true);

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      mode: context.read<AppState>().currentMode.name,
    );

    setState(() {
      _messages.add(userMessage);
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
          conversationHistory: _messages.take(10).toList(),
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
        _messages.add(aiMessage);
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
        _messages.add(errorMessage);
      });
    } finally {
      setState(() => _isLoading = false);
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}