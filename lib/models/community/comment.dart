import 'community_user.dart';

class Comment {
  final int id;
  final String content;
  final CommunityUser author;
  final int postId;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;
  final bool canEdit;
  final bool canDelete;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.postId,
    required this.createdAt,
    required this.likeCount,
    this.isLiked = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      content: json['content'] as String,
      author: CommunityUser.fromJson(json['author'] as Map<String, dynamic>),
      postId: json['post'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
    );
  }

  Comment copyWith({
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id,
      content: content,
      author: author,
      postId: postId,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      canEdit: canEdit,
      canDelete: canDelete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author.toJson(),
      'post': postId,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }

  bool get isLocked => content == '🔒 회원 전용 댓글입니다';
}
