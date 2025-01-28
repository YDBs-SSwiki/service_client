// lib/widgets/popups/edit_bread_popup.dart

import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../../../services/bread_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/bread.dart';

/// 빵 문서 편집 팝업 (이미지 업로드 가능, 웹 + 모바일/데스크톱 동시 대응)
/// 서버 코드 변경 없이, /bread/{breadId}/update 로 multipart/form-data 전송:
///  - @RequestPart("bread") UpdateBreadRequestDTO (JSON)
///  - @RequestPart("imageFile", required=false) MultipartFile
class EditBreadPopup extends StatefulWidget {
  final Bread bread;

  const EditBreadPopup({Key? key, required this.bread}) : super(key: key);

  @override
  State<EditBreadPopup> createState() => _EditBreadPopupState();
}

class _EditBreadPopupState extends State<EditBreadPopup> {
  // 텍스트필드 컨트롤러
  late TextEditingController _nameCtrl;
  late TextEditingController _detailCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _countCtrl;

  // 선택된 매장 ID 집합
  Set<int> _selectedStores = {};

  // 이미지 (웹 vs 모바일/데스크톱)
  //  - 웹: _imageBytes
  //  - 모바일: _imagePath
  String? _imagePath;
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void initState() {
    super.initState();

    // 빵 엔티티 값으로 초기화
    _nameCtrl = TextEditingController(text: widget.bread.name);
    _detailCtrl = TextEditingController(text: widget.bread.detail ?? '');
    _priceCtrl = TextEditingController(text: '${widget.bread.price ?? 0}');
    _countCtrl = TextEditingController(text: '${widget.bread.count ?? 0}');

    // 매장 정보
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

  /// 이미지 파일 선택
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // 웹 환경에서 bytes 필요
    );
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      _imageName = f.name;
      if (kIsWeb) {
        // 웹 => bytes
        _imageBytes = f.bytes;
        _imagePath = null;
      } else {
        // 모바일/데스크톱 => path
        _imagePath = f.path;
        _imageBytes = null;
      }
      setState(() {});
    }
  }

  /// 판매 지점 선택 (예시)
  /// 여기서는 그냥 토글 방식 예시
  Future<void> _pickStores() async {
    final tmp = {..._selectedStores};
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) {
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
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, tmp),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() => _selectedStores = result);
    }
  }

  Widget _storeCheckbox(
      int sid,
      String storeName,
      Set<int> tmp,
      void Function(void Function()) setStateDialog,
      ) {
    final isChecked = tmp.contains(sid);
    return CheckboxListTile(
      title: Text(storeName),
      value: isChecked,
      onChanged: (checked) {
        setStateDialog(() {
          if (checked == true) {
            tmp.add(sid);
          } else {
            tmp.remove(sid);
          }
        });
      },
    );
  }

  /// 서버 전송 (문서 수정)
  Future<void> _onSubmit() async {
    // 로그인 체크
    if (!AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 안 됨')),
      );
      Navigator.pop(context, false);
      return;
    }

    final breadId = widget.bread.breadId;

    // 이미지 파일 생성
    MultipartFile? imageFile;
    if (kIsWeb && _imageBytes != null) {
      // 웹 => fromBytes
      // MIME 추론
      String mimeType = 'image/png';
      final lowerName = (_imageName ?? '').toLowerCase();
      if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (lowerName.endsWith('.gif')) {
        mimeType = 'image/gif';
      }
      imageFile = MultipartFile.fromBytes(
        _imageBytes!,
        filename: _imageName ?? 'upload.jpg',
        contentType: MediaType.parse(mimeType),
      );
    } else if (!kIsWeb && _imagePath != null) {
      // 모바일 / 데스크톱 => fromFile
      imageFile = await MultipartFile.fromFile(
        _imagePath!,
        filename: _imageName,
        // contentType: MediaType('image', 'png') // 필요시
      );
    }

    // 문서 수정 API 호출
    final priceVal = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    final countVal = int.tryParse(_countCtrl.text.trim()) ?? 0;

    final success = await BreadService.updateBreadDocWithImage(
      breadId: breadId,
      name: _nameCtrl.text.trim(),
      detail: _detailCtrl.text.trim(),
      price: priceVal,
      count: countVal,
      storeIds: _selectedStores.toList(),
      imageFile: imageFile, // null이면 이미지 안 바꿈
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문서 수정 완료!')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문서 수정 실패')),
      );
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
            Text('빵 문서 편집 (ID: ${widget.bread.breadId})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '빵 이름'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _detailCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '상세 내용(마크다운)'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '가격'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '재고'),
            ),
            const SizedBox(height: 8),

            // 매장 선택 버튼
            ElevatedButton(
              onPressed: _pickStores,
              child: Text('판매 지점 선택: ${_selectedStores.join(", ")}'),
            ),
            const SizedBox(height: 8),

            // 이미지 선택
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('이미지 선택'),
            ),
            // 웹이면 _imageBytes, 모바일이면 _imagePath
            if (kIsWeb && _imageBytes != null)
              Text('웹 이미지: $_imageName (${_imageBytes!.lengthInBytes} bytes)')
            else if (!kIsWeb && _imagePath != null)
              Text('모바일 이미지: $_imagePath'),

            const SizedBox(height: 16),
            // 저장 버튼
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
