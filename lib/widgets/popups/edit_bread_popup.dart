// lib/widgets/popups/edit_bread_popup.dart

import 'package:flutter/material.dart';
import '../../../services/bread_service.dart';
import '../../../models/bread.dart';
import '../../../services/auth_service.dart';

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
  // 스토어 체크
  Set<int> _selectedStoreIds = {};

  String? _imagePath; // 새 이미지

  @override
  void initState(){
    super.initState();
    _nameCtrl = TextEditingController(text: widget.bread.name);
    _detailCtrl = TextEditingController(text: widget.bread.detail ?? '');
    _priceCtrl = TextEditingController(text: widget.bread.price?.toString() ?? '0');
    _countCtrl = TextEditingController(text: widget.bread.count?.toString() ?? '0');
    if(widget.bread.stores!=null){
      _selectedStoreIds = widget.bread.stores!.map((s)=>s.storeId).toSet();
    }
  }

  @override
  void dispose(){
    _nameCtrl.dispose();
    _detailCtrl.dispose();
    _priceCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  void _pickImage() async {
    // TODO: file picker
    // e.g. _imagePath = result.files.single.path
    // For now, do dummy
    setState(()=>_imagePath='C:/dummy/test.jpg');
  }

  void _pickStores() async {
    final chosen = await showDialog<Set<int>>(
        context: context,
        builder:(ctx){
          Set<int> temp = {..._selectedStoreIds};
          return AlertDialog(
            title: const Text('판매 지점 선택'),
            content: StatefulBuilder(
              builder:(context,setStateDialog){
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    _storeCheckbox(1,'대전역점',temp,setStateDialog),
                    _storeCheckbox(2,'은행동점(본점)',temp,setStateDialog),
                    _storeCheckbox(3,'스마트시티점',temp,setStateDialog),
                  ],
                );
              },
            ),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(ctx,null), child: const Text('취소')),
              ElevatedButton(onPressed:()=>Navigator.pop(ctx,temp), child: const Text('확인')),
            ],
          );
        }
    );
    if(chosen!=null){
      setState(()=>_selectedStoreIds=chosen);
    }
  }

  Widget _storeCheckbox(int sid, String name, Set<int> temp, void Function(void Function()) setStateDialog){
    final isChecked = temp.contains(sid);
    return CheckboxListTile(
        title: Text(name),
        value: isChecked,
        onChanged:(val){
          setStateDialog((){
            if(val==true) temp.add(sid);
            else temp.remove(sid);
          });
        }
    );
  }

  Future<void> _onSubmit() async {
    final uid = AuthService.currentUserId??0;
    if(uid==0){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      Navigator.pop(context,false);
      return;
    }
    final ok = await BreadService.updateBread(
      breadId: widget.bread.breadId,
      name: _nameCtrl.text.trim(),
      detail: _detailCtrl.text.trim(),
      price: int.tryParse(_priceCtrl.text.trim())??0,
      count: int.tryParse(_countCtrl.text.trim())??0,
      imageFilePath: _imagePath, // null이면 변경없음
      storeIds: _selectedStoreIds.toList(),
    );
    if(!ok){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('편집 실패')));
      Navigator.pop(context,false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('편집 완료')));
      Navigator.pop(context,true);
    }
  }

  @override
  Widget build(BuildContext context){
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            Text('빵 문서 편집 (ID: ${widget.bread.breadId})', style: const TextStyle(fontSize:18)),
            const SizedBox(height:16),
            TextField(
              controller:_nameCtrl,
              decoration: const InputDecoration(labelText:'빵 이름'),
            ),
            const SizedBox(height:8),
            TextField(
              controller:_detailCtrl,
              decoration: const InputDecoration(labelText:'상세 내용(마크다운)'),
              maxLines:3,
            ),
            const SizedBox(height:8),
            TextField(
              controller:_priceCtrl,
              decoration: const InputDecoration(labelText:'가격'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height:8),
            TextField(
              controller:_countCtrl,
              decoration: const InputDecoration(labelText:'재고'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height:8),
            ElevatedButton(
              onPressed:_pickImage,
              child: const Text('이미지 변경'),
            ),
            const SizedBox(height:8),
            ElevatedButton(
              onPressed:_pickStores,
              child: Text('판매 지점 선택: ${_selectedStoreIds.join(", ")}'),
            ),
            const SizedBox(height:16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children:[
                TextButton(
                  onPressed: ()=>Navigator.pop(context,false),
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
