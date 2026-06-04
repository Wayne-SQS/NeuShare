package com.neushare.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.neushare.entity.Category;
import com.neushare.mapper.CategoryMapper;
import com.neushare.service.CategoryService;
import org.springframework.stereotype.Service;

@Service
public class CategoryServiceImpl extends ServiceImpl<CategoryMapper, Category> implements CategoryService {
}
