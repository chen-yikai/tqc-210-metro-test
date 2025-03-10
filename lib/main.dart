import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(home: MyApp(), debugShowCheckedModeBanner: false));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<dynamic> data = [];
  String stationName = "";
  int currentTime = 0;
  var showSearchBox = false;
  var clear = true;
  var search = TextEditingController();
  var searchText = "";
  var error = false;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    error = false;
    clear = false;
    data = [];
    stationName = "";

    setState(() {});
    final url = Uri.parse('https://skills-flutter-test-api.eliaschen.dev');
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(url);
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final res = await response.transform(utf8.decoder).join();
        setState(() {
          final jsonData = json.decode(res);
          if (jsonData.isNotEmpty) {
            stationName = jsonData[0]["station"];
            data = jsonData[0]["schedule"];
            currentTime = DateTime.parse(jsonData[0]["current_time"])
                .millisecondsSinceEpoch;
          }
        });
      } else {
        throw Exception("network error");
      }
    } catch (e) {
      setState(() {
        error = true;
      });
    } finally {
      httpClient.close();
    }
    setState(() {});
  }

  Color getLineColors(String name) {
    final color = switch (name) {
      "板南線" => Colors.blue,
      "中和新蘆線" => Colors.orange,
      _ => Colors.white
    };
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(!clear
            ? stationName.isNotEmpty
                ? "$stationName站 時刻表"
                : "載入中"
            : "無資料"),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  showSearchBox = !showSearchBox;
                });
              },
              icon: Icon(!showSearchBox ? Icons.search : Icons.search_off)),
          IconButton(
              onPressed: () {
                setState(() {
                  data = [];
                  stationName = "";
                  clear = true;
                });
              },
              icon: const Icon(Icons.delete)),
          IconButton(onPressed: fetchData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            showSearchBox
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: SearchBar(
                      controller: search,
                      hintText: "搜尋 目的地站名 或 路線名",
                      onChanged: (value) {
                        setState(() {});
                      },
                      trailing: [
                        search.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() {
                                    search.text = "";
                                  });
                                },
                                icon: Icon(Icons.clear))
                            : SizedBox()
                      ],
                    ),
                  )
                : SizedBox(),
            Expanded(
                child: !error
                    ? !clear
                        ? data.isNotEmpty
                            ? ListView.builder(
                                itemCount: data.length,
                                itemBuilder: (context, index) {
                                  final it = data[index];
                                  final date =
                                      DateTime.parse(it["arrival_time"]);
                                  final arriveIn =
                                      date.millisecondsSinceEpoch - currentTime;

                                  return it['line']
                                              .toString()
                                              .contains(search.text) ||
                                          it['destination']
                                              .toString()
                                              .contains(search.text)
                                      ? Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                          child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            decoration: BoxDecoration(
                                                                color: getLineColors(
                                                                    it["line"]),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          2),
                                                              child: Text(
                                                                  it["line"]),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 20),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(it["departure"],
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          20)),
                                                              const Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            20),
                                                                child: Icon(
                                                                  Icons
                                                                      .arrow_forward,
                                                                  size: 40,
                                                                ),
                                                              ),
                                                              Text(it["destination"],
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          20)),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 50),
                                                          Container(
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .redAccent,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20)),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          2),
                                                              child: Text(
                                                                  it["status"] !=
                                                                          "進站中"
                                                                      ? "列車目前在 ${it["status"]}"
                                                                      : "列車目前在 $stationName",
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .white)),
                                                            ),
                                                          )
                                                        ],
                                                      ))),
                                              child: ListTile(
                                                  title: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8.0),
                                                    child: RichText(
                                                      text: TextSpan(
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal),
                                                          children: [
                                                            const TextSpan(
                                                                text: "往",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal)),
                                                            TextSpan(
                                                                text: it[
                                                                    "destination"])
                                                          ]),
                                                    ),
                                                  ),
                                                  subtitle: Row(
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                            color:
                                                                getLineColors(
                                                                    it["line"]),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10)),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 5,
                                                                  vertical: 2),
                                                          child: Text(
                                                            it["line"],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: it["status"] !=
                                                          "進站中"
                                                      ? Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            RichText(
                                                                text: TextSpan(
                                                                    children: [
                                                                  TextSpan(
                                                                      text: (arriveIn ~/
                                                                              (60 *
                                                                                  1000))
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .bold,
                                                                          fontSize:
                                                                              25)),
                                                                  const TextSpan(
                                                                      text:
                                                                          "分鐘",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              13))
                                                                ],
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .black))),
                                                          ],
                                                        )
                                                      : Container(
                                                          decoration: BoxDecoration(
                                                              color: Colors.red,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5)),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    8.0),
                                                            child: Text(
                                                              "進站中",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ))),
                                            ),
                                            index + 1 != data.length
                                                ? const Divider()
                                                : const SizedBox(height: 10)
                                          ],
                                        )
                                      : SizedBox();
                                })
                            : const Center(child: CircularProgressIndicator())
                        : Center(
                            child: Text("無資料"),
                          )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.error), Text("發生錯誤")],
                        ),
                      ))
          ],
        ),
      ),
    );
  }
}
