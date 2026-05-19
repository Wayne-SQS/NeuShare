package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.entity.Comment;
import com.neushare.vo.CommentVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 评论Mapper接口
 */
@Mapper
public interface CommentMapper extends BaseMapper<Comment> {

    /**
     * 查询资源的评论列表（包含用户信息）
     */
    List<CommentVO> selectCommentsByResourceId(@Param("resourceId") Long resourceId);

    /**
     * 查询用户的评论列表
     */
    IPage<CommentVO> selectCommentsByUserId(Page<CommentVO> page, @Param("userId") Long userId);

    /**
     * 分页查询所有评论（管理员）
     */
    IPage<CommentVO> selectCommentVOPage(Page<CommentVO> page);
}
