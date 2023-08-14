import 'package:flutter/material.dart';
import 'package:flutter_application_1/post_asyncnotifier_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'post.dart';

//StateProvider=フィルタの条件 / シンプルなステートオブジェクト
//KeyProvideというProviderを作成（初期化）
//俺がいつも使うProviderはサービスクラス / 算出プロパティ（リストのフィルタなど）
final keyProvider = StateProvider<String>((ref) {
  return '';
});

//postSearchProviderというプProviderを作成(初期化)
//ref.watch=プロバイダの値を取得した上で、その変化を監視する。値が変化すると、その値に依存するウィジェットやプロバイダの更新が行われる。
//↑可能な限りref.watchを使うことらしい
//他にもreadとか色々あるのでドキュメント読むこと
final postSearchProvider = StateProvider<List<Post>>((ref) {
  final postState = ref.watch(
      postAsyncnotifierProviderProvider); //postAsyncnotifierProviderProviderを監視
  final key = ref.watch(keyProvider); //keyProvider(入力された文字)を監視

//なんで？を消したら動くのか？=postsの戻り値がList<post>であり、Nullを返すことを許可されていないのでエラーになる。
  return postState.value!.posts! //現在の投稿リストを取得[!]はNull出ないことを明示
      //ここで入力された文字列[key]に応じてbodyとtitleに含んでいるもののみに絞り込む
      .where((element) =>
          element.body.contains(key) || element.title.contains(key))
      .toList(); //新しいリストとして返す
});
//プロバイダをWidgetで使うのでProviderScopedで囲む
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // お馴染みのやつ
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  //なぜここでエラーが出るのか？=多分これFlutter1.0の時に書かれたコードでNullSafety非対応なため
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final ScrollController _controller = ScrollController();
  int oldLength = 0;

  @override
  void initState() {
    super.initState();
    //スクロールされるたびに呼び出される関数
    _controller.addListener(() async {
      //リストの最後までスクロールをしたかどうかをチェック
      //現在のスクロール位置＜最大下部のスクロール位置になったら発動
      if (_controller.position.pixels >
          _controller.position.maxScrollExtent -
              MediaQuery.of(context).size.height) {
        //不意データの長さと現在のデータの長さが同じであれば次のページを読み込む
        if (oldLength ==
            ref.read(postAsyncnotifierProviderProvider).value!.posts!.length) {
          // make sure ListView has newest data after previous loadMore
          //さっきの条件がTrueであればこれを実行して読み込む
          ref.read(postAsyncnotifierProviderProvider.notifier).loadMorePost();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncTodos = ref.watch(postAsyncnotifierProviderProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(
              hintText: 'Enter to search!',
              hintStyle: TextStyle(color: Colors.yellow)),
          onChanged: (newValue) {
            ref.read(keyProvider.notifier).state =
                newValue; //入力した文字（nuewValue)を入れる
          },
        ),
      ),
      body: asyncTodos.when(
        // 投稿のロード状態に応じて表示を変更
        data: (asyncTodos) => Consumer(
          builder: (ctx, watch, child) {
            //.notifierはインスタンへのアクセス許可・.stateはプロ杯だの現在の状態を取得
            //ref.watchはプロバイダーを監視するやつ(値も得るよ)
            // sync oldLength with post.length to make sure ListView has newest
            // data, so loadMore will work correctly
            //?.の部分はNullにならないので.だけにする
            //posts.length ?? 0;は左側がNullの場合に備えているが、Nullになることはないので、「0」は削除。
            oldLength = asyncTodos.posts!.length;
            // init data or error
            //（この部分わからんのでとりあえず誤魔化す）
            // ignore: unnecessary_null_comparison
            if (asyncTodos.posts! == null) {
              // error case
              if (asyncTodos.isLoading == false) {
                return const Center(
                  child: Text('error'),
                );
              }
              return const _Loading();
            }
            //上からひっぱた時に更新させるやつ
            return RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(postAsyncnotifierProviderProvider.notifier)
                    .refresh();
              },
              child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  controller: _controller,
                  itemCount: asyncTodos.posts!.length + 1, //リストに表示するデータの個数
                  itemBuilder: (ctx, index) {
                    // 現在ビルドされているリストのアイテムの位置を示す番号らしい。
                    //ctxはcontextの略
                    // 最後の要素（プログレスバー、エラー、または最後の要素に到達した場合はDone!とする）
                    if (index == asyncTodos.posts!.length) {
                      // さらにロードしてエラーが出た際に実行
                      if (asyncTodos.isLoadMoreError) {
                        return const Center(
                          child: Text('Error'),
                        );
                      }
                      // ロードしまくって最後の部分に到達した際に実行させる
                      if (asyncTodos.isLoadMoreDone) {
                        return const Center(
                          child: Text(
                            'Done!',
                            style: TextStyle(color: Colors.green, fontSize: 20),
                          ),
                        );
                      }
                      return const LinearProgressIndicator();
                    }
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            asyncTodos.posts![index].title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(asyncTodos.posts![index].body),
                          trailing:
                              Text(asyncTodos.posts![index].id.toString()),
                        ),
                        const Divider(),
                      ],
                    );
                  }),
            );
          },
        ),
        error: (err, stack) => const Text('error'),
        loading: () =>
            const _Loading(), //ローディング中はこいつを実行させてCircularProgressIndicatorを出す
      ),
    );
  }
}

//起動した時にローディング表示
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
