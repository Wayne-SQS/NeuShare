package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.neushare.entity.PostComment;
import com.neushare.vo.PostCommentVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 帖子评论Mapper接口
 */
@Mapper
public interface PostCommentMapper extends BaseMapper<PostComment> {

    List<PostCommentVO> selectCommentsByPostId(@Param("postId") Long postId);
}
