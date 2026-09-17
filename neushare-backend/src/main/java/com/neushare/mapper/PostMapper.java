package com.neushare.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.neushare.entity.Post;
import com.neushare.vo.PostVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 帖子Mapper接口
 */
@Mapper
public interface PostMapper extends BaseMapper<Post> {

    IPage<PostVO> selectPostPage(Page<PostVO> page, @Param("status") Integer status, @Param("tag") String tag, @Param("keyword") String keyword, @Param("sortBy") String sortBy);

    PostVO selectPostById(@Param("id") Long id);

    List<PostVO> selectHotPosts(@Param("limit") Integer limit);

    IPage<PostVO> selectUserPosts(Page<PostVO> page, @Param("userId") Long userId);
}
