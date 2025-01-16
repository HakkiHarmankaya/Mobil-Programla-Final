import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(PersonalAssistantApp());

class PersonalAssistantApp extends StatefulWidget {
  @override
  _PersonalAssistantAppState createState() => _PersonalAssistantAppState();
}

class _PersonalAssistantAppState extends State<PersonalAssistantApp> {
  bool isDarkMode = false; // Koyu tema durumu

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kişisel Asistan',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(
        toggleTheme: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function toggleTheme;

  HomePage({required this.toggleTheme});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> reminders = [];

  final TextEditingController taskController = TextEditingController();
  final TextEditingController reminderController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String currentTime = '';
  String currentDate = '';
  String weatherInfo = "Şehir adını girin ve hava durumunu öğrenin.";

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    Timer.periodic(Duration(seconds: 1), (Timer t) {
      final now = DateTime.now();
      setState(() {
        currentDate = "${now.day}-${now.month}-${now.year}";
        currentTime = "${now.hour}:${now.minute}:${now.second}";
      });
    });
  }

  Future<void> fetchWeather(String city) async {
    final apiKey = "fe2e43a39b4bbb342ea86c77895486e8"; // Çalışan API anahtarı
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=${city.trim()}&appid=$apiKey&units=metric&lang=tr";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final description = data['weather'][0]['description'];
        final temp = data['main']['temp'];
        setState(() {
          weatherInfo = "$city: $temp°C, $description";
        });
      } else if (response.statusCode == 401) {
        setState(() {
          weatherInfo =
              "API anahtarınız geçersiz veya etkin değil. Lütfen geçerli bir API anahtarı kullanın.";
        });
      } else if (response.statusCode == 404) {
        setState(() {
          weatherInfo = "Şehir bulunamadı. Lütfen şehir adını kontrol edin.";
        });
      } else {
        setState(() {
          weatherInfo = "Bir hata oluştu. Hata kodu: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        weatherInfo =
            "Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.";
      });
    }
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          selectedDate = date;
          selectedTime = time;
        });
      }
    }
  }

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        selectedDate != null &&
        selectedTime != null) {
      setState(() {
        tasks.add({
          'text': taskController.text,
          'completed': false,
          'date':
              "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
          'time':
              "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}"
        });
        taskController.clear();
        selectedDate = null;
        selectedTime = null;
      });
    }
  }

  void _addReminder() {
    if (reminderController.text.isNotEmpty &&
        selectedDate != null &&
        selectedTime != null) {
      setState(() {
        reminders.add({
          'text': reminderController.text,
          'completed': false,
          'date':
              "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
          'time':
              "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}"
        });
        reminderController.clear();
        selectedDate = null;
        selectedTime = null;
      });
    }
  }

  void _toggleCompletion(List<Map<String, dynamic>> list, int index) {
    setState(() {
      list[index]['completed'] = !list[index]['completed'];
    });
  }

  void _deleteItem(List<Map<String, dynamic>> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  void _editItem(List<Map<String, dynamic>> list, int index) {
    noteController.text = list[index]['text'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notu Düzenle'),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(hintText: 'Notu düzenleyin'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                list[index]['text'] = noteController.text;
              });
              Navigator.of(context).pop();
            },
            child: Text('Kaydet'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
        leading: IconButton(
          icon: Icon(Icons.lightbulb_outline),
          onPressed: () => widget.toggleTheme(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Takvim ve Saat
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tarih: $currentDate',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Saat: $currentTime',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Hava Durumu Alanı
            Text(
              'Şehir Girin:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cityController,
                    decoration: InputDecoration(
                      hintText: 'Şehir Adı',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    final city = cityController.text.trim();
                    if (city.isNotEmpty) {
                      fetchWeather(city);
                    } else {
                      setState(() {
                        weatherInfo = "Lütfen bir şehir adı girin.";
                      });
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              weatherInfo,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Görev Ekleme Bölümü
            Text(
              'Yeni Görev Ekle:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      hintText: 'Görev girin',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: _pickDateTime,
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Hatırlatıcı Ekleme Bölümü
            Text(
              'Yeni Hatırlatıcı Ekle:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: reminderController,
                    decoration: InputDecoration(
                      hintText: 'Hatırlatıcı girin',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: _pickDateTime,
                ),
                IconButton(
                  icon: Icon(Icons.add_alarm),
                  onPressed: _addReminder,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Görevler Listesi
            Text(
              'Görevler:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(tasks[index]['completed']
                        ? Icons.check_circle
                        : Icons.circle_outlined),
                    title: Text(
                      "${tasks[index]['text']} (Tarih: ${tasks[index]['date']} Saat: ${tasks[index]['time']})",
                      style: TextStyle(
                        decoration: tasks[index]['completed']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    onTap: () => _toggleCompletion(tasks, index),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editItem(tasks, index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteItem(tasks, index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Hatırlatıcılar Listesi
            Text(
              'Hatırlatıcılar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(reminders[index]['completed']
                        ? Icons.alarm_on
                        : Icons.alarm),
                    title: Text(
                      "${reminders[index]['text']} (Tarih: ${reminders[index]['date']} Saat: ${reminders[index]['time']})",
                      style: TextStyle(
                        decoration: reminders[index]['completed']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    onTap: () => _toggleCompletion(reminders, index),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editItem(reminders, index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteItem(reminders, index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
