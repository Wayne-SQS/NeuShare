package com.neushare;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * NeuShare应用启动类
 */
@SpringBootApplication
@MapperScan("com.neushare.mapper")
public class NeushareApplication {

    public static void main(String[] args) {
        SpringApplication.run(NeushareApplication.class, args);
        System.out.println("========================================");
        System.out.println("NeuShare后端服务启动成功！");
        System.out.println("访问地址: http://localhost:8080");
        System.out.println("========================================");
    }
}
