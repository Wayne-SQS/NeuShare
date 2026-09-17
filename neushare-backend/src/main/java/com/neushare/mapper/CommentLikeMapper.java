package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neushare.entity.CommentLike;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 资源评论点赞记录Mapper
 */
@Mapper
public interface CommentLikeMapper extends BaseMapper<CommentLike> {

    CommentLike selectByUserIdAndCommentId(@Param("userId") Long userId, @Param("commentId") Long commentId);
}
