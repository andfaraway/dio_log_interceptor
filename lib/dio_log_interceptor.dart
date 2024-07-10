import 'package:dio/dio.dart';
import 'package:flutter_log_utils/flutter_log_utils.dart';

class DioLogInterceptor extends Interceptor {
  final Map<String, dynamic> apisMap;
  final Iterable<String> hideKeys;
  final bool showRequestHeader;
  final bool responseExpand;

  Map<String, dynamic> _transFormMap = {};

  Map<String, dynamic> get transFormMap {
    if (_transFormMap.isEmpty) {
      _transFormMap = dealWithMap(apisMap);
    }
    return _transFormMap;
  }

  DioLogInterceptor({
    this.apisMap = const {},
    this.hideKeys = const [],
    this.showRequestHeader = false,
    this.responseExpand = false,
  }) : super();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    dynamic data;
    if (options.data is Map) {
      options.extra['tag'] = DateTime.now().millisecondsSinceEpoch;
      data = Map.from(options.data).cast<String, dynamic>();
      for (var key in hideKeys) {
        (data as Map).remove(key);
      }
      data = dealWithData(data);
    }

    String path = transFormMap[options.path] == null ? '' : '${transFormMap[options.path]} => ';

    Log.line(tag: 'start');
    Log.n(
      '${options.baseUrl}${options.path}',
      tag: '${path}request - ${options.method} - ${options.extra['tag']}',
    );
    if (showRequestHeader) {
      Log.n(options.headers, tag: 'header');
    }
    if (options.queryParameters.isNotEmpty) {
      Log.n(options.queryParameters, tag: 'queryParameters');
    }
    if (options.queryParameters.isNotEmpty) {
      Log.n(data, tag: 'data');
    }
    Log.line(tag: 'end', spaceLine: 1);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    dynamic data;
    if (response.requestOptions.data is Map) {
      data = Map.from(response.requestOptions.data).cast<String, dynamic>();
      for (var key in hideKeys) {
        (data as Map).remove(key);
      }
      data = dealWithData(data);
    }

    dynamic responseData;
    if (response.data is Map) {
      responseData = Map.from(response.data).cast<String, dynamic>();
      dynamic temp = responseData['data'];
      if (temp != null) {
        if (temp is Map) {
          responseData['data'] = dealWithData(temp.cast<String, dynamic>());
        } else if (temp is String) {
          if (temp.length > 200) {
            temp = '${temp.substring(0, 50)}...long data';
          }
          responseData['data'] = temp;
        }
      }
    }

    String path =
    transFormMap[response.requestOptions.path] == null ? '' : '${transFormMap[response.requestOptions.path]} => ';

    Log.line(tag: 'start');
    Log.n(
      responseData,
      tag: '${path}response - ${response.requestOptions.extra['tag']}',
      expand: responseExpand,
    );
    Log.line(tag: 'end', spaceLine: 1);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.n('${err.requestOptions.path}=>${err.type}', tag: 'error ❌');
    super.onError(err, handler);
  }

  Map<String, dynamic> dealWithData(Map<String, dynamic> data) {
    if (transFormMap.isEmpty) return data;

    Map<String, dynamic> temp = {};
    for (final item in data.entries) {
      if (item.value is String) {
        String value = item.value;
        if (value.length > 200) {
          value = '${item.value.substring(0, 50)}...long data';
        }
        temp['${transFormMap[item.key]}-${item.key}'] = value;
        continue;
      }
      if (item.value is Map) {
        temp['${item.key}-${transFormMap[item.key]}'] = dealWithData(item.value);
      }
      if (item.value is List){
        List l = [];
        for(Map map in item.value){
          l.add(dealWithData(map.cast<String, dynamic>()));
        }
        temp['${item.key}-${transFormMap[item.key]}'] = l;
      }
    }
    return temp;
  }

  Map<String, dynamic> dealWithMap(Map<String, dynamic> map, [String superKey = '']) {
    Map<String, dynamic> temp = {};
    for (final item in map.entries) {
      if (item.value is String) {
        if (item.key == 'path' || item.key == 'value') {
          temp[item.value] = superKey;
        } else {
          temp[item.value] = item.key;
        }
        continue;
      }
      if (item.value is Map) {
        temp.addAll(dealWithMap(item.value.cast<String, dynamic>(), item.key));
      }
    }
    return temp;
  }
}
