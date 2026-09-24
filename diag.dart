import 'dart:io';

void main() async {
  final client = HttpClient();

  // Test direct PHP file extensions and paths to find what's being routed
  final urls = [
    // Does the server even reach Apache/PHP at all?
    'https://innvikta.co.in/',
    'https://innvikta.co.in/cybershield/',
    // Try the old backup structure which WAS working for login
    'https://innvikta.co.in/cybershield/auth/login.php',
    // The login WAS working before - what changed?
    'https://innvikta.co.in/cybershield/index.html',
    'https://innvikta.co.in/cybershield/index.php',
  ];

  for (final url in urls) {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    final body = await res.transform(const SystemEncoding().decoder).join();
    final preview = body.replaceAll('\n', ' ').replaceAll('\r', '');
    print('${res.statusCode} ${res.headers.value('content-type')} | ${url}');
    print('   └─ ${preview.substring(0, preview.length > 150 ? 150 : preview.length)}\n');
  }

  client.close();
}
