//import 'package:dio/dio.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;

class ApiService {
  final Dio _dio;

// BaseOptions options = BaseOptions(
// baseUrl: 'http://127.0.0.1:8000/api/de',
//// connectTimeout: 5000,
// //receiveTimeout: 3000,
// );

// final _baseUrl = 'https://192.168.2.104:8000/api/';
  ApiService(this._dio);
  Future<dynamic> get({
    required String url,
    @required String? token,
    @required dynamic body,
    @required Map<String, dynamic>? queryParameters,
  }) async {
    Map<String, String> headers = {'Accept': 'application/json'};
    if (token != null) {
      headers.addAll({'Authorization': 'Bearer $token'});
    }

    final Response response = await _dio.get(url,
        data: body,
        queryParameters: queryParameters,
        options: Options(
          headers: headers,
        ));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception(
          'there is a problem with status code ${response.statusCode}');
    }
  }

  Future<dynamic> delete(
      {required String url,
      @required dynamic body,
      @required String? token}) async {
    Map<String, String> headers = {'Accept': 'application/json'};
    if (token != null) {
      headers.addAll({'Authorization': 'Bearer $token'});
//i deleted Bearer before the token
    }

    final Response response = await _dio.delete(
      data: body,
      url,
      options: Options(
        headers: headers,
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      response.data;
    } else {
      throw Exception(
          'there is a problem with status code ${response.statusCode}');
    }
  }

  Future<dynamic> post({
    required String url,
    @required dynamic body,
    @required String? token,
  }) async {
    Map<String, String> headers = {'Accept': 'application/json'};

    if (token != null) {
      headers.addAll({'Authorization': 'Bearer $token'});
    }
    Response response = await _dio.post(
      url,
      options: Options(headers: headers),
      data: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      Map<String, dynamic> data = response.data;
      return data;
    } else {
      throw Exception(
          'there is a problem with status code ${response.statusCode} with body ${response.data}');
    }
  }

  Future<dynamic> put(
      {required String url,
      @required dynamic body,
      @required String? token}) async {
    Map<String, String> headers = {};
    headers.addAll(
        {'Content-Type': 'application/json', 'Accept': 'application/json'});
    if (token != null) {
      headers.addAll({'Authorization': 'Bearer $token'});
    }

    Response response = await _dio.put(
      url,
      data: body,
      options: Options(headers: headers),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> data = response.data;
      return data;
    } else {
      throw Exception(
          'there is a problem with status code ${response.statusCode} with body ${response.data}');
    }
  }

  Future<dynamic> download(
      {required String url,
      required String downloadPath,
      required CancelToken? cancelToken,
      required void Function(int count, int total)? onReceiveProgress,
//
      @required String? token}) async {
    Map<String, String> headers = {};
    headers.addAll(
        {'Content-Type': 'application/json', 'Accept': 'application/json'});
    if (token != null) {
      headers.addAll({'Authorization': 'Bearer $token'});
    }
//var dir = await getApplicationDocumentsDirectory();
    var dir = Directory(downloadPath);
    if (await dir.exists()) {
      return true;
    }
    Response response = await _dio.download(
      url,
      downloadPath,
      cancelToken: cancelToken,

//data: body,
      options: Options(headers: headers),
      onReceiveProgress: onReceiveProgress,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      return data;
    } else {
      throw Exception(
          'there is a problem with status code ${response.statusCode} with body ${response.data}');
    }
  }
}
