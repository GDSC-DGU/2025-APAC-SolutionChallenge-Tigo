import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tigo/app/config/font_system.dart';

class TextDefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TextDefaultAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    required this.preferredSize,
  });

  final String title;
  final List<Widget> actions;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: FontSystem.H3,
        ),
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        actions: actions,
      ),
    );
  }
}
