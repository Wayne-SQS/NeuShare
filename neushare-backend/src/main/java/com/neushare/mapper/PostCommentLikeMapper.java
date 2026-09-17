package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neushare.entity.PostCommentLike;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 帖子评论点赞记录Mapper
 */
@Mapper
public interface PostCommentLikeMapper extends BaseMapper<PostCommentLike> {

    PostCommentLike selectByUserIdAndCommentId(@Param("userId") Long userId, @Param("commentId") Long commentId);
}
