import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'book_page_model.dart'; 
import 'reader_home_page.dart';

const String _bookBoxName = 'book_pages_master_box';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookPageModelAdapter());
  }
  
  // ബോക്സ് തുറക്കുന്നു
  var box = await Hive.openBox<BookPageModel>(_bookBoxName);

  // ഫസ്റ്റ് ലോഞ്ചിൽ അസറ്റ് ഡാറ്റ ഓട്ടോമാറ്റിക്കായി ഹൈവിലേക്ക് ലോഡ് ചെയ്യാൻ
  await _loadAssetDataToHive(box);

  runApp(const BookApp());
}

Future<void> _loadAssetDataToHive(Box<BookPageModel> box) async {
  if (box.isEmpty) {
    try {
      // assets/book_content.json ഫയൽ റീഡ് ചെയ്യുന്നു
      final String jsonString = await rootBundle.loadString('assets/book_content.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      for (var item in jsonList) {
        final pageModel = BookPageModel.fromMap(item);
        await box.add(pageModel);
      }
    } catch (e) {
      debugPrint('Asset loading error: $e');
    }
  }
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'തോമാച്ചായാസ് മാസ്റ്റർ ബുക്ക് മാനേജർ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const ReaderHomePage(),
    );
  }
}