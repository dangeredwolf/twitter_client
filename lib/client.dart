import 'dart:convert';

import 'package:http/http.dart';
import 'package:twitter_client/api.dart';
import 'package:twitter_client/models/AccessToken.dart';
import 'package:twitter_client/models/Tweet.dart';

import 'models/RequestToken.dart';

class TwitterClient {
  TwitterAPI twitter;

  TwitterClient(this.twitter);

  /// Convert a list (value=key&value=key) into a map
  Map<String, String> _responseToMap(String response) {
    Map<String, String> output = new Map();
    
    List<String> pairList = response.split("&");

    pairList.forEach((element) { 
      List<String> values = element.split("=");
      output.addAll({
        values[0]: values[1]
      });
    });

    return output;
  }

  /// Generate an Oauth token to authorize an user
  Future<RequestToken> getRequestToken() async {
    Response response = await this.twitter.post("/oauth/request_token", params: {
      "oauth_callback": "oob"
    });

    Map<String, String> values = _responseToMap(response.body);

    return RequestToken.fromJson(values);
  }

  /// Get our access token
  Future<AccessToken> getAccessToken(String oauthToken, String oauthVerifier) async {
    Response response = await this.twitter.post("/oauth/access_token", params: {
      "oauth_token": oauthToken,
      "oauth_verifier": oauthVerifier
    });

    Map<String, String> values = _responseToMap(response.body);

    return AccessToken.fromJson(values);
  }

  /// Generate the authorization URL
  String getAuthorizationURL(String oauthToken) {
    return "https://api.twitter.com/oauth/authenticate?oauth_token=$oauthToken";
  }

  /// Send a Tweet to Twitter
  /// [tweet] is the content of your Tweet
  /// [reply_to] is the ID of the tweet to reply to
  /// [media_ids] is a list of IDs of images you've uploaded to Twitter
  Future<Tweet> sendTweet(String tweet, {String replyTo, List<String> mediaIDs}) async {
    Map<String, String> params = {
      "status": tweet
    };

    if (replyTo != null) {
      params.addAll({
        "auto_populate_reply_metadata": "true",
        "in_reply_to_status_id": replyTo
      });
    }

    if (mediaIDs != null) {
      params.addAll({
        "media_ids": mediaIDs.join(',')
      });
    }

    Response response = await this.twitter.post("/1.1/statuses/update.json", params: params);

    if (response.statusCode != 200) {
      throw "Couldn't send this tweet!";
    }

    return new Tweet.fromJson(jsonDecode(response.body));
  }

  /// Get home timeline
  Future<void> getHomeTimeline() async {
    Response response = await this.twitter.get("/1.1/statuses/home_timeline.json", params: {
      "count": "40",
      "exclude_replies": "false",
      "include_entities": "true"
    });


  }

  /// Read a conversation
  Future<List<Tweet>> getConversation(String tweetID) async {
    Response response = await this.twitter.get("/2/timeline/conversation/$tweetID.json", params: {
      "include_reply_count": "true",
      "cards_platform": "Web-13",
      "include_entities": "true",
      "include_user_entities": "true",
      "include_cards": "true",
      "tweet_mode": "extended",
      "include_ext_alt_text": "true"
    });

    Map<String, dynamic> body = json.decode(response.body);

    Map<String, dynamic> tweets = body["globalObjects"]["tweets"];

    tweets.forEach((key, value) {
      Tweet tweet = new Tweet.fromJson(value);
      print(tweet.fullText);
    });
  }
}