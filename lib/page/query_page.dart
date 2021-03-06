import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fstar/model/application.dart';
import 'package:fstar/model/box_name.dart';
import 'package:fstar/model/course_map.dart';
import 'package:fstar/model/score_display_mode_enum.dart';
import 'package:fstar/model/score_list.dart';
import 'package:fstar/model/score_query_mode_enum.dart';
import 'package:fstar/model/system_mode_enum.dart';
import 'package:fstar/page/score_page.dart';
import 'package:fstar/page/sport_score_page.dart';
import 'package:fstar/utils/FStarNet.dart';
import 'package:fstar/utils/logger.dart';
import 'package:fstar/utils/parser.dart';
import 'package:fstar/utils/requester.dart';
import 'package:fstar/utils/utils.dart';
import 'package:fstar/widget/timer_count_down_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueryPage extends StatefulWidget {
  @override
  State createState() => _QueryPageState();
}

class _QueryPageState extends State<QueryPage> with WidgetsBindingObserver {
  final _scoreList = getBoxData<ScoreList>(BoxName.scoreBox);
  final _scoreScrollController = ScrollController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _scoreList)],
      builder: (BuildContext context, Widget child) {
        return Consumer<ScoreList>(
            builder: (BuildContext context, score, Widget child) {
          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  child: ListView.separated(
                    itemCount: score.list.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = score.list[index];
                      return ListTile(
                        leading: Text(
                          '${index + 1}',
                          style: TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          showScoreDetails(context, item);
                        },
                        subtitle: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                item.score,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode(context)
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return Divider();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final settings = getSettingsData();
                        final user = getUserData();
                        if (user.jwAccount == null || user.jwPassword == null) {
                          EasyLoading.showToast('没有验证教务系统账号');
                          return;
                        }
                        switch (settings.scoreQueryMode) {
                          case ScoreQueryMode.DEFAULT:
                            _handleScoreQuery(context);
                            break;
                          case ScoreQueryMode.ALTERNATIVE:
                            AwesomeDialog(
                              context: context,
                              dialogType: DialogType.INFO,
                              body: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Text.rich(
                                    TextSpan(
                                      text: "该入口仅在评教系统未开放的时候使用，"
                                          "为不影响学校的评教秩序，"
                                          "请在评教系统开放之后及时评教（工具页）并换回默认入口！",
                                      children: [
                                        TextSpan(
                                          text: "注意：",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        TextSpan(
                                            text: "此入口计算的绩点可能不准确（有挂科的情况）"
                                                "请以"),
                                        TextSpan(
                                          text: "默认入口",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        TextSpan(text: "计算的绩点为准！")
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              btnOk: TimerCountDownButton(
                                onPressed: () {
                                  _handleScoreQuery(context);
                                  Navigator.pop(context);
                                },
                              ),
                            ).show();
                            break;
                        }
                      },
                      child: Text('学业成绩'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final settings = getSettingsData();
                        final user = getUserData();
                        if (user.tyAccount == null || user.tyPassword == null) {
                          EasyLoading.showToast('没有验证体育账号');
                          return;
                        }
                        switch (settings.systemMode) {
                          case SystemMode.JUST:
                            try {
                              EasyLoading.show(status: '正在请求成绩');
                              await Future.delayed(Duration(milliseconds: 375));
                              final sportScoreRequester = SportScoreRequester();
                              final sportScoreParser = SportScoreParser();
                              final content =
                                  await sportScoreRequester.action();
                              sportScoreParser.action(content);
                              EasyLoading.dismiss();
                              pushPage(
                                  context,
                                  SportScore(
                                      scoreData: sportScoreParser.score));
                            } catch (e) {
                              Log.logger.e(e.toString());
                              EasyLoading.showError(e.toString());
                            }
                            break;
                          case SystemMode.VPN:
                            try {
                              EasyLoading.show(status: '正在请求成绩');
                              await Future.delayed(Duration(milliseconds: 375));
                              final sportScoreRequester =
                                  VPNSportScoreRequester();
                              final sportScoreParser = SportScoreParser();
                              final content =
                                  await sportScoreRequester.action();
                              sportScoreParser.action(content);
                              EasyLoading.dismiss();
                              pushPage(
                                  context,
                                  SportScore(
                                      scoreData: sportScoreParser.score));
                            } catch (e) {
                              Log.logger.e(e.toString());
                              EasyLoading.showError(e.toString());
                            }
                            break;
                          case SystemMode.VPN2:
                            EasyLoading.showToast('待实现');
                            // TODO: Handle this case.
                            break;
                          case SystemMode.CLOUD:
                            EasyLoading.showToast('待实现');
                            // TODO: Handle this case.
                            break;
                        }
                      },
                      child: Text('体育成绩'),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                ),
              )
            ],
          );
        });
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Log.logger.i('resumed');
        break;
      case AppLifecycleState.inactive:
        Log.logger.i('inactive');
        break;
      case AppLifecycleState.paused:
        Log.logger.i('paused');
        break;
      case AppLifecycleState.detached:
        Log.logger.i('detached');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _scoreScrollController.dispose();
  }

  _buildCourseToday(CourseMap courseMap) {
    final currentWeek = getCurrentWeek() + 1;
    final today = DateTime.now().weekday;
    return courseMap.dataMap[today]
        .where((element) => element.week.contains(currentWeek))
        .map(
          (course) => Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                        '${course.row}-${course.row + course.rowSpan - 1}'),
                  ),
                ),
                Expanded(flex: 3, child: Center(child: Text(course.name))),
                Expanded(flex: 3, child: Center(child: Text(course.classroom)))
              ],
            ),
          ),
        )
        .toList();
  }

  void _handleScoreQuery(BuildContext context) async {
    EasyLoading.show(status: '正在请求最新成绩');
    await Future.delayed(Duration(milliseconds: 375));
    try {
      var score = await Application.getScore();
      if (score.isEmpty) {
        EasyLoading.showToast('该学期没有成绩或者未评教');
        return;
      }
      final settings = getSettingsData();
      if (settings.reverseScore) {
        score = score.reversed.toList();
      }
      if (settings.saveScoreCloud &&
          settings.scoreDisplayMode == ScoreDisplayMode.MAX &&
          settings.scoreQueryMode == ScoreQueryMode.DEFAULT) {
        compute(calculateDigest, score.toString()).then((digest) async {
          var prefs = await SharedPreferences.getInstance();
          var next = digest.toString();
          var pre = prefs.getString('scoreDigest');
          if (pre != next) {
            prefs.setString('scoreDigest', digest.toString());
            FStarNet().uploadScore(score);
          }
        });
      }
      pushPage(context, ScorePage(score));
      EasyLoading.dismiss();
      context.read<ScoreList>()
        ..list = score
        ..save();
    } catch (e) {
      Log.logger.e(e.toString());
      EasyLoading.showError(e.toString());
    }
  }

  _buildScoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              final settings = getSettingsData();
              final user = getUserData();
              if (user.jwAccount == null || user.jwPassword == null) {
                EasyLoading.showToast('没有验证教务系统账号');
                return;
              }
              switch (settings.scoreQueryMode) {
                case ScoreQueryMode.DEFAULT:
                  _handleScoreQuery(context);
                  break;
                case ScoreQueryMode.ALTERNATIVE:
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.INFO,
                    body: Center(
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Text.rich(
                          TextSpan(
                            text: "该入口仅在评教系统未开放的时候使用，"
                                "为不影响学校的评教秩序，"
                                "请在评教系统开放之后及时评教（工具页）并换回默认入口！",
                            children: [
                              TextSpan(
                                text: "注意：",
                                style: TextStyle(color: Colors.red),
                              ),
                              TextSpan(
                                  text: "此入口计算的绩点可能不准确（有挂科的情况）"
                                      "请以"),
                              TextSpan(
                                text: "默认入口",
                                style: TextStyle(color: Colors.red),
                              ),
                              TextSpan(text: "计算的绩点为准！")
                            ],
                          ),
                        ),
                      ),
                    ),
                    btnOk: TimerCountDownButton(
                      onPressed: () {
                        _handleScoreQuery(context);
                        Navigator.pop(context);
                      },
                    ),
                  ).show();
                  break;
              }
              // switch (settings.systemMode) {
              //   case SystemMode.JUST:
              //     break;
              //   case SystemMode.VPN:
              //     _handleScoreQuery(context);
              //     break;
              //   case SystemMode.VPN2:
              //     EasyLoading.showToast('待实现');
              //     // TODO: Handle this case.
              //     break;
              //   case SystemMode.CLOUD:
              //     EasyLoading.showToast('待实现');
              //     // TODO: Handle this case.
              //     break;
              // }
            },
            child: Text('学业成绩'),
          ),
          TextButton(
            onPressed: () async {
              final settings = getSettingsData();
              final user = getUserData();
              if (user.tyAccount == null || user.tyPassword == null) {
                EasyLoading.showToast('没有验证体育账号');
                return;
              }
              switch (settings.systemMode) {
                case SystemMode.JUST:
                  try {
                    EasyLoading.show(status: '正在请求成绩');
                    await Future.delayed(Duration(milliseconds: 375));
                    final sportScoreRequester = SportScoreRequester();
                    final sportScoreParser = SportScoreParser();
                    final content = await sportScoreRequester.action();
                    sportScoreParser.action(content);
                    EasyLoading.dismiss();
                    pushPage(
                        context, SportScore(scoreData: sportScoreParser.score));
                  } catch (e) {
                    Log.logger.e(e.toString());
                    EasyLoading.showError(e.toString());
                  }
                  break;
                case SystemMode.VPN:
                  EasyLoading.showToast('待实现');
                  // TODO: Handle this case.
                  break;
                case SystemMode.VPN2:
                  EasyLoading.showToast('待实现');
                  // TODO: Handle this case.
                  break;
                case SystemMode.CLOUD:
                  EasyLoading.showToast('待实现');
                  // TODO: Handle this case.
                  break;
              }
            },
            child: Text('体育成绩'),
          ),
          TextButton(
            child: Text('实验成绩'),
            onPressed: () {
              EasyLoading.showToast('待实现');
            },
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceAround,
      ),
    );
  }

  _buildScore(BuildContext context) {
    return Consumer<ScoreList>(
        builder: (BuildContext context, value, Widget child) {
      final score = value.list;
      return Container(
        height: MediaQuery.of(context).size.height / 2,
        child: NotificationListener<OverscrollNotification>(
          onNotification: _handleOverscrollNotification,
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            controller: _scoreScrollController,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: InkWell(
                  onTap: () {
                    showScoreDetails(context, score[index]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              score[index].name,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Text(
                              score[index].score,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
            itemCount: score.length,
          ),
        ),
      );
    });
  }

  bool _handleOverscrollNotification(OverscrollNotification notification) {
    bool onTop = notification.overscroll < 0 ? true : false;
    if ((onTop &&
            _scrollController.position.minScrollExtent !=
                _scrollController.offset) ||
        (!onTop &&
            _scrollController.position.maxScrollExtent !=
                _scrollController.offset)) {
      if (onTop &&
          _scrollController.offset + notification.overscroll <
              _scrollController.position.minScrollExtent) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      } else if (!onTop &&
          _scrollController.offset + notification.overscroll >
              _scrollController.position.maxScrollExtent) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        _scrollController
            .jumpTo(_scrollController.offset + notification.overscroll);
      }
    }
    return true;
  }
}
