package com.neushare.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.neushare.common.Result;
import com.neushare.entity.Category;
import com.neushare.service.CategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/category")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @GetMapping("/list")
    public Result<List<Category>> getCategoryList() {
        List<Category> categories = categoryService.list(
                new LambdaQueryWrapper<Category>().orderByAsc(Category::getSort));
        return Result.success(categories);
    }
}
