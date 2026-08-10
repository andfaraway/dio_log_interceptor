# dio_log_interceptor

`dio_log_interceptor` 是一个用于 Flutter/Dio 的请求日志拦截器。它会记录请求、响应和异常信息到控制台；也可以接入内置的悬浮调试面板，以流程形式查看每一次网络请求。

## 安装

在项目的 `pubspec.yaml` 中添加依赖：

```sh
flutter pub add dio_log_interceptor
```

然后获取依赖：

```sh
flutter pub get
```

## 基础使用

创建 `Dio` 后添加拦截器：

```dart
import 'package:dio/dio.dart';
import 'package:dio_log_interceptor/dio_log_interceptor.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
));

dio.interceptors.add(DioLogInterceptor());
```

发送请求后，拦截器会输出以下内容：

- 请求地址、方法和请求体
- 请求头（需开启 `showRequestHeader`）和查询参数
- 响应数据及 HTTP 状态码
- 请求异常及原始请求信息

## 启用悬浮调试面板

默认 `showLogWidget` 为 `true`。将应用入口替换为 `DioLogInterceptor.runAppWithConsole` 后，可通过悬浮窗查看请求流程、请求/响应内容和异常信息。

```dart
import 'package:flutter/material.dart';
import 'package:dio_log_interceptor/dio_log_interceptor.dart';

void main() {
  DioLogInterceptor.runAppWithConsole(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Demo')),
      ),
    );
  }
}
```

如果只需要终端日志，不需要悬浮调试面板：

```dart
dio.interceptors.add(DioLogInterceptor(showLogWidget: false));
```

> `showLogWidget: false` 时，拦截器只会在 Debug 模式下输出日志；Release 模式会直接跳过日志处理。

## 配置字段

```dart
DioLogInterceptor(
  apisMap: const {},
  hideKeys: const ['password', 'token'],
  showRequestHeader: true,
  responseExpand: false,
  showLogWidget: true,
  singleMap: const {},
);
```

| 字段 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `apisMap` | `Map<String, dynamic>` | `{}` | 接口路径和数据字段的映射配置。用于将日志中的路径、字段名展示为更易读的名称。 |
| `hideKeys` | `Iterable<String>` | `[]` | 请求体中不输出到常规日志的字段名，例如密码、令牌等敏感字段。仅对 `Map` 类型的请求体生效。 |
| `showRequestHeader` | `bool` | `false` | 是否输出请求头到常规日志。 |
| `responseExpand` | `bool` | `false` | 是否以展开形式输出响应数据到常规日志。 |
| `showLogWidget` | `bool` | `true` | 是否记录到内置悬浮调试面板。设为 `false` 后，Release 模式不记录任何日志。 |
| `singleMap` | `Map<String, dynamic>?` | `null` | 直接指定扁平字段映射；设置后优先于 `apisMap`。 |

## 字段映射

### 使用 `singleMap`

`singleMap` 适合直接维护「原字段名 → 展示名称」的映射。映射后的日志键会显示为 `展示名称-原字段名`。

```dart
dio.interceptors.add(DioLogInterceptor(
  singleMap: const {
    '/user/profile': '获取用户信息',
    'name': '姓名',
    'mobile': '手机号',
  },
));
```

例如请求体：

```dart
{
  'name': 'Alice',
  'mobile': '13800000000',
}
```

日志中会显示为：

```dart
{
  '姓名-name': 'Alice',
  '手机号-mobile': '13800000000',
}
```

路径也会使用同一映射，显示为 `获取用户信息 =>`。

### 使用 `apisMap`

`apisMap` 用于复用接口定义中的嵌套配置。拦截器会递归读取其中的字符串值：

- 键为 `path` 或 `value` 时，字符串值会映射到其父级键；
- 其他键值对会按「字符串值 → 当前键」映射。

示例：

```dart
final apisMap = {
  '获取用户信息': {
    'path': '/user/profile',
    '姓名': 'name',
    '手机号': 'mobile',
  },
};

dio.interceptors.add(DioLogInterceptor(apisMap: apisMap));
```

上例会把 `/user/profile` 标记为「获取用户信息」，并将 `name`、`mobile` 分别标记为「姓名」「手机号」。

## 日志处理规则

- 仅会转换 `Map` 类型的请求数据；`FormData` 会记录其 `fields`。
- 响应数据为 JSON 字符串时会尝试解析；当前会处理 `Map` 类型的响应。
- 响应对象中的 `data` 为 `Map` 时会应用字段映射。
- 字符串字段超过 200 个字符时，日志会截断并附加 `...(long data)`。
- `hideKeys` 只影响普通请求日志；悬浮调试面板仍会记录原始请求数据。因此生产环境不要启用悬浮调试面板，也不要将敏感信息写入可共享的日志。

## 完整示例

```dart
final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

dio.interceptors.add(DioLogInterceptor(
  hideKeys: const ['password', 'accessToken'],
  showRequestHeader: true,
  singleMap: const {
    '/login': '登录',
    'phone': '手机号',
    'password': '密码',
  },
));
```
