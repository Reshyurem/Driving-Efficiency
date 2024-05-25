import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driving Efficiency',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 97, 221, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Driving Efficiency Statistics'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _DrivingData {
  _DrivingData(this.cost, this.odometer, this.date);

  final double cost;
  final double odometer;
  final DateTime date;
}

class _ProcessedDrivingData {
  _ProcessedDrivingData(this.cost, this.odometer, this.date, this.costPerKm);

  final double cost;
  final double odometer;
  final DateTime date;
  final double costPerKm;
}

class DrivingDataForm extends StatefulWidget {
  const DrivingDataForm({super.key});

  @override
  State<DrivingDataForm> createState() => _DrivingDataFormState();
}

class _DrivingDataFormState extends State<DrivingDataForm> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _odometerController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _cost = 0;
  double _odometer = 0;

  final _db = Localstore.getInstance(useSupportDir: true);

  @override
  void dispose() {
    _costController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    /// The argument value will return the changed date as [DateTime] when the
    /// widget [SfDateRangeSelectionMode] set as single.
    ///
    /// The argument value will return the changed dates as [List<DateTime>]
    /// when the widget [SfDateRangeSelectionMode] set as multiple.
    ///
    /// The argument value will return the changed range as [PickerDateRange]
    /// when the widget [SfDateRangeSelectionMode] set as range.
    ///
    /// The argument value will return the changed ranges as
    /// [List<PickerDateRange] when the widget [SfDateRangeSelectionMode] set as
    /// multi range.
    setState(() {
      _selectedDate = args.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add Driving Data'),
        ),
        body: ListView(children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(labelText: 'Cost'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a cost';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Odometer'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an odometer reading';
                    }
                    return null;
                  },
                ),
                SfDateRangePicker(
                  onSelectionChanged: _onSelectionChanged,
                  selectionMode: DateRangePickerSelectionMode.single,
                  initialSelectedDate: DateTime.now(),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process data
                      _cost = double.parse(_costController.text);
                      _odometer = double.parse(_odometerController.text);
                      _db.collection('drivingData').doc().set({
                        'cost': _cost,
                        'odometer': _odometer,
                        'date': _selectedDate.toString(),
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ]));
  }
}

class _MyHomePageState extends State<MyHomePage> {
  // List<_DrivingData> drivingData = [
  //   // _DrivingData(104, 100, DateTime(2024, 1, 1)),
  //   _DrivingData(105, 200, DateTime(2024, 2, 1)),
  //   _DrivingData(106, 300, DateTime(2024, 3, 1)),
  //   _DrivingData(104, 400, DateTime(2024, 4, 1)),
  //   _DrivingData(105, 500, DateTime(2024, 5, 1)),
  //   _DrivingData(106, 600, DateTime(2024, 6, 1)),
  //   _DrivingData(104, 700, DateTime(2024, 7, 1)),
  //   _DrivingData(105, 800, DateTime(2024, 8, 1)),
  //   _DrivingData(106, 900, DateTime(2024, 9, 1)),
  //   _DrivingData(104, 1000, DateTime(2024, 10, 1)),
  //   _DrivingData(105, 1100, DateTime(2024, 11, 1)),
  //   _DrivingData(106, 1200, DateTime(2024, 12, 1)),
  // ];
  List<_DrivingData> drivingData = [];

  List<_ProcessedDrivingData> processedDrivingData = [];

  void retrieveDrivingData() {
    final _db = Localstore.getInstance(useSupportDir: true);
    _db.collection('drivingData').get().then((event) {
      drivingData.clear();

      for (var doc in event!.keys) {
        drivingData.add(_DrivingData(event[doc]['cost'] as double,
            event[doc]['odometer'] as double, DateTime.parse(event[doc]['date'] as String)));
      }
      setState(() {});
    });
  }

  void _processDrivingData() {
    retrieveDrivingData();
    processedDrivingData.clear();
    // sort driving data by date
    drivingData.sort((a, b) => a.date.compareTo(b.date));
    for (var i = 0; i < drivingData.length - 1; i++) {
      var km = drivingData[i + 1].odometer - drivingData[i].odometer;
      var cost = drivingData[i].cost;
      var costPerKm = km / cost;
      processedDrivingData
          .add(_ProcessedDrivingData(cost, km, drivingData[i].date, costPerKm));
    }
  }

  void _switchToForm() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const DrivingDataForm())).whenComplete(_processDrivingData);
  }

  @override
  Widget build(BuildContext context) {
    // _processDrivingData();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                // Chart title
                title: ChartTitle(text: 'Cost Analysis of a Car'),
                // Enable legend
                legend: Legend(isVisible: true),
                // Enable tooltip
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<_ProcessedDrivingData, String>>[
                  LineSeries<_ProcessedDrivingData, String>(
                      dataSource: processedDrivingData
                          .skip(processedDrivingData.length - 5 > 0
                              ? processedDrivingData.length - 5
                              : 0)
                          .toList(),
                      // xValueMapper: (_SalesData sales, _) => sales.year,
                      // yValueMapper: (_SalesData sales, _) => sales.sales,
                      xValueMapper: (_ProcessedDrivingData p, _) =>
                          (p.date.day.toString() +
                              '/' +
                              p.date.month.toString()),
                      yValueMapper: (_ProcessedDrivingData p, _) => p.costPerKm,
                      name: 'Cost Efficiency',
                      // Enable data label
                      dataLabelSettings: DataLabelSettings(isVisible: true)),
                ]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _switchToForm,
        tooltip: 'Add Driving Data',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
