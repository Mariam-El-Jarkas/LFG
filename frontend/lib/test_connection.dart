import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(ConnectionTestApp());

class ConnectionTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('API Connection Test')),
        body: ConnectionTestPage(),
      ),
    );
  }
}

class ConnectionTestPage extends StatefulWidget {
  @override
  _ConnectionTestPageState createState() => _ConnectionTestPageState();
}

class _ConnectionTestPageState extends State<ConnectionTestPage> {
  String _result = 'Click Test Button';
  bool _testing = false;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _result = 'Testing...';
    });

    try {
   final url = Uri.parse('http://localhost/fuck/api/');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = '✅ SUCCESS!\nAPI: ${data['api_name']}\nVersion: ${data['version']}\nStatus: ${data['status']}';
        });
      } else {
        setState(() {
          _result = '❌ Failed with status: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ ERROR: $e\n\nMake sure:\n1. XAMPP is running\n2. Server: http://10.0.2.2/fuck/api/\n3. Emulator has internet permission';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _testing ? null : _testConnection,
            child: _testing 
                ? CircularProgressIndicator()
                : Text('Test API Connection'),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _result,
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Testing URL: http://10.0.2.2/fuck/api/',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}