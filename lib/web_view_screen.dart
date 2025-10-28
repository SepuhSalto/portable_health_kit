import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import WebView package

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // To show a loading indicator
  String? _loadingError; // To show potential errors

  @override
  void initState() {
    super.initState();

    // Initialize the WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(const Color(0x00000000)) // Transparent background
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Optional: Update loading bar.
            print('WebView loading progress: $progress%');
            if (progress == 100 && mounted) {
              setState(() { _isLoading = false; });
            }
          },
          onPageStarted: (String url) {
             print('WebView page started loading: $url');
             if (mounted) {
                 setState(() {
                     _isLoading = true;
                     _loadingError = null; // Clear previous errors
                 });
             }
          },
          onPageFinished: (String url) {
             print('WebView page finished loading: $url');
             if (mounted) {
               setState(() { _isLoading = false; });
             }
          },
          onWebResourceError: (WebResourceError error) {
            // *** Suppression Logic ***
            bool suppressError = false;

            // Check for ERR_BLOCKED_BY_ORB (Code: -1, but description specific)
            if (error.errorCode == -1 && error.description.contains('ERR_BLOCKED_BY_ORB')) {
              print('WebView: Ignoring ERR_BLOCKED_BY_ORB error.');
              suppressError = true;
            }
            // Check for ERR_SSL_PROTOCOL_ERROR (Code: -11)
            else if (error.errorCode == -11 && error.description.contains('ERR_SSL_PROTOCOL_ERROR')) {
              print('WebView: Ignoring ERR_SSL_PROTOCOL_ERROR.');
              suppressError = true;
            }
            // *** ADD THIS CHECK for ERR_FAILED (Code: -1) ***
            else if (error.errorCode == -1 && error.description.contains('ERR_FAILED')) {
              print('WebView: Ignoring generic ERR_FAILED error.');
              suppressError = true;
            }

            // *** Apply Suppression or Show Error ***
            if (mounted) {
              setState(() { _isLoading = false; }); // Always hide loading on error
              if (!suppressError) { // Only show error if NOT suppressed
                setState(() {
                  _loadingError = 'Gagal memuat halaman: ${error.description} (Code: ${error.errorCode})';
                });
              }
            }
            // *** End Error Handling Logic ***
          },
          
          onNavigationRequest: (NavigationRequest request) {
            // Decide which navigation actions to allow
            // You might want to prevent navigating away from the initial Drive link
            // For now, allow all navigation:
            print('WebView allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // Load the initial URL passed to the screen
      print("WebView initial URL load requested: ${widget.url}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title), // Show the material title in AppBar
        actions: [
            // Optional: Add a refresh button
            if (!_isLoading) IconButton(
               icon: const Icon(Icons.refresh),
               onPressed: () => _controller.reload(),
               tooltip: 'Muat Ulang',
             )
        ],
      ),
      body: Stack( // Use Stack to overlay loading indicator/error message
        children: [
          // The WebView itself
          WebViewWidget(controller: _controller),

          // Loading Indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Error Message Display
          if (_loadingError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.error_outline, color: Colors.red, size: 40),
                       SizedBox(height: 16),
                       Text(
                          _loadingError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                       ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                            icon: Icon(Icons.refresh),
                            label: Text('Coba Lagi'),
                            onPressed: () => _controller.reload(),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700])
                        )
                    ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}