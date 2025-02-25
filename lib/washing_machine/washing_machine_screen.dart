import 'package:flutter/material.dart';
import 'package:smart_washing_machine_app/washing_machine/task_sequence_widget.dart';
import 'settings/settings_screen.dart';
import 'scanner/scanner_screen.dart';
import 'dart:async';

import 'package:lan_scanner/lan_scanner.dart';
import 'package:http/http.dart' as http;

import 'package:percent_indicator/circular_percent_indicator.dart';

import 'labels.dart';

import 'washing_machine.dart';

import 'dart:io';

class WashingMachineScreen extends StatefulWidget {
  const WashingMachineScreen({super.key});
  @override
  State<WashingMachineScreen> createState() => WashingMachineScreenState();
}

class WashingMachineScreenState extends State<WashingMachineScreen> {
  Timer? timer;

  WashingMachineScreenState() {
    setupRefreshCurrentStatusTimer();
  }

  void setupRefreshCurrentStatusTimer() {
    WashingMachine.instance.getTaskSequence();
    Duration period = const Duration(seconds: 1);
    timer = Timer.periodic(period, (arg) {
      WashingMachine.instance.refreshCurrentStatus();
      setState(() {});
    });
  }

  void cancelRefreshCurrentStatusTimer() {
    timer?.cancel();
  }

  void getOctetHostname() async {
    debugPrint('Getting Octet Hostname');
    String subnet = ipToCSubnet(await getLocalIp() ?? '192.168.18.101');
    print('subnet $subnet');
    String octet = WashingMachine.instance.octet;
    String ipaddress = '$subnet.$octet';
    print('octetip $ipaddress');

    bool isWashingMachine = await checkIPisWashingMachine(ipaddress);

    print("is washing machine $isWashingMachine $ipaddress");

    if (isWashingMachine) {
      print("Setting Octet Hostname $ipaddress");
      WashingMachine.instance.hostname = ipaddress;
    } else {
      print("No Octet Hostname machine $ipaddress");
    }
  }

  Future<void> forceOctetHostname() async {
    debugPrint('Getting Octet Hostname');
    String subnet = ipToCSubnet(await getLocalIp() ?? '192.168.18.101');
    print('subnet $subnet');
    String octet = WashingMachine.instance.octet;
    String ipaddress = '$subnet.$octet';
    print('octetip $ipaddress');

    print("Force Octet Hostname $ipaddress");
    WashingMachine.instance.hostname = ipaddress;
  }

  void initSettingsInOrder() async {
    await WashingMachine.instance.loadSettings();
    await forceOctetHostname();
  }

  @override
  void initState() {
    super.initState();

    debugPrint('WashingMachineScreen');
    initSettingsInOrder();
  }

  void openScannerScreen() async {
    WashingMachine.instance.pauseMachine();
    cancelRefreshCurrentStatusTimer();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    if (result != null) {
      debugPrint("Returned Hostname: $result");
    }
    await WashingMachine.instance.loadSettings();
    setupRefreshCurrentStatusTimer();
  }

  void openSettingsScreen() async {
    WashingMachine.instance.pauseMachine();
    cancelRefreshCurrentStatusTimer();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (result != null) {
      debugPrint("Returned Hostname: $result");
    }
    await WashingMachine.instance.loadSettings();
    setupRefreshCurrentStatusTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 18, left: 24, right: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HI MOM',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: "openScanner",
                    onPressed: openScannerScreen,
                    tooltip: 'Open Scanner Screen',
                    child: const Icon(Icons.wifi),
                  ),
                  FloatingActionButton(
                    heroTag: "openSettings",
                    onPressed: openSettingsScreen,
                    tooltip: 'Open Settings Screen',
                    child: const Icon(Icons.settings),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  WashingMachine.instance.message,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 16),
                    CircularPercentIndicator(
                      radius: 150,
                      lineWidth: 24,
                      percent: 1,
                      progressColor: Colors.indigo,
                      center: Text(
                        WashingMachine.instance.centerLabel,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: "runMachine",
                          onPressed: WashingMachine.instance.runMachine,
                          tooltip: 'Run',
                          child: const Icon(Icons.play_arrow),
                        ),
                        FloatingActionButton(
                          heroTag: "pauseMachine",
                          onPressed: WashingMachine.instance.pauseMachine,
                          tooltip: 'Pause',
                          child: const Icon(Icons.stop),
                        ),
                        FloatingActionButton(
                          heroTag: "holdMachine",
                          onPressed: WashingMachine.instance.holdMachine,
                          tooltip: 'Hold',
                          child: const Icon(Icons.pause),
                        ),
                        FloatingActionButton(
                          heroTag: "skipMachine",
                          onPressed: WashingMachine.instance.skipMachine,
                          tooltip: 'Skip',
                          child: const Icon(Icons.skip_next),
                        ),
                        FloatingActionButton(
                          heroTag: "resetMachine",
                          onPressed: () {
                            WashingMachine.instance.refreshCurrentStatus();
                            WashingMachine.instance.getTaskSequence();
                            WashingMachine.instance.resetMachine;
                          },
                          tooltip: 'Reset',
                          child: const Icon(Icons.reset_tv),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        imageIconButtons(
                          onPressed: () => {
                            WashingMachine.instance.setNextTask(
                                task: 1,
                                countdown: int.parse(WashingMachine
                                    .instance.fillingTaskCountdown))
                          },
                          text: "Fill",
                          task: 1,
                        ),
                        imageIconButtons(
                          onPressed: () => {
                            WashingMachine.instance.setNextTask(
                                task: 2,
                                countdown: int.parse(WashingMachine
                                    .instance.washingTaskCountdown))
                          },
                          text: "Wash",
                          task: 2,
                        ),
                        imageIconButtons(
                          onPressed: () => {
                            WashingMachine.instance.setNextTask(
                                task: 3,
                                countdown: int.parse(WashingMachine
                                    .instance.soakingTaskCountdown))
                          },
                          text: "Soak",
                          task: 3,
                        ),
                        imageIconButtons(
                          onPressed: () => {
                            WashingMachine.instance.setNextTask(
                                task: 4,
                                countdown: int.parse(WashingMachine
                                    .instance.drainingTaskCountdown))
                          },
                          text: "Drain",
                          task: 4,
                        ),
                        imageIconButtons(
                          onPressed: () => {
                            WashingMachine.instance.setNextTask(
                                task: 5,
                                countdown: int.parse(WashingMachine
                                    .instance.dryingTaskCountdown))
                          },
                          text: "Dry",
                          task: 5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    taskSequenceView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget imageIconButtons({
  required String text,
  required int task,
  VoidCallback? onPressed,
}) {
  return FloatingActionButton(
    heroTag: "hero$text",
    onPressed: onPressed,
    tooltip: text,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        washingMachineTasksIcons[task],
        Text(text), // <-- Text
      ],
    ),
  );
}
