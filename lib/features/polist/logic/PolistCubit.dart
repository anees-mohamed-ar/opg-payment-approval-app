import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/config.dart';
import '../../../core/models/po_model/po_model.dart';

class PolistCubit extends Cubit<List<POModel>> {
  PolistCubit() : super([]);

  // Store the original list to apply filter on
  List<POModel> _allPOList = [];

  // Fetch data from API
  Future<void> fetchPOList() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/product/search/po_generate'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        print(data); // Print the API response to verify the keys
        _allPOList = data.map((item) => POModel.fromJson(item)).toList();
        emit(_allPOList); // Emit the complete POList
      } else {
        throw Exception('Failed to load PO list');
      }
    } catch (error) {
      emit([]); // Emit an empty list or handle error state
      throw Exception('Error fetching data: $error');
    }
  }

  // Filter PO List based on search query for poNumber
  void filterPOList(String query) {
    if (query.isEmpty) {
      emit(_allPOList); // Show all items if search query is empty
    } else {
      final filteredList = _allPOList
          .where(
              (po) => po.poNumber.toLowerCase().contains(query.toLowerCase()))
          .toList();
      emit(filteredList); // Emit filtered POList
    }
  }
}
