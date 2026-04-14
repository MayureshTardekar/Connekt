import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyD15gKjnQWrbtfAy4deTHVj6IFhIubDk1A';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');
  
  final client = HttpClient();
  try {
    final request = await client.postUrl(url);
    request.headers.contentType = ContentType.json;
    request.write(json.encode({
      "contents": [{"parts":[{"text": "Hi"}], "role": "user"}]
    }));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status: \${response.statusCode}');
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      try {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        print('Parsed successfully: $text');
      } catch (e) {
        print('Parse error: $e');
      }
    } else {
       print('Error details: $responseBody');
    }
  } catch (e) {
    print('Exception: $e');
  } finally {
    client.close();
  }
}
