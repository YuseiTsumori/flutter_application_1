import 'dart:convert';
import 'post.dart';
import 'package:http/http.dart' as http;

//<Post>はpost.dartのPostクラスから引っ張っていている
//getPosts(int page)関数は引数としてページ番号を取得していて、$pageに入れる
//Futureは非同期処理ってやつで時間がかかる処理の時に使うぞ（他の処理を実行したい時にも使う）
//Future<>の<>は返り値
Future<List<Post>> getPosts(int page) async {
  print('httpClient loading page $page'); //コンソールに出力
  // fake loading error at page = 1
  // if (page == 1) {
  //   // load more e_rror
  //   await Future.delayed(Duration(seconds: 2));
  //   return null;
  // }

  // fake load more error at page = 3
  // if (page == 3) {
  //   // load more error
  //   await Future.delayed(Duration(seconds: 2));
  //   return null;
  // }

//limit=10なので１０件ずつのデータを取得
  try {
    //通常行う処理を書く場所
    //URLからデータを取得し、responseに入れる
    final response = await http.get(Uri.parse(
        'https://jsonplaceholder.typicode.com/posts?_page=$page&_limit=10'));
    final List<Post> posts = (jsonDecode(response.body) as List)
        .map((e) => Post.fromJsonMap(e))
        .toList();
    return posts;
  } catch (ex, st) {
    //エラー(例外)が発生したらこの処理を実行して空っぽのリスト[]を返す。
    print(ex); //exは例外オブジェクトを表示する
    print(st); //スタックトレースオブジェクトというものを表示する（どこでエラーが出たのかなどを含んだ情報）
    //なぜここが[null]ではダメで[]ならいいかっていうと、Future<List<Post>>でList型であり、nullは関数の戻り値に対応してないからエラーになる。
    //Listのnullは[]なのでこれに置き換える。ってことでOK？
    return [];
  }
}
