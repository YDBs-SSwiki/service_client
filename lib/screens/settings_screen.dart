// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../widgets/common/custom_appbar.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const SettingsScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _fontScale=1.0;

  void _onSearch(String val){
    Navigator.pushNamed(context, '/searchResult', arguments: val);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted:_onSearch,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:[
            Row(
              children:[
                const Text('다크모드:'),
                Switch(
                  value: widget.isDarkMode,
                  onChanged: (val){
                    widget.onToggleDarkMode(val);
                  },
                )
              ],
            ),
            Row(
              children:[
                const Text('글자 크기:'),
                Expanded(
                  child: Slider(
                    min:0.5, max:1.5,
                    divisions:4,
                    value:_fontScale,
                    onChanged:(v){
                      setState(()=>_fontScale=v);
                    },
                  ),
                ),
                Text('${(_fontScale*100).toInt()}%')
              ],
            )
          ],
        ),
      ),
    );
  }
}
