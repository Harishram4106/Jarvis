import '../models/conversation.dart';
import 'repository_interfaces.dart';

/// Seeded on first run so the app is not empty on install.
List<Conversation> buildSampleConversations() {
  final now = DateTime.now();
  return [
    Conversation(
      id: 'conv-1',
      title: 'Quantum computing explained',
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
      messages: [
        ChatMessage(
          id: 'msg-1-1',
          content: 'Explain quantum computing in simple terms',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(hours: 2, minutes: 5)),
        ),
        ChatMessage(
          id: 'msg-1-2',
          content:
              'Quantum computing uses the principles of quantum mechanics to process information in fundamentally different ways than classical computers.\n\nInstead of bits (0 or 1), quantum computers use **qubits**, which can be 0, 1, or both at the same time. This allows them to solve certain problems — like complex simulations, optimization, and cryptography — much faster than classical computers.\n\nThink of it like this: a classical computer tries one path through a maze at a time, while a quantum computer can explore all paths simultaneously.',
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        ChatMessage(
          id: 'msg-1-3',
          content: 'What are real-world applications of quantum computing?',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 55)),
        ),
        ChatMessage(
          id: 'msg-1-4',
          content:
              'Great question! Here are some real-world applications:\n\n**Drug Discovery**\nSimulating molecular interactions to find new medicines faster.\n\n**Cryptography**\nBreaking and creating encryption methods that are practically unbreakable.\n\n**Optimization**\nSolving logistics problems — like finding the best delivery routes for thousands of trucks.\n\n**Financial Modeling**\nRunning complex risk analysis and portfolio optimization.\n\n**Climate Modeling**\nSimulating complex climate systems with far greater accuracy.',
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(hours: 1, minutes: 50)),
        ),
      ],
    ),
    Conversation(
      id: 'conv-2',
      title: 'Plan a trip to Japan',
      createdAt: now.subtract(const Duration(hours: 5)),
      updatedAt: now.subtract(const Duration(hours: 5)),
      messages: [
        ChatMessage(
          id: 'msg-2-1',
          content: 'Help me plan a 10-day trip to Japan',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(hours: 5, minutes: 10)),
        ),
        ChatMessage(
          id: 'msg-2-2',
          content:
              "Here's a 10-day Japan itinerary that balances culture, nature, and cuisine:\n\n**Days 1–3: Tokyo**\nExplore Shibuya, Shinjuku, Harajuku, and Akihabara. Visit Senso-ji Temple and teamLab digital art museums.\n\n**Days 4–5: Nikko or Kamakura**\nDay trip to Nikko's ornate shrines or Kamakura's Giant Buddha.\n\n**Days 6–7: Kyoto**\nArashiyama bamboo grove, Fushimi Inari shrine, Gion geisha district.\n\n**Day 8: Nara**\nFeed the friendly deer and visit Todai-ji Temple.\n\n**Days 9–10: Osaka**\nDotonbori food street, Osaka Castle, Universal Studios Japan.",
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(hours: 5)),
        ),
      ],
    ),
    Conversation(
      id: 'conv-3',
      title: 'Write a professional email',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      updatedAt: now.subtract(const Duration(days: 1, hours: 3)),
      messages: [
        ChatMessage(
          id: 'msg-3-1',
          content:
              'Write a professional email requesting a meeting with a potential client',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        ChatMessage(
          id: 'msg-3-2',
          content:
              'Subject: Exploring a Partnership Opportunity\n\nDear [Name],\n\nI hope this message finds you well. I came across your work at [Company] and was genuinely impressed by your approach to [specific area].\n\nI\'d love to schedule a brief 30-minute call to explore whether there\'s a meaningful way we could work together. I believe there\'s real potential for a partnership that could benefit both our teams.\n\nWould you be available sometime this week or next? I\'m flexible and happy to work around your schedule.\n\nLooking forward to connecting.\n\nBest regards,\n[Your Name]',
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(days: 1, hours: 2, minutes: 58)),
        ),
      ],
    ),
    Conversation(
      id: 'conv-4',
      title: 'Explain machine learning',
      createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      updatedAt: now.subtract(const Duration(days: 1, hours: 8)),
      messages: [
        ChatMessage(
          id: 'msg-4-1',
          content: 'What is machine learning and how does it work?',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(days: 1, hours: 8)),
        ),
        ChatMessage(
          id: 'msg-4-2',
          content:
              'Machine learning is a branch of AI where computers **learn from data** rather than being explicitly programmed with rules.\n\nHere\'s how it works:\n\n1. **Feed data** — You give the system thousands or millions of examples.\n2. **Find patterns** — The algorithm identifies patterns and relationships.\n3. **Make predictions** — It uses those patterns to predict outcomes on new data.\n4. **Improve over time** — The more data it sees, the better it gets.\n\nFor example, a spam filter learns what spam looks like by analyzing thousands of emails — without you defining every rule.',
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(days: 1, hours: 7, minutes: 58)),
        ),
      ],
    ),
    Conversation(
      id: 'conv-5',
      title: 'Brainstorm startup ideas',
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
      messages: [
        ChatMessage(
          id: 'msg-5-1',
          content:
              'Give me 5 innovative startup ideas for 2025 that solve real problems',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(days: 3)),
        ),
        ChatMessage(
          id: 'msg-5-2',
          content:
              'Here are 5 startup ideas with genuine potential:\n\n**1. AI-Powered Sleep Coach**\nPersonalized sleep optimization using wearable data + AI to improve sleep quality without medication.\n\n**2. Hyperlocal Carbon Offset Platform**\nConnect individuals with verified local reforestation and clean energy projects they can fund directly.\n\n**3. Skill-Based Immigration Navigator**\nHelp skilled immigrants find opportunities and navigate complex visa systems using AI.\n\n**4. Micro-Learning for Trades**\nBite-sized, mobile-first training for plumbers, electricians, and HVAC technicians.\n\n**5. Elderly Companion AI**\nA voice-first AI companion for seniors that helps with daily tasks, medication reminders, and loneliness.',
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(days: 3)),
        ),
      ],
    ),
    Conversation(
      id: 'conv-6',
      title: 'Python concepts explained',
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
      messages: [
        ChatMessage(
          id: 'msg-6-1',
          content: 'Explain Python decorators with examples',
          role: MessageRole.user,
          timestamp: now.subtract(const Duration(days: 5)),
        ),
        ChatMessage(
          id: 'msg-6-2',
          content:
              'Decorators in Python are a powerful way to **modify or extend functions** without changing their source code.\n\nHere\'s a simple example:\n\n```python\ndef my_decorator(func):\n    def wrapper():\n        print("Before the function")\n        func()\n        print("After the function")\n    return wrapper\n\n@my_decorator\ndef say_hello():\n    print("Hello!")\n\nsay_hello()\n# Output:\n# Before the function\n# Hello!\n# After the function\n```\n\nThe `@my_decorator` syntax is just shorthand for `say_hello = my_decorator(say_hello)`.',
          role: MessageRole.assistant,
          timestamp: now.subtract(const Duration(days: 5)),
        ),
      ],
    ),
  ];
}

