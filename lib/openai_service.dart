import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kiri_ai/secrets.dart';

class OpenAIService {
  final List<Map<String, String>> messages = [];

  // this method will give us yes or no answer from the api.
  // if yes => create an image using dall-e api, if no => basic answer using chatgpt api
  Future<String> isArtPromptAPI(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content':
                  "Does this message want me to generate a picture, image, art or anything similar? '$prompt'. Simply answer with a 'yes' or a 'no'.",
            }
          ],
        }),
      );
      //print(res.body);
      if (res.statusCode == 200) {
        //this is the extraction of the answer/reply from the ai. that is => content
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();
        print(content);

        //giving a condition here whether to run chatgpt api or the dall-e api here
        switch (content) {
          case 'Yes':
          case 'Yes.':
          case 'yes':
          case 'yes.':
            final res = await dallEAPI(prompt);
            return res;
          default:
            final res = await chatGPTAPI(prompt);
            return res;
        }
      }
      return 'An internal error occured.';
    } catch (e) {
      return e.toString();
    }
  }

  // this menthod is the chatgpt api functioning
  Future<String> chatGPTAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
        }),
      );
      //print(res.body);
      if (res.statusCode == 200) {
        //this is the extraction of the answer/reply from the ai. that is => content
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();
        print(content);

        messages.add({
          'role': 'assistant',
          'content': content,
        });

        return content;
      }
      return 'An internal error occured.';
    } catch (e) {
      return e.toString();
    }
  }

  // this menthod is the dall-e api functioning
  Future<String> dallEAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKey',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n': 1,
          'size': '512x512',
        }),
      );
      //print(res.body);
      if (res.statusCode == 200) {
        //this is the extraction of the answer/reply from the ai. that is => content
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
        imageUrl = imageUrl.trim();
        print(imageUrl);

        messages.add({
          'role': 'assistant',
          'content': imageUrl,
        });

        return imageUrl;
      }
      return 'An internal error occured.';
    } catch (e) {
      return e.toString();
    }
  }
}
