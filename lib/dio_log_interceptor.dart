import 'package:dio/dio.dart';
import 'package:flutter_log_utils/flutter_log_utils.dart';

class DioLogInterceptor extends Interceptor {
  final Map<String, dynamic> apisMap;

  DioLogInterceptor({this.apisMap = const {}}):super();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    Log.d(options.headers,tag: 'headers');
    String path = '';
    apisMap.forEach((key, value) {
      if (value is Map) {
        if (value['path'] == options.path) {
          path = key;
        }
      }
    });
    Log.line('=', tag: 'start');
    Log.n('${options.baseUrl}${options.path}${path.isEmpty ? '' : ' <= $path'}', tag: 'request - ${options.method}');
    Log.n(options.queryParameters, tag: 'queryParameters');
    Log.n(options.data, tag: 'data');
    Log.line('=', tag: 'end', spaceLine: 1);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    Log.line('=', tag: 'start');
    Log.n(response.data, tag: 'response - ${response.requestOptions.path}}', level: 0);
    Log.line('=', tag: 'end', spaceLine: 1);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Log.n('${err.requestOptions.path}=>${err.type}', tag: 'error ❌');
    super.onError(err, handler);
  }
}
