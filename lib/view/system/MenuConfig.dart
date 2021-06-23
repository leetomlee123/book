import 'package:flutter/material.dart';

class MenuConfig extends StatefulWidget {
  final String title;
  final Function sub;
  final Function add;
  final Function change;
  final double value;
  final double min;
  final double max;

  MenuConfig(this.sub, this.add, this.change, this.value, this.title,
      {this.min = .1, this.max = 4.0});

  @override
  _MenuConfigState createState() => _MenuConfigState();
}

class _MenuConfigState extends State<MenuConfig> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(this.widget.title, style: TextStyle(fontSize: 13.0)),
        IconButton(
          onPressed: this.widget.sub,
          icon: Icon(Icons.remove),
        ),
        Expanded(
          child: Container(
            height: 12,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Color(0xFF3075EE),
                inactiveTrackColor: Color(0x1A3075EE),
                trackHeight: 2,
                thumbColor: Color(0xFF3075EE),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: this.widget.value,
                onChanged: (v) {
                  setState(() {
                    this.widget.change(v);
                  });
                },
                min: this.widget.min,
                max: this.widget.max,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: this.widget.add,
          icon: Icon(Icons.add),
        ),
        // Text('${this.widget.value.toStringAsFixed(1)}')
      ],
    );
  }
}
