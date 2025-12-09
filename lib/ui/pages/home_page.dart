import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_paven/services/theme_services.dart';
import 'package:task_paven/ui/pages/add_task_page.dart';
import 'package:task_paven/ui/widgets/button.dart';
import 'package:task_paven/ui/widgets/task_tile.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../services/notification_services.dart';
import '../size_config.dart';
import 'privacy_policy_page.dart';
import 'assistant_page.dart';
import 'dashboard_page.dart';
import '../theme.dart';
import 'package:get_storage/get_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NotifyHelper notifyHelper;
  final _settingsBox = GetStorage();
  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.requestIOSPermissions();
    notifyHelper.initializeNotification();
    _selectedLanguageCode =
        _settingsBox.read<String>('language_code') ?? Get.locale?.languageCode ?? 'en';
    Intl.defaultLocale = _selectedLanguageCode;
    _taskController.getTasks();
  }

  DateTime _selectedDate = DateTime.now();
  final TaskController _taskController = Get.put(TaskController());

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // ignore: deprecated_member_use
        backgroundColor: context.theme.colorScheme.background,
        appBar: _customAppBar(),
        floatingActionButton: _buildAssistantButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Column(
          children: [
            _addTaskBar(),
            TabBar(
              indicatorColor: primaryClr,
              labelColor: primaryClr,
              unselectedLabelColor:
                  Get.isDarkMode ? Colors.white70 : Colors.grey,
              tabs: [
                Tab(text: 'tab_by_day'.tr),
                Tab(text: 'tab_all'.tr),
                Tab(text: 'tab_stats'.tr),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      _addDateBar(),
                      const SizedBox(height: 6),
                      _showTasksForSelectedDate(),
                    ],
                  ),
                  _showAllTasksTimeline(),
                  DashboardPage(taskController: _taskController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _customAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          ThemeServices().switchTheme();
        },
        icon: Icon(
          Get.isDarkMode
              ? Icons.wb_sunny_outlined
              : Icons.nightlight_round_outlined,
          size: 24,
          color: Get.isDarkMode ? Colors.white : darkGreyClr,
        ),
      ),
      elevation: 0,
      // ignore: deprecated_member_use
      backgroundColor: context.theme.colorScheme.background,
      actions: [
        IconButton(
          icon: Icon(Icons.cleaning_services_outlined,
              size: 24, color: Get.isDarkMode ? Colors.white : darkGreyClr),
          onPressed: () {
            notifyHelper.cancelAllNotifications();
            _taskController.deleteAllTasks();
          },
        ),
        GestureDetector(
          onTap: _showProfileMenu,
          child: const CircleAvatar(
            backgroundImage: AssetImage('images/person.jpeg'),
            radius: 18,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
      ],
      centerTitle: true,
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;

        final sheetHeight = MediaQuery.of(context).size.height * 0.5;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  height: sheetHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onBackground.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'account_settings_title'.tr,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'account_settings_subtitle'.tr,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      _LanguageSelectTile(
                        selectedCode: _selectedLanguageCode,
                        onChanged: _updateLanguage,
                      ),
                      const Spacer(),
                      _ProfileActionTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'privacy_item_title'.tr,
                        subtitle: 'privacy_item_subtitle'.tr,
                        selected: false,
                        onTap: () {
                          Navigator.pop(context);
                          Get.to(() => const PrivacyPolicyPage());
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateLanguage(String code) {
    setState(() {
      _selectedLanguageCode = code;
    });
    Get.updateLocale(Locale(code));
    Intl.defaultLocale = code;
    _settingsBox.write('language_code', code);
  }

  Widget _buildAssistantButton() {
    return FloatingActionButton(
      onPressed: () => Get.to(() => const GeminiAssistantPage()),
      backgroundColor: primaryClr,
      child: SvgPicture.asset(
        'images/chatbot.svg',
        width: 26,
        height: 26,
      ),
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 10, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: subHeadingStyle,
              ),
              Text(
                'today_label'.tr,
                style: subHeadingStyle,
              ),
            ],
          ),
          MyButton(
              label: '+ ${'add_task'.tr}',
              onTap: () async {
                await Get.to(() => const AddTaskPage());
                _taskController.getTasks();
              }),
        ],
      ),
    );
  }

  _addDateBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 10, top: 10),
      child: DatePicker(
        DateTime.now(),
        width: 80,
        height: 100,
        initialSelectedDate: _selectedDate,
        selectedTextColor: Colors.white,
        selectionColor: primaryClr,
        dateTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        )),
        dayTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        )),
        monthTextStyle: GoogleFonts.lato(
            textStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        )),
        onDateChange: (newDate) {
          setState(() {
            _selectedDate = newDate;
          });
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    _taskController.getTasks();
  }

  _showTasksForSelectedDate() {
    return Expanded(
      child: Obx(() {
        final filteredTasks = _taskController.taskList
            .where((task) => _isTaskForSelectedDate(task))
            .toList();

        if (filteredTasks.isEmpty) {
          return _noTaskMsg();
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            scrollDirection: SizeConfig.orientation == Orientation.landscape
                ? Axis.horizontal
                : Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              var task = filteredTasks[index];

              _scheduleNotification(task);

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 1375),
                child: SlideAnimation(
                  horizontalOffset: 300,
                  child: FadeInAnimation(
                    child: GestureDetector(
                      onTap: () => _showBottomSheet(context, task),
                      child: TaskTile(task),
                    ),
                  ),
                ),
              );
            },
            itemCount: filteredTasks.length,
          ),
        );
      }),
    );
  }

  bool _isTaskForSelectedDate(Task task) {
    if (task.date == null || task.startTime == null) return false;

    final formattedSelected = DateFormat.yMd().format(_selectedDate);
    if (task.repeat == 'Daily') {
      return true;
    }

    if (task.date == formattedSelected) {
      return true;
    }

    final taskDate = DateFormat.yMd().parse(task.date!);
    if (task.repeat == 'Weekly' &&
        _selectedDate.difference(taskDate).inDays % 7 == 0) {
      return true;
    }

    if (task.repeat == 'Monthly' && taskDate.day == _selectedDate.day) {
      return true;
    }

    return false;
  }

  void _scheduleNotification(Task task) {
    try {
      var date = DateFormat.jm().parse(task.startTime!);
      var myTime = DateFormat('HH:mm').format(date);

      notifyHelper.scheduledNotification(
        int.parse(myTime.toString().split(':')[0]),
        int.parse(myTime.toString().split(':')[1]),
        task,
      );
    } catch (e) {
      print('Error parsing time: $e');
    }
  }

  Widget _showAllTasksTimeline() {
    return Obx(() {
      final tasks = [..._taskController.taskList];
      tasks.sort((a, b) {
        final aDate = _toTaskDateTime(a);
        final bDate = _toTaskDateTime(b);
        return aDate.compareTo(bDate);
      });

      if (tasks.isEmpty) {
        return _noTaskMsg();
      }

      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 1375),
              child: SlideAnimation(
                horizontalOffset: 300,
                child: FadeInAnimation(
                  child: GestureDetector(
                    onTap: () => _showBottomSheet(context, task),
                    child: TaskTile(task),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  DateTime _toTaskDateTime(Task task) {
    try {
      final date = task.date != null
          ? DateFormat.yMd().parse(task.date!)
          : DateTime.now();
      final time = task.startTime != null
          ? DateFormat.jm().parse(task.startTime!)
          : DateTime.now();
      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  _noTaskMsg() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: SizeConfig.screenHeight * 0.55,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'images/task.svg',
                    // ignore: deprecated_member_use
                    color: primaryClr.withOpacity(0.5),
                    height: 96,
                    semanticsLabel: 'Task',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_tasks_title'.tr,
                    style: subHeadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'no_tasks_subtitle'.tr,
                    style: subTitleStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.only(top: 4),
        width: SizeConfig.screenWidth,
        height: (SizeConfig.orientation == Orientation.landscape)
            ? (task.isCompleted == 1
                ? SizeConfig.screenHeight * 0.6
                : SizeConfig.screenHeight * 0.8)
            : (task.isCompleted == 1
                ? SizeConfig.screenHeight * 0.30
                : SizeConfig.screenHeight * 0.39),
        color: Get.isDarkMode ? darkHeaderClr : Colors.white,
        child: Column(
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            task.isCompleted == 1
                ? Container()
                : _buildBottomSheet(
                    label: 'task_completed'.tr,
                    onTap: () {
                      NotifyHelper().cancelNotification(task);
                      _taskController.markTaskAsCompleted(task.id!);
                      Get.back();
                    },
                    clr: primaryClr),
            _buildBottomSheet(
                label: 'delete_task'.tr,
                onTap: () {
                  NotifyHelper().cancelNotification(task);
                  _taskController.deleteTasks(task);
                  Get.back();
                },
                clr: Colors.red[300]!),
            Divider(color: Get.isDarkMode ? Colors.grey : darkGreyClr),
            _buildBottomSheet(
                label: 'cancel'.tr,
                onTap: () {
                  Get.back();
                },
                clr: primaryClr),
            const SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
    ));
  }

  _buildBottomSheet(
      {required String label,
      required Function() onTap,
      required Color clr,
      bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 65,
        width: SizeConfig.screenWidth * 0.9,
        decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: isClose
                  ? Get.isDarkMode
                      ? Colors.grey[600]!
                      : Colors.grey[300]!
                  : clr,
            ),
            borderRadius: BorderRadius.circular(20),
            color: isClose ? Colors.transparent : clr),
        child: Center(
          child: Text(
            label,
            style:
                isClose ? titleStyle : titleStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelectTile extends StatelessWidget {
  const _LanguageSelectTile({
    required this.selectedCode,
    required this.onChanged,
  });

  final String selectedCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.language,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'language_select_label'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'language_select_hint'.tr,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedCode,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                value: 'vi',
                child: Text('language_vi'.tr),
              ),
              DropdownMenuItem(
                value: 'en',
                child: Text('language_en'.tr),
              ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          )
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileActionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 230,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withOpacity(0.08)
              : colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
