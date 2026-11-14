package com.neushare.util;

import com.neushare.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 上传工具测试：扩展名白名单与随机文件名。
 */
class FileUploadUtilTest {

    @TempDir
    Path tempDir;

    private FileUploadUtil newUtil() {
        FileUploadUtil util = new FileUploadUtil();
        ReflectionTestUtils.setField(util, "uploadPath", tempDir.toString());
        return util;
    }

    @Test
    void shouldRejectExecutableExtension() {
        MockMultipartFile file = new MockMultipartFile(
                "file", "evil.html", "text/html", "<script>alert(1)</script>".getBytes());
        BusinessException ex = assertThrows(BusinessException.class, () -> newUtil().upload(file));
        assertEquals(400, ex.getCode());
    }

    @Test
    void shouldRejectFileWithoutExtension() {
        MockMultipartFile file = new MockMultipartFile("file", "noext", "text/plain", "x".getBytes());
        assertThrows(BusinessException.class, () -> newUtil().upload(file));
    }

    @Test
    void shouldRenameUploadedFileToUuid() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file", "课件.PDF", "application/pdf", "pdf-content".getBytes());
        String stored = newUtil().upload(file);
        assertTrue(stored.endsWith(".pdf"));
        assertFalse(stored.contains("课件"));
        assertTrue(stored.matches("[0-9a-fA-F-]{36}\\.pdf"));
        assertTrue(tempDir.resolve(stored).toFile().exists());
    }
}
