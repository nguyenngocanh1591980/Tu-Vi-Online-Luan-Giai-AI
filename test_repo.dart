import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var response = await http.get(Uri.parse('http://localhost:8000/api/users/Admin/profile-stats'));
  print(response.body);
  
  response = await http.get(Uri.parse('http://localhost:8000/api/users'));
  print(response.body);
}
