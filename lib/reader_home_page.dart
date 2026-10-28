import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'book_page_model.dart';

const String _bookBoxName = 'book_pages_master_box';

class ReaderHomePage extends StatefulWidget {
  const ReaderHomePage({super.key});

  @override
  State<ReaderHomePage> createState() => _ReaderHomePageState();
}

class _ReaderHomePageState extends State<ReaderHomePage> {
  final TextEditingController _chapterController = TextEditingController();
  final TextEditingController _subheadingController = TextEditingController();
  final TextEditingController _englishContentController = TextEditingController();
  final TextEditingController _malayalamContentController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late Box<BookPageModel> _bookBox;
  int? _editingIndex;
  String _searchQuery = '';
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _bookBox = Hive.box<BookPageModel>(_bookBoxName);
  }

  // ക്യാമറ വഴി ഫോട്ടോ എടുത്ത് OCR വഴി ടെക്സ്റ്റ് റീഡ് ചെയ്യുന്ന മെത്തേഡ്
  Future<void> _scanTextFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      setState(() => _isScanning = true);
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image == null) {
        setState(() => _isScanning = false);
        return;
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();

      if (recognizedText.text.isNotEmpty) {
        setState(() {
          _englishContentController.text = recognizedText.text;
        });
        _showSnackBar('ക്യാമറ വഴി ടെക്സ്റ്റ് വിജയകരമായി സ്കാൻ ചെയ്ത് എടുത്തു!', Colors.green);
      } else {
        _showSnackBar('ഫോട്ടോയിൽ നിന്ന് ടെക്സ്റ്റ് കണ്ടെത്താൻ കഴിഞ്ഞില്ല.', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('സ്കാനിംഗ് എറർ: $e', Colors.red);
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _savePageData() {
    final englishText = _englishContentController.text.trim();
    final malayalamText = _malayalamContentController.text.trim();

    if (englishText.isEmpty && malayalamText.isEmpty) {
      _showSnackBar('ദയവായി ഇംഗ്ലീഷ് അല്ലെങ്കിൽ മലയാളം കണ്ടന്റ് ചേർക്കുക!', Colors.red);
      return;
    }

    final pageModel = BookPageModel(
      chapter: _chapterController.text.trim(),
      subheading: _subheadingController.text.trim(),
      english: englishText,
      malayalam: malayalamText,
      reference: _referenceController.text.trim(),
    );

    if (_editingIndex == null) {
      _bookBox.add(pageModel);
    } else {
      _bookBox.putAt(_editingIndex!, pageModel);
      _editingIndex = null;
    }

    _clearForm();
    setState(() {});
    _showSnackBar('വിവരങ്ങൾ വിജയകരമായി പെർമനെന്റായി സേവ് ചെയ്തു!', Colors.green);
  }

  void _clearForm() {
    _chapterController.clear();
    _subheadingController.clear();
    _englishContentController.clear();
    _malayalamContentController.clear();
    _referenceController.clear();
  }

  void _editPage(int index, BookPageModel page) {
    setState(() {
      _editingIndex = index;
      _chapterController.text = page.chapter;
      _subheadingController.text = page.subheading;
      _englishContentController.text = page.english;
      _malayalamContentController.text = page.malayalam;
      _referenceController.text = page.reference;
    });
  }

  void _deletePage(int index) {
    _bookBox.deleteAt(index);
    if (_editingIndex == index) {
      _editingIndex = null;
      _clearForm();
    }
    setState(() {});
    _showSnackBar('ഡാറ്റ വിജയകരമായി നീക്കം ചെയ്തു.', Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _exportTSDFile() async {
    try {
      var allData = _bookBox.values.toList();
      if (allData.isEmpty) {
        _showSnackBar('എക്സ്പോർട്ട് ചെയ്യാൻ ഡാറ്റയൊന്നും ലഭ്യമല്ല!', Colors.red);
        return;
      }

      String filePath = '${Directory.current.path}/book_master_backup.tsd';
      File file = File(filePath);

      String fileContent = allData.map((e) => e?.toMap().toString() ?? '').join('\n---TSD-SPLIT---\n');
      await file.writeAsString(fileContent);

      _showSnackBar('TSD ഫയൽ വിജയകരമായി സേവ് ചെയ്തു: $filePath', Colors.green);
    } catch (e) {
      _showSnackBar('എറർ വന്നു: $e', Colors.red);
    }
  }

  // സേവ് ചെയ്ത പുസ്തകങ്ങൾ ഫുൾ സ്ക്രീനിൽ കാണാനുള്ള ഡയലോഗ് വ്യൂവർ
  void _openSavedBooksModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.98,
          height: MediaQuery.of(context).size.height * 0.95,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('സേവ് ചെയ്ത പുസ്തക ഭാഗങ്ങൾ (Full View)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(child: _buildSavedBookListView()),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreenReader(BookPageModel page) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.92,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      page.chapter,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (page.subheading.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  page.subheading,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
              const Divider(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ENGLISH ORIGINAL:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 10),
                            SelectableText(
                              page.english,
                              style: const TextStyle(fontSize: 18, height: 1.7, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 30),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MALAYALAM TRANSLATION:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 10),
                            SelectableText(
                              page.malayalam,
                              style: const TextStyle(fontSize: 18, height: 1.7, color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (page.reference.isNotEmpty) ...[
                const Divider(height: 20),
                SelectableText(
                  "Ref: ${page.reference}",
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // മുകളിലെ ഹെഡർ (AppBar) പൂർണ്ണമായി ഒഴിവാക്കി ഫുൾ സ്ക്രീൻ വർക്ക് ഏരിയ നൽകിയിരിക്കുന്നു
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            children: [
              // ടോപ്പ് കോംപാക്റ്റ് കൺട്രോൾ ബാർ (സേവ് ചെയ്തവ കാണാനും ബാക്ക്അപ്പ് എടുക്കാനും ക്യാമറ സ്കാൻ ചെയ്യാനും)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                        decoration: InputDecoration(
                          labelText: 'ചാപ്റ്ററോ ഉള്ളടക്കമോ തിരയുക...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _scanTextFromCamera,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    icon: _isScanning 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.camera_alt, size: 16),
                    label: const Text('സ്കാൻ (OCR)', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: _openSavedBooksModal,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    icon: const Icon(Icons.list_alt, size: 16),
                    label: const Text('സേവ് ചെയ്തവ', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.save_alt, color: Colors.blueGrey),
                    tooltip: 'TSD ബാക്ക്അപ്പ്',
                    onPressed: _exportTSDFile,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ഫുൾ സ്ക്രീൻ ഇൻപുട്ട് ഫോം ഏരിയ (ഇനി സൈഡിൽ സ്ഥലം വേസ്റ്റ് ആകില്ല)
              Expanded(
                child: _buildInputFormCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFormCard() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingIndex == null ? 'പുതിയ പേജ് / ചാപ്റ്റർ ചേർക്കുക' : 'പേജ് എഡിറ്റ് ചെയ്യുന്നു',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                ),
                if (_editingIndex != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editingIndex = null;
                        _clearForm();
                      });
                    },
                    child: const Text('ക്യാൻസൽ', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _chapterController,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Name (ഉദാ: CHAPTER ONE)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _subheadingController,
                      decoration: const InputDecoration(
                        labelText: 'Subheading / Sub-division',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _englishContentController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 15),
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: 'English Original Content (ക്യാമറ സ്കാൻ ചെയ്താൽ ഇവിടെ വരും)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _malayalamContentController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 15),
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        labelText: 'Malayalam Translation',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: TextField(
                controller: _referenceController,
                maxLines: 1,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'References / Footnotes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bookmark_border, size: 16),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _savePageData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save, size: 16),
                label: Text(
                  _editingIndex == null ? 'പെർമനെന്റായി സേവ് ചെയ്യുക' : 'മാറ്റങ്ങൾ അപ്ഡേറ്റ് ചെയ്യുക',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedBookListView() {
    return ValueListenableBuilder(
      valueListenable: _bookBox.listenable(),
      builder: (context, Box<BookPageModel> box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('ഇതുവരെ ഡാറ്റയൊന്നും സേവ് ചെയ്തിട്ടില്ല.', style: TextStyle(fontSize: 13)),
            ),
          );
        }

        List<int> filteredIndices = [];
        for (int i = 0; i < box.length; i++) {
          final page = box.getAt(i);
          if (page != null) {
            String chapter = page.chapter.toLowerCase();
            String english = page.english.toLowerCase();
            String malayalam = page.malayalam.toLowerCase();

            if (_searchQuery.isEmpty ||
                chapter.contains(_searchQuery) ||
                english.contains(_searchQuery) ||
                malayalam.contains(_searchQuery)) {
              filteredIndices.add(i);
            }
          }
        }

        if (filteredIndices.isEmpty) {
          return const Center(child: Text('തിരച്ചിലിന് അനുയോജ്യമായ ഫലങ്ങൾ ലഭ്യമല്ല.', style: TextStyle(fontSize: 13)));
        }

        return ListView.builder(
          itemCount: filteredIndices.length,
          itemBuilder: (context, idx) {
            int index = filteredIndices[idx];
            final page = box.getAt(index);
            if (page == null) return const SizedBox.shrink();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            page.chapter.isEmpty ? "Chapter" : page.chapter,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.fullscreen, color: Colors.indigo, size: 18),
                              tooltip: 'ഫുൾ സ്ക്രീനിൽ കാണുക',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context); // മോഡൽ ക്ലോസ് ചെയ്ത് ഫുൾ വ്യൂവറിലേക്ക് പോകാം
                                _openFullScreenReader(page);
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange, size: 16),
                              tooltip: 'എഡിറ്റ് ചെയ്യുക',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context);
                                _editPage(index, page);
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                              tooltip: 'ഡിലീറ്റ് ചെയ്യുക',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deletePage(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (page.subheading.isNotEmpty)
                      Text(
                        page.subheading,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            "EN: ${page.english}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "ML: ${page.malayalam}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}