/// Streams a canned reply word-by-word. Swap for an API-backed implementation;
/// nothing outside this class knows the difference.
class MockAiRepository implements AiRepository {
  @override
  Stream<String> send(List<ChatMessage> history, {String? context}) async* {
    if (history.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 400));
    final words = _cannedReply(history.last.content).split(' ');
    for (var i = 0; i < words.length; i++) {
      yield i == 0 ? words[i] : ' ${words[i]}';
      await Future.delayed(const Duration(milliseconds: 18));
    }
  }

  String _cannedReply(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('quantum')) {
      return 'Quantum computing uses the principles of quantum mechanics to process information in fundamentally different ways than classical computers.\n\nInstead of bits (0 or 1), quantum computers use **qubits**, which can exist in multiple states simultaneously — a property called superposition.\n\nThis allows quantum computers to explore many solutions at once, making them exceptionally powerful for certain types of problems.';
    } else if (lower.contains('python') || lower.contains('code') || lower.contains('program')) {
      return 'Here\'s a clear explanation:\n\n```python\n# Example code\ndef greet(name: str) -> str:\n    return f"Hello, {name}!"\n\nresult = greet("World")\nprint(result)  # Hello, World!\n```\n\nThis pattern demonstrates clean, readable Python code. Would you like me to go deeper into any aspect of this?';
    } else if (lower.contains('trip') || lower.contains('travel') || lower.contains('japan')) {
      return 'I\'d love to help you plan that! Here\'s a framework to get started:\n\n**Best Time to Visit:** March–May (cherry blossoms) or October–November (autumn foliage)\n\n**Key Destinations:**\n- Tokyo — modern culture and technology\n- Kyoto — traditional temples and geisha districts  \n- Osaka — food capital of Japan\n- Hiroshima — deeply moving historical site\n\nShall I create a detailed day-by-day itinerary for you?';
    } else if (lower.contains('email') || lower.contains('write') || lower.contains('draft')) {
      return 'Here\'s a polished draft you can adapt:\n\n---\n\nSubject: Following Up on Our Conversation\n\nDear [Name],\n\nThank you for taking the time to speak with me earlier. I wanted to follow up on the key points we discussed and ensure we\'re aligned on next steps.\n\n[Add your specific points here]\n\nPlease let me know if you have any questions or would like to discuss further.\n\nBest regards,\n[Your Name]\n\n---\n\nWould you like me to tailor this further for your specific situation?';
    } else if (lower.contains('idea') || lower.contains('brainstorm') || lower.contains('startup')) {
      return 'Let\'s explore this together. Here are some directions to consider:\n\n**High-Impact Areas:**\n1. AI-powered personal productivity tools\n2. Climate tech solutions for everyday consumers\n3. Mental health and wellness platforms\n4. Education technology for underserved markets\n5. Sustainable supply chain transparency\n\nWhich of these resonates most with your interests or skills? I can help you develop any of these concepts further.';
    } else if (lower.contains('explain') || lower.contains('what is') || lower.contains('how does')) {
      return 'Great question! Let me break this down clearly:\n\nAt its core, the concept involves several interconnected principles that build on each other.\n\n**The Foundation**\nThe basic premise is straightforward once you understand the underlying mechanics.\n\n**How It Works**\nThink of it as a layered system where each component serves a specific purpose.\n\n**Why It Matters**\nUnderstanding this can help you make better decisions and solve related problems more effectively.\n\nWould you like me to go deeper into any specific aspect?';
    } else if (lower.contains('help') || lower.contains('how can')) {
      return 'I\'m here to help! Here\'s what I can do for you:\n\n- **Explain** complex topics in simple terms\n- **Write** emails, essays, code, and more\n- **Analyze** information and find patterns\n- **Brainstorm** creative ideas\n- **Plan** projects, trips, and schedules\n- **Learn** any subject together\n\nWhat would you like to work on today?';
    } else {
      return 'That\'s an interesting topic to explore. Let me share some thoughts:\n\nThe key to understanding this is to approach it from multiple angles — the theoretical framework, the practical applications, and the broader implications.\n\n**Here\'s what I find most compelling:**\n\nWhen you dig beneath the surface, you discover patterns that connect this to much larger ideas. These connections are often where the most valuable insights emerge.\n\nI can help you explore this further. What aspect would you like to focus on first?';
    }
  }
}
