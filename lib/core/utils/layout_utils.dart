import 'package:flutter/material.dart';

class RaisedFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const RaisedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    // Lift it 135 pixels from the bottom to stay above the glass NavBar
    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        135;
    return Offset(fabX, fabY);
  }
}
