import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fconsole/fconsole.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_log_utils/flutter_log_utils.dart';

class DioLogInterceptor extends Interceptor {
  final Map<String, dynamic> apisMap;
  final Iterable<String> hideKeys;
  final bool showRequestHeader;
  final bool responseExpand;
  final bool showLogWidget;

  Map<String, dynamic> _transFormMap = {};

  Map<String, dynamic> get transFormMap {
    if (_transFormMap.isEmpty) {
      _transFormMap = dealWithMap(apisMap);
    }
    return _transFormMap;
  }

  final Map<String, dynamic> _hideMap = {};

  DioLogInterceptor({
    this.apisMap = const {},
    this.hideKeys = const [],
    this.showRequestHeader = false,
    this.responseExpand = false,
    this.showLogWidget = true,
  }) : super();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (showLogWidget == false && kDebugMode == false) {
      handler.next(options);
      return;
    }

    Map<String, dynamic> data = {};
    if (options.data is Map) {
      options.extra['tag'] = DateTime.now().millisecondsSinceEpoch;
      data = Map.from(options.data).cast<String, dynamic>();
      for (var key in hideKeys) {
        _hideMap[transFormMap[key]] = data[key];
        data.remove(key);
      }
      data = dealWithData(data);
    }

    String path = getTransformPath(options);

    if (showLogWidget) {
      final logger = getLogFlow(options: options, path: path);
      logger.log('开始请求:\n${options.headers}');

      if(options.data is FormData){
        FormData formData = options.data;
        logger.log(formData.fields);
      }else{
        logger.log(data);
      }
    }

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
    if (data.isNotEmpty) {
      Log.n(data, tag: 'data');
    }
    Log.line(tag: 'end', spaceLine: 1);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (showLogWidget == false && kDebugMode == false) {
      handler.next(response);
      return;
    }

    dynamic responseData;

    if (response.data is String || response.data is Map) {
      if (response.data is String) {
        try {
          response.data = json.decode(response.data);
        } catch (_) {}
      }

      responseData = Map.from(response.data).cast<String, dynamic>();

      dynamic temp = responseData['data'];
      if (temp != null) {
        if (temp is Map) {
          responseData['data'] = dealWithData(temp.cast<String, dynamic>());
        } else if (temp is String) {
          if (temp.length > 200) {
            temp = '${temp.substring(0, 200)}...(long data)';
          }
          responseData['data'] = temp;
        }else if (temp is List) {
          List<Map<String,dynamic>> l = [];
          for(Map<String,dynamic> dic in temp){
            l.add(dealWithData(dic));
          }
          responseData['data'] = l;
        }
      }
    }

    String path = getTransformPath(response.requestOptions);

    if (showLogWidget) {
      final logger = getLogFlow(options: response.requestOptions, path: path);
      logger.log('请求结束: ${response.statusCode}');
      logger.log(responseData);

      logger.log('全局参数');
      logger.log(_hideMap);
      logger.end();
    }

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
    String path = getTransformPath(err.requestOptions);

    if (showLogWidget) {
      final logger = getLogFlow(options: err.requestOptions, path: path);
      logger.error('请求错误');
      logger.error('$err');
      logger.end();
    }

    Log.n('$path${err.requestOptions.path}=>${err.type}', tag: 'error ❌');
    super.onError(err, handler);
  }

  String getTransformPath(RequestOptions options) {
    String path = transFormMap[options.path] == null ? '' : '${transFormMap[options.path]} => ';
    return path;
  }

  Map<String, dynamic> dealWithData(Map<String, dynamic> data) {
    if (transFormMap.isEmpty) return data;

    Map<String, dynamic> temp = {};
    for (final item in data.entries) {
      if (item.value is Map) {
        temp['${transFormMap[item.key]}-${item.key}'] = dealWithData(item.value);
      } else if (item.value is List) {
        List l = [];
        for (Map map in item.value) {
          l.add(dealWithData(map.cast<String, dynamic>()));
        }
        temp['${transFormMap[item.key]}-${item.key}'] = l;
      } else {
        dynamic value = item.value;
        if(item.value is String){
          if (item.value.length > 200) {
            value = '${item.value.substring(0, 200)}...(long data)';
          }
        }
        temp['${transFormMap[item.key]}-${item.key}'] = value;
        continue;
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

  FlowLog getLogFlow({
    required RequestOptions options,
    required String path,
  }) {
    var logger = FlowLog.ofNameAndId(
      '$path[${options.method}]\n${options.path}',
      id: '${options.hashCode}',
    );
    return logger;
  }
}
