import 'package:flutter_application_1/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'post_state.freezed.dart'; //このファイルを生成する

//これは、投稿データの状態を定義している。
//自動生成する部分
//abstractは抽象クラス（細かい処理内容を記載しないクラスのこと）
@freezed
abstract class PostState with _$PostState {
  const factory PostState({
    @Default(1) int page,
    List<Post>? posts,
    @Default(true) bool isLoading,
    @Default(false) bool isLoadMoreError,
    @Default(false) bool isLoadMoreDone,
  }) = _PostState;

  const PostState._();
}
//
