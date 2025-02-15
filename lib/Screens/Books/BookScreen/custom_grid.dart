//
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:dio/dio.dart';
// import 'package:eoffice/Models/oldbook_model.dart';
// import 'package:eoffice/Screens/Books/book_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path/path.dart' as p;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'directory_path.dart';
// import 'package:http/http.dart' as http;
//
// class CustomGrid extends StatefulWidget {
//   const CustomGrid({super.key});
//
//   @override
//   State<CustomGrid> createState() => _CustomGridState();
// }
//
// class _CustomGridState extends State<CustomGrid> {
//   String oldBookUrl = '';
//
//   Future<void> setOldBookUrl()async {
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('id');
//     final url = Uri.parse(
//         "https://eofficess.com/api/getOldBook?user_id=$userId");
//
//     try {
//       final response = await http.post(url);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['success']) {
//           final value = OldBookModel.fromJson(data);
//           print(value);
//          setState(() {
//            oldBookUrl = value.data!.oldBook!;
//          });
//
//         } else {
//           Fluttertoast.showToast(msg: "Error while downloading book");
//         }
//       }
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error : $e");
//     }
//     throw "Unable to load url";
//   }
//
//
//
// @override
//   void initState() {
//    setOldBookUrl();
//     super.initState();
//   }
//
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return GridView(
//       padding: EdgeInsets.all(12),
//       gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 4/3,
//         mainAxisSpacing: 10,
//         crossAxisSpacing: 10,
//       ),
//       children: [
//         CustomContainer(name: "Old Book",fileUrl: 'https://eofficess.com/images/$oldBookUrl',),
//         CustomContainer(name: "eBook",fileUrl: 'https://eofficess.com/images/eofficeManual.pdf',),
//
//       ],
//
//     );
//   }
//
//
// }
//
//
// class CustomContainer extends StatefulWidget {
//   final String name;
//   final String fileUrl;
//   const CustomContainer({super.key, required this.name,
//     required this.fileUrl,
//   });
//
//   @override
//   State<CustomContainer> createState() => _CustomContainerState();
// }
//
// class _CustomContainerState extends State<CustomContainer> {
//   bool dowloading = false;
//   bool fileExists = false;
//   double progress = 0;
//   String fileName = "";
//   late String filePath;
//   late CancelToken cancelToken;
//   var getPathFile = DirectoryPath();
//
//
//   startDownload() async {
//     cancelToken = CancelToken();
//     var storePath = await getPathFile.getPath();
//     filePath = '$storePath/$fileName';
//     setState(() {
//       dowloading = true;
//       progress = 0;
//     });
//
//     try {
//       await Dio().download(widget.fileUrl, filePath,
//           onReceiveProgress: (count, total) {
//             setState(() {
//               progress = (count / total);
//             });
//           }, cancelToken: cancelToken);
//       setState(() {
//         dowloading = false;
//         fileExists = true;
//       });
//     } catch (e) {
//       print(e);
//       setState(() {
//         dowloading = false;
//       });
//     }
//   }
//
//   cancelDownload() {
//     cancelToken.cancel();
//     setState(() {
//       dowloading = false;
//     });
//   }
//
//   checkFileExit() async {
//     var storePath = await getPathFile.getPath();
//     filePath = '$storePath/$fileName';
//     bool fileExistCheck = await File(filePath).exists();
//     setState(() {
//       fileExists = fileExistCheck;
//     });
//   }
//
//   openfile() {
//     // OpenFile.open(filePath);
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => BookScreen(
//           bookPath: filePath,
//         title:widget.name,
//       )),
//     );
//     print("fff $filePath");
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     setState(() {
//       fileName = p.basename(widget.fileUrl);
//
//     });
//     checkFileExit();
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return  InkWell(
//       onTap: ()=> fileExists && dowloading == false ?  openfile(): startDownload(),
//       child: Container(
//           decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               color: Colors.blueGrey
//           ),
//           child: Column(
//             children: [
//               SizedBox(height: 35,),
//               Center(child: Text(widget.name,
//                 style: TextStyle(fontSize: 16,fontWeight:FontWeight.w600,color: Colors.white),),),
//               Spacer(),
//               Container(height: 45,color: Colors.white70,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     if(dowloading)IconButton(
//                         onPressed: () {
//                           fileExists && dowloading == false
//                               ? openfile()
//                               : cancelDownload();
//                         },
//                         icon: fileExists && dowloading == false
//                             ? const Icon(
//                           Icons.window,
//                           color: Colors.green,
//                         )
//                             : const Icon(Icons.close)),
//                     fileExists ? Center(child: Text("Open",style: TextStyle(color: Colors.green,fontWeight: FontWeight.w500,fontSize: 16),)):
//                         Text("Download",style: TextStyle(color: Colors.black,fontWeight: FontWeight.w500),),
//                    if(!fileExists) IconButton(onPressed: (){
//                       fileExists && dowloading == false
//                           ? openfile()
//                           : startDownload();
//                     },
//                                            icon: dowloading?
//                                            Stack(
//                           alignment: Alignment.center,
//                           children: [
//                             CircularProgressIndicator(
//                               value: progress,
//                               strokeWidth: 3,
//                               backgroundColor: Colors.grey,
//                               valueColor: const AlwaysStoppedAnimation<Color>(
//                                   Colors.blue),
//                             ),
//                             Text(
//                               "${(progress * 100).toStringAsFixed(0)}%",
//                               style: TextStyle(fontSize: 12),
//                             )
//                           ],
//                         ):
//                                            Icon(Icons.download))
//                   ],
//                 ),
//               )
//             ],
//           )
//       ),
//     );
//   }
// }
//
//
