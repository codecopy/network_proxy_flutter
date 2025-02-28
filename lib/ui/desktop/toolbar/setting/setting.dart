import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_proxy/network/bin/configuration.dart';
import 'package:network_proxy/network/bin/server.dart';
import 'package:network_proxy/ui/desktop/toolbar/setting/external_proxy.dart';
import 'package:network_proxy/ui/desktop/toolbar/setting/request_rewrite.dart';
import 'package:network_proxy/ui/desktop/toolbar/setting/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'filter.dart';

///设置菜单
class Setting extends StatefulWidget {
  final ProxyServer proxyServer;

  const Setting({super.key, required this.proxyServer});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late ValueNotifier<bool> enableDesktopListenable;
  late Configuration configuration;

  @override
  void initState() {
    configuration = widget.proxyServer.configuration;
    enableDesktopListenable = ValueNotifier<bool>(configuration.enableSystemProxy);
    super.initState();
  }

  @override
  void dispose() {
    enableDesktopListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: "设置",
      icon: const Icon(Icons.settings),
      surfaceTintColor: Colors.white70,
      offset: const Offset(10, 30),
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
              padding: const EdgeInsets.all(0),
              child: PortWidget(proxyServer: widget.proxyServer, textStyle: const TextStyle(fontSize: 13))),
          PopupMenuItem<String>(
              padding: const EdgeInsets.all(0),
              child: ValueListenableBuilder(
                valueListenable: enableDesktopListenable,
                builder: (_, val, __) => setSystemProxy(),
              )),
          const PopupMenuItem(padding: EdgeInsets.all(0), child: ThemeSetting(dense: true)),
          menuItem("域名过滤", onTap: hostFilter),
          menuItem("请求重写", onTap: requestRewrite),
          menuItem("外部代理设置", onTap: setExternalProxy),
          menuItem(
            "Github",
            onTap: () {
              launchUrl(Uri.parse("https://github.com/wanghongenpin/network_proxy_flutter"));
            },
          )
        ];
      },
    );
  }

  PopupMenuItem<String> menuItem(String title, {GestureTapCallback? onTap}) {
    return PopupMenuItem<String>(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          title: Text(title),
          dense: true,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          trailing: const Icon(Icons.arrow_right),
          onTap: onTap,
        ));
  }

  ///设置外部代理地址
  setExternalProxy() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return ExternalProxyDialog(configuration: widget.proxyServer.configuration);
        });
  }

  ///设置系统代理
  Widget setSystemProxy() {
    return SwitchListTile(
        hoverColor: Colors.transparent,
        title: const Text("设置为系统代理"),
        visualDensity: const VisualDensity(horizontal: -4),
        dense: true,
        value: configuration.enableSystemProxy,
        onChanged: (val) {
          widget.proxyServer.setSystemProxyEnable(val);
          configuration.enableSystemProxy = val;
          enableDesktopListenable.value = !enableDesktopListenable.value;
          configuration.flushConfig();
        });
  }

  ///请求重写Dialog
  void requestRewrite() {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            scrollable: true,
            title: Row(children: [
              const Text("请求重写"),
              Expanded(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton.icon(
                          icon: const Icon(Icons.close, size: 15),
                          label: const Text("关闭"),
                          onPressed: () => Navigator.of(context).pop())))
            ]),
            content: RequestRewrite(configuration: configuration),
          );
        });
  }

  ///show域名过滤Dialog
  void hostFilter() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return FilterDialog(configuration: configuration);
      },
    );
  }
}

class PortWidget extends StatefulWidget {
  final ProxyServer proxyServer;
  final TextStyle? textStyle;

  const PortWidget({super.key, required this.proxyServer, this.textStyle});

  @override
  State<StatefulWidget> createState() {
    return _PortState();
  }
}

class _PortState extends State<PortWidget> {
  final textController = TextEditingController();
  final FocusNode portFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    textController.text = widget.proxyServer.port.toString();
    portFocus.addListener(() async {
      //失去焦点
      if (!portFocus.hasFocus && textController.text != widget.proxyServer.port.toString()) {
        widget.proxyServer.configuration.port = int.parse(textController.text);
        if (widget.proxyServer.isRunning) {
          widget.proxyServer.restart();
        }
        widget.proxyServer.configuration.flushConfig();
      }
    });
  }

  @override
  void dispose() {
    portFocus.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Padding(padding: EdgeInsets.only(left: 16)),
      Text("端口号：", style: widget.textStyle),
      SizedBox(
          width: 80,
          child: TextFormField(
            focusNode: portFocus,
            controller: textController,
            textAlign: TextAlign.center,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(5),
              FilteringTextInputFormatter.allow(RegExp("[0-9]"))
            ],
            decoration: const InputDecoration(),
          ))
    ]);
  }
}
