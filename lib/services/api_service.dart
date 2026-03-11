import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:limo_guy/views/login/login_response';
import '../models/driver_profile_model.dart';
import '../models/trip_model.dart';

class ApiService {
  // Update this with your actual API base URL
  static const String baseUrl = 'https://dash.mayfairlimo.ca/api';
  
  /// Login endpoint
  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/driver/login');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LoginResponse.fromJson(jsonData);
      } else {
        // Handle error responses
        final jsonData = json.decode(response.body);
        throw ApiException(
          message: jsonData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Logout endpoint
  Future<bool> logout({required String token}) async {
    try {
      final url = Uri.parse('$baseUrl/driver/logout');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      } else if (response.statusCode == 401) {
        // Unauthorized - token is invalid or expired
        throw ApiException(
          message: 'Invalid token',
          statusCode: response.statusCode,
        );
      } else {
        // Handle other error responses
        final jsonData = json.decode(response.body);
        throw ApiException(
          message: jsonData['message'] ?? 'Logout failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get driver profile endpoint
  Future<DriverProfile> getProfile({required String token}) async {
    try {
      final url = Uri.parse('$baseUrl/driver/profile');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DriverProfile.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        // Unauthorized - token is invalid or expired
        throw ApiException(
          message: 'Invalid token',
          statusCode: response.statusCode,
        );
      } else {
        // Handle other error responses
        final jsonData = json.decode(response.body);
        throw ApiException(
          message: jsonData['message'] ?? 'Failed to fetch profile',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get driver trips endpoint
  Future<TripsResponse> getTrips({required String token}) async {
    try {
      final url = Uri.parse('$baseUrl/driver/trips');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TripsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        // Unauthorized - token is invalid or expired
        throw ApiException(
          message: 'Invalid token',
          statusCode: response.statusCode,
        );
      } else {
        // Handle other error responses
        final jsonData = json.decode(response.body);
        throw ApiException(
          message: jsonData['message'] ?? 'Failed to fetch trips',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Update driver location endpoint
  /// Sends latitude, longitude, and optional trip_id (empty when no active trip)
  Future<bool> updateDriverLocation({
    required String token,
    required double latitude,
    required double longitude,
    int? tripId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/driver/location');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'trip_id': tripId?.toString() ?? '',
        },
      );

      if (response.statusCode == 200) {
        print('Location update successful: ($latitude, $longitude) with trip_id: ${tripId ?? 'none'}');
        final jsonData = json.decode(response.body);
        return jsonData['success'] ?? false;
      } else if (response.statusCode == 401) {
        throw ApiException(
          message: 'Invalid token',
          statusCode: response.statusCode,
        );
      } else {
        final jsonData = json.decode(response.body);
        throw ApiException(
          message: jsonData['message'] ?? 'Failed to update location',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Update trip status endpoint
  /// Sends trip status updates to the backend
  /// Status values: on_the_way, arrived, picked_up, completed
  Future<bool> updateTripStatus({
    required String token,
    required int tripId,
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/driver/status');

      final body = <String, String>{
        'trip_id': tripId.toString(),
        'status': status,
      };
      if (latitude != null) body['latitude'] = latitude.toString();
      if (longitude != null) body['longitude'] = longitude.toString();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Trip status update successful: trip_id: $tripId, status: $status, location: (${latitude ?? 'N/A'}, ${longitude ?? 'N/A'})');
        return jsonData['success'] ?? false;
      } else if (response.statusCode == 401) {
        // Unauthorized - token is invalid or expired
        throw ApiException(
          message: 'Invalid token',
          statusCode: response.statusCode,
        );
      } else {
        // Handle other error responses
        final jsonData = json.decode(response.body);
        throw ApiException(
          message: jsonData['message'] ?? 'Failed to update trip status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => message;
}



