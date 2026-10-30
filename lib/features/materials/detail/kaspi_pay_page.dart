import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/typography.dart';

/// Kaspi-дегі «Ustaz Tilegi» төлемі.
///
/// Сайттағы oplataPopup.vue сияқты: kaspi.kz/online мекенжайына жасырын
/// форма POST-пен жіберіледі, сонда Kaspi бетінде пайдаланушы ID-і мен сома
/// толтырылып тұрады (GET /pay/... сілтемесі оларды толтырмайды).
/// Kaspi қосымшасын ашатын сілтемелер (intent://, kaspi...://) телефонда ашылады.
class KaspiPayPage extends StatefulWidget {
  const KaspiPayPage({super.key, required this.userId, required this.price});
  final int userId;
  final int price;

  @override
  State<KaspiPayPage> createState() => _KaspiPayPageState();
}

class _KaspiPayPageState extends State<KaspiPayPage> {
  /// Төлемнен кейін Kaspi осы мекенжайға қайтарады — бет жабылады.
  static const _returnUrl = 'https://ust.kz/';

  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigation,
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_formHtml());
  }

  String _formHtml() {
    const esc = HtmlEscape(HtmlEscapeMode.attribute);
    final fields = {
      'TranId': '1',
      'OrderId': '${widget.userId}',
      'Amount': '${widget.price}00',
      'Service': 'UstazTilegi1',
      'returnUrl': _returnUrl,
      'Signature': '',
    };
    final inputs = fields.entries
        .map(
          (e) =>
              '<input type="hidden" name="${e.key}" value="${esc.convert(e.value)}">',
        )
        .join();
    return '<html><body onload="document.forms[0].submit()">'
        '<form method="post" action="https://kaspi.kz/online">$inputs</form>'
        '</body></html>';
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    final url = request.url;
    if (url.startsWith(_returnUrl)) {
      Navigator.of(context).pop();
      return NavigationDecision.prevent;
    }
    if (url.startsWith('http') ||
        url.startsWith('about:') ||
        url.startsWith('data:')) {
      return NavigationDecision.navigate;
    }
    // Kaspi қосымшасына өту
    _openExternal(url);
    return NavigationDecision.prevent;
  }

  Future<void> _openExternal(String url) async {
    var uri = Uri.tryParse(url);
    // Android intent://host/path#Intent;scheme=kaspi;...;end → kaspi://host/path
    if (url.startsWith('intent://')) {
      final scheme = RegExp(r'scheme=([^;]+)').firstMatch(url)?.group(1);
      final fallback = RegExp(r'S\.browser_fallback_url=([^;]+)')
          .firstMatch(url)
          ?.group(1);
      final body = url.substring('intent://'.length).split('#').first;
      if (scheme != null) uri = Uri.tryParse('$scheme://$body');
      if (uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (fallback != null) {
        await _controller.loadRequest(Uri.parse(Uri.decodeComponent(fallback)));
      }
      return;
    }
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Kaspi арқылы төлеу', style: AppText.topBarTitle),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
