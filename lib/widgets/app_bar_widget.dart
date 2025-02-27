import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transcriptomatic/provider/theme_provider.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String name;

  AppBarWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return _buildAppBar(context, themeProvider);
  }

  Widget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return AppBar(
      title: Text(name),
      actions: [
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
