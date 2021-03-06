/// Twitter API wrapper to make simple request to Twitter's servers
/// @ZoeyLovesMiki, 2020

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import '../twitter.dart'; 

const BASE_URL = "api.twitter.com";

/// Wrapper class to call the Twitter API doing raw requests
class TwitterAPI {
  String consumerKey;
  String consumerSecret;
  String token;
  String tokenSecret;
  
  TwitterAPI({
    this.consumerKey,
    this.consumerSecret,
    this.token = "",
    this.tokenSecret = ""
  });

  /// Call the Twitter API with proper oauth headers and signature
  /// [method] is the HTTP method to use, GET or POST.
  /// [url] is the full path for the endpoint, /1.1/some/thing.json
  Future<http.Response> _request(String method, String url, Map<String, String> params, {Map<String, String> body}) async {
    if (params == null) params = {};

    Uri originalUrl = Uri.parse("https://$BASE_URL$url");
    Uri finalUrl = _fixedURL(url, params);
    
    // Create our OauthHelper instance
    OAuthHelper helper = new OAuthHelper(
      consumerKey: this.consumerKey,
      consumerSecret: this.consumerSecret,
      token: this.token, 
      tokenSecret: this.tokenSecret
    );

    if (body != null) {
      params.addAll(body);
    }

    // Create our oAuth signature and Authorization header
    String signature = helper.getSignature(method, originalUrl.toString(), params);
    String oauthHeader = helper.getAuthHeader(signature);

    // Set the proper headers
    Map<String, String> headers = {
      "Authorization": oauthHeader,
      "Content-Type": "application/x-www-form-urlencoded"
    };

    // Add extra heders if needed
    headers.addAll(await _getExtraHeaders(helper.type));

    // Do our http request and return the response
    http.Response response;

    if (method == "POST") {
      response = await http.post(finalUrl, headers: headers, body: body);
    } else {
      response = await http.get(finalUrl, headers: headers);
    }

    return response;
  }

  /// Get extra headers
  Future<Map<String, String>> _getExtraHeaders(KeyType keyType) async {
    Map<String, String> extraHeaders = new Map();

    // Twitter for Android requires extra headers to make the request works using Twitter's keys
    if (keyType == KeyType.Android) {
      const String clientName = "TwitterAndroid";
      const String versionName = "6.41.0";
      const String apiVersion = "5";
      const String internalVersionName = "7160062-r-930";

      // Default values used when using the keys on a non Android platform
      String model = "Pixel 3";
      String sdkVersion = "30";
      String manufacturer = "Google";
      String brand = "google";
      String product = "blueline";

      // Use the actual device information if we're using an Android phone
      if (Platform.isAndroid) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        model = androidInfo.model;
        sdkVersion = androidInfo.version.sdkInt.toString();
        manufacturer = androidInfo.manufacturer;
        brand = androidInfo.brand;
        product = androidInfo.product;
      }

      extraHeaders.addAll({
        "User-Agent": "$clientName/$versionName ($internalVersionName) $model/$sdkVersion ($manufacturer;$model;$brand;$product;0;;0)",
        "Accept-Language": "en_US",
        "X-Twitter-Client": clientName,
        "X-Twitter-Client-Language": "en_US",
        "X-Twitter-Client-Version": versionName,
        "X-Twitter-API-Version": apiVersion
      });
    }

    return extraHeaders;
  }

  // Twitter's oAuth is garbage
  // If the URL includes some query, it needs to be included in the oauth signature
  // The final URL includes the "data" as part of the query but these shouldn't be part of the oauth signature
  // This fixes the url and add the missing query info that aren't part of the base url
  Uri _fixedURL(String url, Map<String, String> params) {
    Map<String, String> paramsWithQuery = params;
    String urlWithoutQuery = "";

    Uri.parse(url).queryParameters.forEach((key, value) {
      paramsWithQuery.addAll({key: value});
    });

    urlWithoutQuery = url.replaceAll("?${Uri.parse(url).query}", "");

    return Uri.https("api.twitter.com", urlWithoutQuery, paramsWithQuery);
  }

  /// Do a post request to [url] using the [params] and [body]
  Future<http.Response> post(String url, {Map<String, String> params, Map<String, String> body}) async{
    if (body == null) body = new Map();
    return await _request("POST", url, params, body: body);
  }

  /// Do a get request to [url] using the [params] and [body]
  Future<http.Response> get(String url, {Map<String, String> params}) async {
    return await _request("GET", url, params);
  }
}