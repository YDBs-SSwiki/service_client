// lib/widgets/popups/login_sheet.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginSheet extends StatefulWidget {
  const LoginSheet({Key? key}) : super(key: key);

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  Future<void> _onLogin() async {
    final ok = await AuthService.googleLogin("fakeIdToken", "홍길동");
    if(ok){
      Navigator.pop(context,true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 실패')));
    }
  }

  Future<void> _onSignup() async {
    final ok = await AuthService.googleLogin("fakeSignupToken", "신규홍길동");
    if(ok){
      Navigator.pop(context,true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('회원가입 실패')));
    }
  }

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child:Column(
          mainAxisSize:MainAxisSize.min,
          children:[
            const SizedBox(height:16),
            const Text('구글 로그인/회원가입', style:TextStyle(fontSize:18)),
            const SizedBox(height:16),
            ElevatedButton(
              onPressed: _onLogin,
              child: const Text('구글 로그인'),
            ),
            const SizedBox(height:8),
            ElevatedButton(
              onPressed: _onSignup,
              child: const Text('구글 회원가입'),
            ),
            const SizedBox(height:32),
          ],
        ),
      ),
    );
  }
}
