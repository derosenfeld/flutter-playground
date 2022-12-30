import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'x y plotter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DataApp(title: 'x y plotter'),
    );
  }
}

class DataApp extends StatefulWidget {
  const DataApp({super.key, required this.title});

  final String title;

  @override
  State<DataApp> createState() => _DataAppState();
}

class _DataAppState extends State<DataApp> {
  List<double> _x = [0.0, 1.0, 2.0]; // these will be initial values in table
  List<double> _y = [0.0, 1.0, 4.0];

  void printData() {
    for (var i = 0; i < _x.length; ++i) {
      print("x: ${_x[i]} , y: ${_y[i]}");
    }
  }

  void plutoCallback(List<double> val_x, List<double> val_y) {
    setState(() {
      _x = val_x;
      _y = val_y;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: <Widget>[]),
      body: Row(children: <Widget>[
        Expanded(
          child:
              PlutoGridBox(callback: plutoCallback, initialX: _x, initialY: _y),
        ),
        Expanded(child: LineChartWidget(_x, _y)),
      ]),
    );
  }
}

typedef void DataCallBack(List<double> val_x, List<double> val_y);

/// PlutoGrid Widget
//
/// For more examples, go to the demo web link on the github below.
class PlutoGridBox extends StatefulWidget {
  final DataCallBack callback;
  final List<double> initialX;
  final List<double> initialY;
  const PlutoGridBox(
      {required this.callback,
      required this.initialX,
      required this.initialY,
      Key? key})
      : super(key: key);
//  const PlutoGridBox({Key? key}) : super(key: key);

  @override
  State<PlutoGridBox> createState() => _PlutoGridBoxState();

  List<PlutoRow> buildRowsFromInitial() {
    List<PlutoRow> rows = [];
    for (var i = 0; i < initialX.length; ++i) {
      rows.add(PlutoRow(cells: {
        'x': PlutoCell(value: initialX[i]),
        'y': PlutoCell(value: initialY[i]),
      }));
    }
    return rows;
  }
}

class _PlutoGridBoxState extends State<PlutoGridBox> {
  final List<PlutoColumn> columns = <PlutoColumn>[
    PlutoColumn(
      title: 'x',
      field: 'x',
      type: PlutoColumnType.number(applyFormatOnInit: false),
    ),
    PlutoColumn(
      title: 'y',
      field: 'y',
      type: PlutoColumnType.number(applyFormatOnInit: false),
    ),
  ];

  late final PlutoGridStateManager stateManager;

  late List<double> _x;
  late List<double> _y;

  void addRowHandler() {
    stateManager.insertRows(
        stateManager.refRows.originalList.length + 1,
        <PlutoRow>[
          PlutoRow(cells: {
            'x': PlutoCell(value: double.nan),
            'y': PlutoCell(value: double.nan),
          })
        ],
        notify: true);
    storeGridToLists();
    widget.callback(_x, _y);
  }

  void deleteRowHandler() {
    stateManager.removeCurrentRow();
    storeGridToLists();
    widget.callback(_x, _y);
  }

  void storeGridToLists() {
    _x = <double>[];
    _y = <double>[];
    for (var i = 0; i < stateManager.refRows.originalList.length; ++i) {
      final PlutoRow tempRow = stateManager.refRows.originalList[i];
      _x.add(tempRow.cells['x']!.value);
      _y.add(tempRow.cells['y']!.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Row(children: [
          TextButton(onPressed: addRowHandler, child: Text("Add Row")),
          TextButton(
              onPressed: deleteRowHandler, child: Text("Remove Current Row")),
        ]),
        Expanded(
            child: PlutoGrid(
          columns: columns,
          rows: widget.buildRowsFromInitial(),
          onLoaded: (PlutoGridOnLoadedEvent event) {
            stateManager = event.stateManager;
            storeGridToLists();
            widget.callback(_x, _y);
          },
          onChanged: (PlutoGridOnChangedEvent event) {
            storeGridToLists();
            widget.callback(_x, _y);
          },
          configuration: const PlutoGridConfiguration(),
        )),
      ]),
    );
  }
}

// Chart Widget
class LineChartWidget extends StatefulWidget {
//  const LineChartWidget({Key? key}) : super(key: key);
  final List<double> x;
  final List<double> y;
  late List<FlSpot> data;

  LineChartWidget(this.x, this.y) : super() {
    data = <FlSpot>[];
    for (var i = 0; i < x.length; ++i) {
      if (!x[i].isNaN && !y[i].isNaN) {
        data.add(FlSpot(x[i], y[i]));
      }
    }
  }

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.17,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: widget.data,
              isCurved: false,
              // dotData: FlDotData(
              //   show: false,
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
