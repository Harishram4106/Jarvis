import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis/repositories/openrouter_repository.dart';
import 'package:jarvis/models/conversation.dart';
import 'package:jarvis/repositories/repository_interfaces.dart';

/// The app must never bill the user. Three independent guards stand between a
/// paid model and a request: the picker's price filter, the ':free' id check,
/// and a refusal inside send(). This pins all three.
void main() {
  Map<String, dynamic> model(
    String id, {
    String prompt = '0',
    String completion = '0',
    List<String>? outputs,
    int context = 1000,
  }) =>
      {
        'id': id,
        'name': id,
        'context_length': context,
        'pricing': {'prompt': prompt, 'completion': completion},
        if (outputs != null) 'architecture': {'output_modalities': outputs},
      };

  test('isFree accepts only zero-cost ids', () {
    expect(OpenRouterAiRepository.isFree('meta/llama:free'), isTrue);
    expect(OpenRouterAiRepository.isFree('openrouter/free'), isTrue);
    expect(OpenRouterAiRepository.isFree('openai/gpt-4o'), isFalse);
    // A paid model that merely mentions "free" must not slip through.
    expect(OpenRouterAiRepository.isFree('acme/free-tier-pro'), isFalse);
    expect(OpenRouterAiRepository.isFree(''), isFalse);
  });

  test('parseFreeModels drops anything that costs money', () {
    final parsed = OpenRouterAiRepository.parseFreeModels([
      model('good/a:free'),
      model('paid/prompt:free', prompt: '0.0000005'),
      model('paid/completion:free', completion: '0.000002'),
      model('paid/plain'),
    ]);

    expect(parsed.map((m) => m.id), ['good/a:free']);
  });

  test('parseFreeModels drops non-text models and sorts by context', () {
    final parsed = OpenRouterAiRepository.parseFreeModels([
      model('small/a:free', context: 8000),
      model('music/b:free', outputs: ['text', 'audio']),
      model('big/c:free', context: 128000),
    ]);

    expect(parsed.map((m) => m.id), ['big/c:free', 'small/a:free']);
  });

  test('parseFreeModels survives malformed entries', () {
    // Missing pricing must be treated as paid, not as free.
    final parsed = OpenRouterAiRepository.parseFreeModels([
      {'id': 'nopricing/a:free', 'name': 'x'},
      model('good/b:free'),
    ]);

    expect(parsed.map((m) => m.id), ['good/b:free']);
  });

  test('send refuses a paid model even if one is somehow selected', () {
    final repo = OpenRouterAiRepository(
      apiKey: 'test-key',
      model: 'openai/gpt-4o',
    );

    expect(
      repo.send([
        ChatMessage(
          id: '1',
          content: 'hi',
          role: MessageRole.user,
          timestamp: DateTime(2026),
        ),
      ]).toList(),
      throwsA(isA<AiException>()),
    );
  });
}
