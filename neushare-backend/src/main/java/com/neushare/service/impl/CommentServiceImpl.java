package com.neushare.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Comment;
import com.neushare.exception.BusinessException;
import com.neushare.mapper.CommentMapper;
import com.neushare.service.CommentService;
import com.neushare.vo.CommentVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 评论服务实现类
 */
@Service
public class CommentServiceImpl extends ServiceImpl<CommentMapper, Comment> implements CommentService {

    @Autowired
    private CommentMapper commentMapper;

    @Override
    public List<CommentVO> getCommentsByResourceId(Long resourceId) {
        List<CommentVO> allComments = commentMapper.selectCommentsByResourceId(resourceId);
        List<CommentVO> roots = allComments.stream()
                .filter(c -> c.getParentId() == null || c.getParentId() == 0)
                .collect(Collectors.toList());
        for (CommentVO root : roots) {
            root.setChildren(findChildren(root.getId(), allComments));
        }
        return roots;
    }

    private List<CommentVO> findChildren(Long parentId, List<CommentVO> allComments) {
        List<CommentVO> children = new ArrayList<>();
        for (CommentVO comment : allComments) {
            if (parentId.equals(comment.getParentId())) {
                comment.setChildren(findChildren(comment.getId(), allComments));
                children.add(comment);
            }
        }
        return children;
    }

    @Override
    public void addComment(Long resourceId, Long userId, String content, Long parentId) {
        Comment comment = new Comment();
        comment.setResourceId(resourceId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setParentId(parentId != null ? parentId : 0L);
        comment.setCreateTime(LocalDateTime.now());
        save(comment);
    }

    @Override
    public void deleteComment(Long id, Long userId) {
        Comment comment = getById(id);
        if (comment == null) {
            throw new BusinessException("评论不存在");
        }
        if (!comment.getUserId().equals(userId)) {
            throw new BusinessException("无权删除此评论");
        }
        removeById(id);
    }

    @Override
    public IPage<CommentVO> getCommentsByUserId(Integer pageNum, Integer pageSize, Long userId) {
        Page<CommentVO> page = new Page<>(pageNum, pageSize);
        return commentMapper.selectCommentsByUserId(page, userId);
    }

    @Override
    public IPage<CommentVO> getCommentVOPage(Integer pageNum, Integer pageSize) {
        Page<CommentVO> page = new Page<>(pageNum, pageSize);
        return commentMapper.selectCommentVOPage(page);
    }
}
