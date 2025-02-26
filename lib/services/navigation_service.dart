import 'package:flutter/material.dart';

//to manage navigation between different screens in our app
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  //this function removes the current screen from the stack and navigates to a new named route.
  void removeAndNavigateToRoute(String _route) {
    navigatorKey.currentState?.popAndPushNamed(_route);
  }

  // thisi function navigates to a new named route without removing the current screen.
  void navgateToRoute(String _route) {
    navigatorKey.currentState?.pushNamed(_route);
  }

  //this function pops up the current screen and goes back.
  void goBack() {
    navigatorKey.currentState?.pop();
  }
}
