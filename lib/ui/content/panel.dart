import 'package:flutter/material.dart';
import 'package:network_proxy/network/bin/server.dart';
import 'package:network_proxy/network/http/http.dart';
import 'package:network_proxy/ui/component/share.dart';
import 'package:network_proxy/ui/component/utils.dart';
import 'package:network_proxy/utils/lang.dart';

import 'body.dart';

class NetworkTabController extends StatefulWidget {
  final tabs = [
    'General',
    'Request',
    'Response',
    'Cookies',
  ];

  final ProxyServer proxyServer;
  final ValueWrap<HttpRequest> request = ValueWrap();
  final ValueWrap<HttpResponse> response = ValueWrap();
  final Widget? title;
  final TextStyle? tabStyle;

  NetworkTabController(
      {HttpRequest? httpRequest, HttpResponse? httpResponse, this.title, this.tabStyle, required this.proxyServer})
      : super(key: GlobalKey<NetworkTabState>()) {
    request.set(httpRequest);
    response.set(httpResponse);
  }

  void change(HttpRequest? request, HttpResponse? response) {
    this.request.set(request);
    this.response.set(response);
    var state = key as GlobalKey<NetworkTabState>;
    state.currentState?.changeState();
  }

  @override
  State<StatefulWidget> createState() {
    return NetworkTabState();
  }
}

class NetworkTabState extends State<NetworkTabController> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void changeState() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tabBar = TabBar(
      padding: const EdgeInsets.only(bottom: 0),
      controller: _tabController,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      tabs: widget.tabs.map((title) => Tab(child: Text(title, style: widget.tabStyle, maxLines: 1))).toList(),
    );

    Widget appBar = widget.title == null
        ? tabBar
        : AppBar(
            title: widget.title,
            bottom: tabBar,
            actions: [
              ShareWidget(
                  proxyServer: widget.proxyServer, request: widget.request.get(), response: widget.response.get())
            ],
          );

    return Scaffold(
      endDrawerEnableOpenDragGesture: false,
      appBar: appBar as PreferredSizeWidget?,
      body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
          child: TabBarView(
            controller: _tabController,
            children: [
              general(),
              request(),
              response(),
              cookies(),
            ],
          )),
    );
  }

  Widget general() {
    var request = widget.request.get();
    if (request == null) {
      return const SizedBox();
    }
    var response = widget.response.get();
    var content = [
      rowWidget("Request URL", request.requestUrl),
      const SizedBox(height: 20),
      rowWidget("Request Method", request.method.name),
      const SizedBox(height: 20),
      rowWidget("Status Code", response?.status.toString()),
      const SizedBox(height: 20),
      rowWidget("Remote Address", response?.remoteAddress),
      const SizedBox(height: 20),
      rowWidget("Request Time", request.requestTime.toString()),
      const SizedBox(height: 20),
      rowWidget("Duration", response?.costTime()),
      const SizedBox(height: 20),
      rowWidget("Request Content-Type", request.headers.contentType),
      const SizedBox(height: 20),
      rowWidget("Response Content-Type", response?.headers.contentType),
    ];

    return ListView(children: [expansionTile("General", content)]);
  }

  Widget request() {
    if (widget.request.get() == null) {
      return const SizedBox();
    }
    var scrollController = ScrollController();
    var path = widget.request.get()?.path() ?? '';
    try {
      path = Uri.decodeFull(widget.request.get()?.path() ?? '');
    } catch (_) {}
    return ListView(
        controller: scrollController,
        children: [rowWidget("URI", path), ...message(widget.request.get(), "Request", scrollController)]);
  }

  Widget response() {
    if (widget.response.get() == null) {
      return const SizedBox();
    }

    var scrollController = ScrollController();
    return ListView(controller: scrollController, children: [
      rowWidget("StatusCode", widget.response.get()?.status.toString()),
      ...message(widget.response.get(), "Response", scrollController)
    ]);
  }

  Widget cookies() {
    var requestCookie = _cookieWidget(widget.request.get()?.cookie);

    var responseCookie = widget.response.get()?.headers.getList("Set-Cookie")?.expand((e) => _cookieWidget(e)!);
    return ListView(children: [
      expansionTile("Request Cookies", requestCookie?.toList() ?? []),
      const SizedBox(height: 20),
      expansionTile("Response Cookies", responseCookie?.toList() ?? []),
    ]);
  }

  List<Widget> message(HttpMessage? message, String type, ScrollController scrollController) {
    var headers = <Widget>[];
    message?.headers.forEach((name, values) {
      for (var v in values) {
        headers.add(Row(children: [
          SelectableText('$name: ',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepOrangeAccent)),
          Expanded(child: SelectableText(v, contextMenuBuilder: contextMenu, maxLines: 8, minLines: 1)),
        ]));
        headers.add(const Divider(thickness: 0.1));
      }
    });

    Widget bodyWidgets = HttpBodyWidget(httpMessage: message, scrollController: scrollController);

    Widget headerWidget = ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 0),
        title: Text("$type Headers", style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        shape: const Border(),
        children: headers);

    return [headerWidget, bodyWidgets];
  }

  Widget expansionTile(String title, List<Widget> content) {
    return ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        tilePadding: const EdgeInsets.only(left: 0),
        expandedAlignment: Alignment.topLeft,
        initiallyExpanded: true,
        shape: const Border(),
        children: content);
  }

  Iterable<Widget>? _cookieWidget(String? cookie) {
    return cookie
        ?.split(";")
        .map((e) => Strings.splitFirst(e, "="))
        .where((element) => element != null)
        .map((e) => rowWidget(e!.key, e.value));
  }

  Widget rowWidget(final String name, String? value) {
    return Row(children: [
      Expanded(flex: 2, child: SelectableText(name, style: const TextStyle(fontWeight: FontWeight.w500))),
      Expanded(
          flex: 4,
          child: SelectableText(
            value ?? '',
            contextMenuBuilder: contextMenu,
          ))
    ]);
  }
}
