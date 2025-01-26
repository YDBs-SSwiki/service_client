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
  final List<double> _fontScales = [0.5, 0.75, 1.0, 1.25, 1.5];
  double _currentScale = 1.0;

  void _onSearch(String keyword){
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  void _pickFontScale() async {
    final val = await showDialog<double>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('글자 크기'),
          children: [
            for(final s in _fontScales)
              SimpleDialogOption(
                onPressed: ()=>Navigator.pop(ctx, s),
                child: Text(
                  '${(s*100).toInt()}% 크기',
                  style: TextStyle(fontSize:14*s),
                ),
              )
          ],
        )
    );
    if(val!=null){
      setState(()=>_currentScale = val);
    }
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
                const Text('테마: '),
                ElevatedButton(
                  onPressed: ()=> widget.onToggleDarkMode(false),
                  child: const Text('라이트'),
                ),
                const SizedBox(width:10),
                ElevatedButton(
                  onPressed: ()=> widget.onToggleDarkMode(true),
                  child: const Text('다크'),
                ),
              ],
            ),
            const SizedBox(height:16),
            Row(
              children:[
                const Text('글자 크기: '),
                ElevatedButton(
                  onPressed: _pickFontScale,
                  child: Text('${(_currentScale*100).toInt()}%'),
                )
              ],
            ),
            const SizedBox(height:16),
            Text(
              '예시 텍스트.\n현재 ${(_currentScale*100).toInt()}%.',
              style: TextStyle(fontSize:14*_currentScale),
            )
          ],
        ),
      ),
    );
  }
}
