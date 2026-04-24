import 'package:flutter/material.dart';

/// Shared [RouteObserver] so game screens can pause when covered by another route.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
