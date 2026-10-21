import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/config_new.dart';
import '../../../core/models/payment_model/Voucher2.dart';

final paymentVoucherProvider = FutureProvider<List<Voucher>>((ref) async {
  try {
    final url = Uri.parse('${Config_new.baseUrl}/opg/vouchers/get-payment');
    debugPrint('Fetching vouchers from: $url');

    final response = await http.get(url).timeout(const Duration(seconds: 30));

    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
            'Expected JSON object but got ${decoded.runtimeType}');
      }

      final data = decoded['data'] as List?;
      if (data == null) {
        throw FormatException('Missing or invalid "data" field in response');
      }

      return data.map((item) {
        try {
          return Voucher.fromJson(item as Map<String, dynamic>);
        } catch (e, stack) {
          debugPrint('Error parsing voucher item: $e');
          debugPrint('Stack trace: $stack');
          debugPrint('Problematic item: $item');
          throw FormatException('Failed to parse voucher item: $e');
        }
      }).toList();
    } else {
      throw http.ClientException(
        'Request failed with status ${response.statusCode}',
        url,
      );
    }
  } on TimeoutException {
    throw Exception('Request timed out');
  } on http.ClientException catch (e) {
    debugPrint('Network error: ${e.message}');
    throw Exception('Network error: ${e.message}');
  } on FormatException catch (e) {
    debugPrint('Data parsing error: ${e.message}');
    throw Exception('Data format error: ${e.message}');
  } catch (e, stack) {
    debugPrint('Unexpected error: $e');
    debugPrint('Stack trace: $stack');
    throw Exception('An unexpected error occurred');
  }
});
