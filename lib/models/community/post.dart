import 'community_user.dart';

class Post {
  final int id;
  final String title;
  final String content;
  final String ticker;
  final CommunityUser author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool canEdit;
  final bool canDelete;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.ticker,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      ticker: json['ticker'] as String,
      author: CommunityUser.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      likeCount: json['like_count'] as int,
      commentCount: json['comment_count'] as int,
      isLiked: json['is_liked'] as bool,
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'ticker': ticker,
      'author': author.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_liked': isLiked,
      'can_edit': canEdit,
      'can_delete': canDelete,
    };
  }

  Post copyWith({
    int? likeCount,
    bool? isLiked,
    int? commentCount,
  }) {
    return Post(
      id: id,
      title: title,
      content: content,
      ticker: ticker,
      author: author,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      canEdit: canEdit,
      canDelete: canDelete,
    );
  }
}
