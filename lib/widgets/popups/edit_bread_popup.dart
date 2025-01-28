// lib/widgets/popups/edit_bread_popup.dart

import 'package:flutter/material.dart';
import '../../../services/bread_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/bread.dart';

/// 빵 문서 편집 팝업 (이미지 없이 JSON으로만 전송)
class EditBreadPopup extends StatefulWidget {
  final Bread bread;

  const EditBreadPopup({Key? key, required this.bread}) : super(key: key);

  @override
  State<EditBreadPopup> createState() => _EditBreadPopupState();
}

class _EditBreadPopupState extends State<EditBreadPopup> {
  late TextEditingController _nameCtrl;
  late TextEditingController _detailCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _countCtrl;
  Set<int> _selectedStores = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bread.name);
    _detailCtrl = TextEditingController(text: widget.bread.detail ?? '');
    _priceCtrl = TextEditingController(text: '${widget.bread.price ?? 0}');
    _countCtrl = TextEditingController(text: '${widget.bread.count ?? 0}');

    if (widget.bread.stores != null) {
      _selectedStores = widget.bread.stores!.map((s) => s.storeId).toSet();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _detailCtrl.dispose();
    _priceCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  void _pickStores() async {
    final chosen = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) {
        final tmp = {..._selectedStores};
        return AlertDialog(
          title: const Text('판매 지점 선택'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _storeCheckbox(1, '대전역점', tmp, setStateDialog),
                  _storeCheckbox(2, '은행동점(본점)', tmp, setStateDialog),
                  _storeCheckbox(3, '스마트시티점', tmp, setStateDialog),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('취소')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, tmp), child: const Text('확인')),
          ],
        );
      },
    );
    if (chosen != null) {
      setState(() => _selectedStores = chosen);
    }
  }

  Widget _storeCheckbox(int sid, String name, Set<int> tmp, void Function(void Function()) setStateDialog) {
    final isChecked = tmp.contains(sid);
    return CheckboxListTile(
      title: Text(name),
      value: isChecked,
      onChanged: (val) {
        setStateDialog(() {
          if (val == true) tmp.add(sid);
          else tmp.remove(sid);
        });
      },
    );
  }

  /// 문서 수정 버튼 눌렀을 때 (이미지 없음)
  Future<void> _onSubmit() async {
    final uid = AuthService.currentUserId ?? 0;
    if (uid == 0) {
      // 로그인 안 된 상태
      Navigator.pop(context, false);
      return;
    }

    // 새 메서드 사용
    final updated = await BreadService.updateBreadDocNoImage(
      breadId: widget.bread.breadId,
      name: _nameCtrl.text.trim(),
      detail: _detailCtrl.text.trim(),
      price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
      count: int.tryParse(_countCtrl.text.trim()) ?? 0,
      storeIds: _selectedStores.toList(),
    );

    if (updated != null) {
      // 수정 성공
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문서 수정 완료(이미지 없이)')));
      Navigator.pop(context, true);
    } else {
      // 실패
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문서 수정 실패')));
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('빵 문서 편집 (ID: ${widget.bread.breadId})', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '빵 이름'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailCtrl,
              decoration: const InputDecoration(labelText: '상세 내용(마크다운)'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: '가격'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _countCtrl,
              decoration: const InputDecoration(labelText: '재고'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickStores,
              child: Text('판매 지점 선택: ${_selectedStores.join(", ")}'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _onSubmit,
                  child: const Text('저장'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
