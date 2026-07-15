import 'package:flutter/material.dart';

class MenuConfig extends StatefulWidget {
  final String title;
  final VoidCallback sub;
  final VoidCallback add;
  final ValueChanged<double> change;
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
        Text(widget.title, style: TextStyle(fontSize: 13.0)),
        IconButton(
          onPressed: widget.sub,
          icon: Icon(Icons.remove),
        ),
        Expanded(
          child: Container(
            height: 12,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: widget.value,
                onChanged: (v) {
                  setState(() {
                    widget.change(v);
                  });
                },
                min: widget.min,
                max: widget.max,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.add,
          icon: Icon(Icons.add),
        ),
      ],
    );
  }
}
