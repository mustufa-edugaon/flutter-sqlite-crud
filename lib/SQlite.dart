
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'db_helper.dart';

late Size mq;

class HomeScreenApp extends StatefulWidget {
  const HomeScreenApp({Key? key}) : super(key: key);

  @override
  State<HomeScreenApp> createState() => _HomeScreenAppState();
}

class _HomeScreenAppState extends State<HomeScreenApp> {
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  late TextEditingController titleController;
  late TextEditingController descController;

  @override
  void initState() {
    super.initState();
    _refresh();
    titleController = TextEditingController();
    descController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  void _refresh() async {
    try {
      final data = await SQLHelper.getAllData();
      setState(() {
        _allData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addData() async {
    await SQLHelper.createData(titleController.text, descController.text, _imagePath!.path);
    _refresh();
  }

  Future<void> _updateData(int id) async {
    await SQLHelper.updateData(id, titleController.text, descController.text, _imagePath!.path);
    _refresh();
  }

  Future<void> _deleteData(int id) async {
    await SQLHelper.deleteData(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Data deleted'),
      backgroundColor: Colors.red,
    ));
    _refresh();
  }
    File? _imagePath;
    void pickImage() async{
      var imagePicker = await ImagePicker().pickImage(source: ImageSource.gallery);
      if(imagePicker != null){
        _imagePath = File(imagePicker.path);
        setState(() {
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Selected Image"),
              content: Container(
                width: 200, // Set width as needed
                height: 200, // Set height as needed
                child: Image.file(_imagePath!),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_imagePath!.path)));
    }

  void showBottomSheet(int? id) async {
    if (id != null) {
      final existingData =
      _allData.firstWhere((element) => element['id'] == id);
      titleController.text = existingData['title'];
      descController.text = existingData['desc'];
    } else {
      titleController.text = '';
      descController.text = '';
    }
    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          top: 30,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            IconButton(
                onPressed: (){
                  pickImage();
            },
                icon: Icon(Icons.camera_enhance)
            ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (id == null) {
                  await _addData().then((value) => print("add data"));
                } else {
                  await _updateData(id);
                }
                titleController.clear();
                descController.clear();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(id == null ? "Add Data" : "Update Data"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
      mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite'),
        backgroundColor: CupertinoColors.lightBackgroundGray,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          :ListView.builder(
        itemCount: _allData.length,
        itemBuilder: (context, index) {
          final itemData = _allData[index];

          return ClipRRect(// Wrap with ClipRRect for rounded corners
            borderRadius: BorderRadius.circular(10.0), // Adjust corner radius
            child: Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04,vertical: mq.height * 0.01),
              color: Colors.grey[200],
              child: ListTile(
                leading: CircleAvatar(
                  radius: 30, // Adjust radius as needed
                  backgroundImage: FileImage(File(itemData['image'])),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4), // Adjust padding
                  child: Text(
                    itemData['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(bottom: 8), // Adjust padding
                  child: Text(
                    itemData['desc'],
                    style: const TextStyle(
                      fontSize: 16,
                      color:Colors.teal,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue), // Set icon color
                      onPressed: () {
                        showBottomSheet(itemData['id']);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.blue), // Set icon color
                      onPressed: () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirm Delete"),
                            content: Text("Are you sure you want to delete this item?"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(), // Close dialog
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteData(itemData['id']); // Delete using itemData
                                  Navigator.of(context).pop(); // Close dialog
                                },
                                child: Text("Delete"),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                onTap: () => showBottomSheet(itemData['id']),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: Icon(Icons.add),
      ),
    );
  }
}
