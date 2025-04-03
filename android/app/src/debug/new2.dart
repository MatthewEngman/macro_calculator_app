import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/calculator_provider.dart';
import '../widgets/input_field.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load the goal from persistence when the screen initializes
    // Use future.microtask or addPostFrameCallback to ensure ref is available
    Future.microtask(() => ref.read(calculatorProvider.notifier).loadGoal());
  }

  @override
  Widget build(BuildContext context) {
    final calculatorNotifier = ref.watch(calculatorProvider.notifier);

    return Scaffold(
        appBar: AppBar(
            title: const Text('Macro Calculator'), centerTitle: true),
        body: Padding(
        padding: const EdgeInsets.all(20.0),
    child: Form(
    key: _formKey,
    child: SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
    // Weight Input
    InputField(
    label: 'Weight (lbs):',
    hint: 'Enter your weight in pounds',
    keyboardType: TextInputType.number,
    onChanged: (value) {
    // Directly update the mutable field in the notifier
    calculatorNotifier.weight = double.tryParse(value) ?? 0.0;
    },
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your weight';
    }
    if (double.tryParse(value) == null) {
    return 'Please enter a valid number';
    }
    if (double.parse(value) <= 0) {
    return 'Weight must be greater than 0';
    }
    if (double.parse(value) > 500) {
    return 'Weight must be less than 500';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),
    // Height Input
    const Text('Height:', style: TextStyle(fontSize: 16)),
    Row(
    children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Feet',
    style: TextStyle(fontSize: 14),
    ),
    TextFormField(
    keyboardType: TextInputType.number,
    onChanged: (value) {
    calculatorNotifier.feet = int.tryParse(value) ?? 0;
    },
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Enter feet';
    }
    if (int.tryParse(value) == null) {
    return 'Invalid number';
    }
    return null;
    },
    decoration: const InputDecoration(
    hintText: 'e.g., 5',
    ),
    ),
    ],
    ),
    ),
    const SizedBox(width: 10),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Inches',
    style: TextStyle(fontSize: 14),
    ),
    TextFormField(
    keyboardType: TextInputType.number,
    onChanged: (value) {
    calculatorNotifier.inches = int.tryParse(value) ?? 0;
    },
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Enter inches';
    }
    if (int.tryParse(value) == null) {
    return 'Invalid number';
    }
    return null;
    },
    decoration: const InputDecoration(
    hintText: 'e.g., 10',
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    const SizedBox(height: 20),
    // Age Input
    InputField(
    label: 'Age (years):',
    hint: 'Enter your age in years',
    keyboardType: TextInputType.number,
    onChanged: (value) {
    calculatorNotifier.age = int.tryParse(value) ?? 0;
    },
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your age';
    }
    if (int.tryParse(value) == null) {
    return 'Please enter a valid number';
    }
    if (int.parse(value) <= 0) {
    return 'Age must be greater than 0';
    }
    if (int.parse(value) > 150) {
    return 'Age must be less than 150';
    }
    return null;
    },
    ),
    const SizedBox(height: 20),
    // Sex Input (Dropdown)
    const Text('Sex:', style: TextStyle(fontSize: 16)),
    DropdownButtonFormField<String>(
    value: calculatorNotifier.sex, // Read current value
    onChanged: (value) {
    if (value != null) {
    // Update the mutable field
    calculatorNotifier.sex = value;
    // Manually trigger rebuild to reflect changes
    setState(() {});
    }
    },
    items: ['male', 'female']
        .map<DropdownMenuItem<String>>((String value) {
    return DropdownMenuItem<String>(
    value: value,
    child: Text(value),
    );
    }).toList(),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please select your sex';
    }
    return null;
    },
    decoration: const InputDecoration(
    hintText: 'Select your sex'
    ,
    )
    ,
    )
    ,
                