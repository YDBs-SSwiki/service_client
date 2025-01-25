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
    Navigator.pushNamed(context, '/searchResult', arguments: keyword);
  }

  void _pickFontScale() async {
    final val = await showDialog<double>(
        context: context,
        builder:(ctx){
          return SimpleDialog(
            title: const Text('글자 크기'),
            children: _fontScales.map((scale){
              return SimpleDialogOption(
                onPressed: ()=>Navigator.pop(ctx, scale),
                child: Text('${(scale*100).toInt()}% 크기', style: TextStyle(fontSize:14*scale)),
              );
            }).toList(),
          );
        }
    );
    if(val!=null){
      setState(()=>_currentScale=val);
      // 실제로 전체 글씨에 반영하려면 Provider 등...
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
                const Text('다크모드:'),
                Switch(
                  value: widget.isDarkMode,
                  onChanged: (val){
                    widget.onToggleDarkMode(val);
                  },
                )
              ],
            ),
            const SizedBox(height:16),
            Row(
              children:[
                const Text('글자 크기 (리스트 선택): '),
                ElevatedButton(
                  onPressed:_pickFontScale,
                  child: Text('${(_currentScale*100).toInt()}%'),
                ),
              ],
            ),
            const SizedBox(height:16),
            Text(
              '예시 텍스트입니다.\n이 글자 크기가 실시간으로 변하는 것은 예시로.\n(실제 프로젝트에서는 Provider/InheritedWidget 등으로 전체 앱에 반영)',
              style: TextStyle(fontSize: 14*_currentScale),
            )
          ],
        ),
      ),
    );
  }
}
