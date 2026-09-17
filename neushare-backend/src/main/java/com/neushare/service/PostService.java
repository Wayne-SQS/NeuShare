package com.neushare.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.service.IService;
import com.neushare.entity.Post;
import com.neushare.vo.PostVO;

import java.util.List;

/**
 * 帖子服务接口
 */
public interface PostService extends IService<Post> {

    IPage<PostVO> getPostPage(Integer pageNum, Integer pageSize, Integer status, String tag, String keyword, String sortBy);

    PostVO getPostDetail(Long id);

    void createPost(Post post, Long userId);

    void updatePost(Post post, Long userId, String role);

    void deletePost(Long id, Long userId, String role);

    List<PostVO> getHotPosts(Integer limit);

    void incrementViewCount(Long id);

    void likePost(Long postId, Long userId);

    void unlikePost(Long postId, Long userId);

    boolean isLiked(Long postId, Long userId);

    void favoritePost(Long postId, Long userId);

    void unfavoritePost(Long postId, Long userId);

    boolean isFavorited(Long postId, Long userId);

    IPage<PostVO> getUserPosts(Integer pageNum, Integer pageSize, Long userId);

    void recommendPost(Long id, Long userId, String role);
}
