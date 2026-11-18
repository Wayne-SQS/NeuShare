"""Declarative contract cases — one per Java endpoint (84) plus negative probes.

Every case is replayed in list order against both backends, so the two
databases mutate in lockstep and each response can be compared directly.

* ``role``      who calls: anon / student / teacher / admin
* ``query``     query-string params (mirrors Java ``@RequestParam``)
* ``json``      JSON body (mirrors Java ``@RequestBody``)
* ``form``/``files`` multipart body (mirrors Java form binding + ``MultipartFile``)
* ``mutating``  writes or depends on an earlier write; skipped by the committed
                pytest run unless CONTRACT_ALLOW_WRITES=1
* ``derive``    after the call, capture ids into the replay context so later
                cases can address the row that was just created
"""
from __future__ import annotations

import json

from tests.contract.replay import fill_path

STUDENT = "student"
TEACHER = "teacher"
ADMIN = "admin"

CASES: list[dict] = []


def case(name: str, method: str, path: str, role: str = "anon", **kw) -> None:
    entry = {"name": name, "method": method, "path": path, "role": role}
    entry.update(kw)
    CASES.append(entry)


# -- derive helpers --------------------------------------------------------
def _json(backend, method, path, role, params=None):
    return backend.request(method, path, role, params=params).json


def _pick(data, expr: str):
    cur = data
    for part in expr.split("."):
        cur = cur[int(part)] if part.isdigit() else cur[part]
    return cur


def id_where(path: str, role: str, field_name: str, field_value,
             expr: str = "data.records", params: dict | None = None):
    """Capture the id of the row whose ``field_name`` equals ``field_value``.

    ``path`` may itself contain ``{{id}}`` placeholders; they are resolved from
    the replay context before the lookup runs.
    """

    def derive(backend, ctx):
        resolved = fill_path(path, ctx)
        items = _pick(_json(backend, "GET", resolved, role, params), expr)
        for item in items:
            if item.get(field_name) == field_value:
                return item["id"]
        raise AssertionError(f"{resolved} 中找不到 {field_name}={field_value!r}")

    return derive


# =========================================================================
# 1. 公开读取
# =========================================================================
case("banner.list", "GET", "/api/banner/list")
case("category.list", "GET", "/api/category/list")
case("formcard.current", "GET", "/api/form-card/current")
case("stats.overview", "GET", "/api/stats/overview",
     # Java 只按 count 降序排，并列项顺序取自 HashMap 迭代序（不可复现）
     unordered=[("data.categoryDistribution", "name"),
                ("data.sourceDistribution", "name"),
                ("data.topResources", "id")])

case("resource.list.default", "GET", "/api/resource/list")
case("resource.list.page2", "GET", "/api/resource/list", query={"pageNum": 2, "pageSize": 10})
case("resource.list.sortHot", "GET", "/api/resource/list", query={"sortBy": "hot"})
case("resource.list.category", "GET", "/api/resource/list", query={"categoryId": 1})
case("resource.list.keyword", "GET", "/api/resource/list", query={"keyword": "Java"})
case("resource.list.status.forcedForStudent", "GET", "/api/resource/list",
     role=STUDENT, query={"status": 0})
case("resource.list.status.allowedForAdmin", "GET", "/api/resource/list",
     role=ADMIN, query={"status": 0})

case("resource.hot", "GET", "/api/resource/hot", query={"limit": 5})
case("resource.search", "GET", "/api/resource/search", query={"keyword": "Java"})
case("resource.search.sortHot", "GET", "/api/resource/search",
     query={"keyword": "C语言", "sortBy": "hot"})
case("resource.search.missingKeyword", "GET", "/api/resource/search")

case("resource.detail.1", "GET", "/api/resource/detail/1")
case("resource.detail.404", "GET", "/api/resource/detail/999999")
case("resource.detail.pending.anon", "GET", "/api/resource/detail/13")
case("resource.detail.pending.owner", "GET", "/api/resource/detail/13", role=STUDENT)

case("resource.download.local", "GET", "/api/resource/download/1")
case("resource.download.external", "GET", "/api/resource/download/118")
case("resource.download.404", "GET", "/api/resource/download/999999")

case("post.list", "GET", "/api/post/list")
case("post.list.tag", "GET", "/api/post/list", query={"tag": "考研"})
case("post.list.keyword", "GET", "/api/post/list", query={"keyword": "复习"})
case("post.list.sortHot", "GET", "/api/post/list", query={"sortBy": "hot", "pageSize": 5})
case("post.list.status.forcedForStudent", "GET", "/api/post/list",
     role=STUDENT, query={"status": 0})
case("post.hot", "GET", "/api/post/hot", query={"limit": 5})
case("post.detail.1", "GET", "/api/post/detail/1")
case("post.detail.404", "GET", "/api/post/detail/999999")

case("comment.list.r1", "GET", "/api/comment/list/1")
case("comment.list.empty", "GET", "/api/comment/list/999999")
case("postcomment.list.p1", "GET", "/api/post/comment/list/1")
case("postcomment.list.empty", "GET", "/api/post/comment/list/999999")

case("user.detail.2", "GET", "/api/user/2")
case("user.detail.disabled", "GET", "/api/user/8")
case("user.detail.404", "GET", "/api/user/999999")
case("user.resources.6", "GET", "/api/user/6/resources")

# =========================================================================
# 2. 鉴权
# =========================================================================
case("auth.login.student", "POST", "/api/auth/login",
     json={"username": "20240001", "password": "123456"})
case("auth.login.admin", "POST", "/api/auth/login",
     json={"username": "admin", "password": "123456"})
case("auth.login.teacher", "POST", "/api/auth/login",
     json={"username": "T20240001", "password": "123456"})
case("auth.login.wrongPassword", "POST", "/api/auth/login",
     json={"username": "20240001", "password": "wrong-password"})
case("auth.login.disabledUser", "POST", "/api/auth/login",
     json={"username": "20240004", "password": "123456"})
case("auth.login.unknownUser", "POST", "/api/auth/login",
     json={"username": "no_such_user", "password": "123456"})
case("auth.login.emptyBody", "POST", "/api/auth/login", json={})

case("auth.info.anon", "GET", "/api/auth/info")
case("auth.info.student", "GET", "/api/auth/info", role=STUDENT)
case("auth.info.admin", "GET", "/api/auth/info", role=ADMIN)

case("auth.password.missingParam", "PUT", "/api/auth/password", role=STUDENT,
     query={"oldPassword": "123456"})
case("auth.password.wrongOld", "PUT", "/api/auth/password", role=STUDENT,
     query={"oldPassword": "not-my-password", "newPassword": "123456"})

case("admin.statistics.anon", "GET", "/api/admin/statistics")
case("admin.statistics.forbidden", "GET", "/api/admin/statistics", role=STUDENT)

# =========================================================================
# 3. 登录后读取
# =========================================================================
case("comment.my", "GET", "/api/comment/my", role=STUDENT)
case("comment.user", "GET", "/api/comment/user", role=STUDENT)
case("favorite.list", "GET", "/api/favorite/list", role=STUDENT)
case("follow.following", "GET", "/api/follow/following", role=STUDENT)
case("follow.followers", "GET", "/api/follow/followers", role=STUDENT)

case("notification.list", "GET", "/api/notification/list", role=TEACHER)
case("notification.list.type", "GET", "/api/notification/list", role=TEACHER,
     query={"type": "like"})
case("notification.unread", "GET", "/api/notification/unread", role=TEACHER)

case("post.user", "GET", "/api/post/user", role=STUDENT)
case("resource.user", "GET", "/api/resource/user", role=STUDENT)

case("resource.like.check.liked", "GET", "/api/resource/like/check/1", role=STUDENT)
case("resource.like.check.notLiked", "GET", "/api/resource/like/check/3", role=STUDENT)
case("favorite.check.yes", "GET", "/api/favorite/check", role=STUDENT,
     query={"resourceId": 2})
case("favorite.check.no", "GET", "/api/favorite/check", role=STUDENT,
     query={"resourceId": 3})
case("follow.check", "GET", "/api/follow/check", role=STUDENT, query={"followedId": 3})
case("post.like.check", "GET", "/api/post/like/check/1", role=STUDENT)
case("post.favorite.check", "GET", "/api/post/favorite/check/1", role=STUDENT)
case("comment.like.check", "GET", "/api/comment/like/check/1", role=STUDENT)
case("postcomment.like.check", "GET", "/api/post/comment/like/check/1", role=STUDENT)

# =========================================================================
# 4. 参数边界 / 错误契约（客户端可触发的 500、信封逃逸）
# =========================================================================
case("boundary.pageNum0", "GET", "/api/resource/list", query={"pageNum": 0})
case("boundary.pageNumNegative", "GET", "/api/resource/list", query={"pageNum": -3})
case("boundary.pageSize0", "GET", "/api/resource/list", query={"pageSize": 0})
case("boundary.pageSizeNegative", "GET", "/api/resource/list", query={"pageSize": -1})
case("boundary.pageSizeHuge", "GET", "/api/resource/list", query={"pageSize": 100000})
case("boundary.pageNumTypeError", "GET", "/api/resource/list", query={"pageNum": "abc"})
case("boundary.detailTypeError", "GET", "/api/resource/detail/abc")
case("boundary.methodNotAllowed", "GET", "/api/favorite/add")
case("boundary.unknownPath", "GET", "/api/nope/nope")

# =========================================================================
# 5. 管理端只读
# =========================================================================
case("admin.statistics", "GET", "/api/admin/statistics", role=ADMIN)
case("admin.user.list", "GET", "/api/admin/user/list", role=ADMIN)
case("admin.user.list.keyword", "GET", "/api/admin/user/list", role=ADMIN,
     query={"keyword": "张"})
case("admin.user.status.404", "PUT", "/api/admin/user/status", role=ADMIN,
     query={"id": 999999, "status": 1})
case("admin.user.status.missingParam", "PUT", "/api/admin/user/status", role=ADMIN,
     query={"id": 3})
case("admin.resource.pending", "GET", "/api/admin/resource/pending", role=ADMIN)
case("admin.comment.list", "GET", "/api/admin/comment/list", role=ADMIN)
case("admin.banner.list", "GET", "/api/admin/banner/list", role=ADMIN)
case("admin.formcard.list", "GET", "/api/admin/form-card/list", role=ADMIN)

# =========================================================================
# 6. 写操作（按顺序自清理；mutating=True）
# =========================================================================
case("write.favorite.add", "POST", "/api/favorite/add", role=STUDENT,
     query={"resourceId": 3}, mutating=True)
case("write.favorite.check", "GET", "/api/favorite/check", role=STUDENT,
     query={"resourceId": 3}, mutating=True)
case("write.favorite.addDuplicate", "POST", "/api/favorite/add", role=STUDENT,
     query={"resourceId": 2}, mutating=True)
case("write.favorite.remove", "DELETE", "/api/favorite/remove", role=STUDENT,
     query={"resourceId": 3}, mutating=True)

case("write.follow.add", "POST", "/api/follow/add", role=STUDENT,
     query={"followedId": 5}, mutating=True)
case("write.follow.check", "GET", "/api/follow/check", role=STUDENT,
     query={"followedId": 5}, mutating=True)
case("write.follow.remove", "DELETE", "/api/follow/remove", role=STUDENT,
     query={"followedId": 5}, mutating=True)

case("write.resource.like", "POST", "/api/resource/like/3", role=STUDENT, mutating=True)
case("write.resource.like.check", "GET", "/api/resource/like/check/3", role=STUDENT,
     mutating=True)
case("write.resource.unlike", "DELETE", "/api/resource/like/3", role=STUDENT,
     mutating=True)

# -- 资源评论
case("write.comment.add", "POST", "/api/comment/add", role=STUDENT,
     query={"resourceId": 1, "content": "Golden 契约比对评论"},
     mutating=True,
     derive={"comment_id": id_where("/api/comment/user", STUDENT, "content",
                                    "Golden 契约比对评论", params={"pageSize": 50})})
case("write.comment.list.afterAdd", "GET", "/api/comment/list/1", mutating=True)
case("write.comment.like", "POST", "/api/comment/like/{{comment_id}}", role=STUDENT,
     mutating=True)
case("write.comment.like.check", "GET", "/api/comment/like/check/{{comment_id}}",
     role=STUDENT, mutating=True)
case("write.comment.unlike", "DELETE", "/api/comment/like/{{comment_id}}",
     role=STUDENT, mutating=True)
case("write.comment.addReply", "POST", "/api/comment/add", role=STUDENT,
     query={"resourceId": 1, "content": "Golden 契约回复", "parentId": 1},
     mutating=True,
     derive={"reply_id": id_where("/api/comment/user", STUDENT, "content",
                                  "Golden 契约回复", params={"pageSize": 50})})
case("write.comment.deleteReply", "DELETE", "/api/comment/delete/{{reply_id}}",
     role=STUDENT, mutating=True)
case("admin.comment.deleteCreated", "DELETE", "/api/admin/comment/delete/{{comment_id}}",
     role=ADMIN, mutating=True)

# -- 帖子全链路
case("write.post.create", "POST", "/api/post/create", role=STUDENT,
     json={
         "title": "Golden 契约比对帖子",
         "content": "这是一条用于契约比对的帖子内容。",
         "tags": '["契约","测试"]',
         "imageUrls": '[]',
         "files": '[]',
     },
     mutating=True,
     derive={"post_id": id_where("/api/post/user", STUDENT, "title",
                                 "Golden 契约比对帖子", params={"pageSize": 50})})
case("write.post.update", "PUT", "/api/post/update", role=STUDENT,
     json={"id": "{{post_id}}", "title": "Golden 契约比对帖子（已更新）",
           "content": "更新后的内容。", "tags": '["契约"]'},
     mutating=True)
case("write.post.like", "POST", "/api/post/like/{{post_id}}", role=STUDENT, mutating=True)
case("write.post.like.check", "GET", "/api/post/like/check/{{post_id}}", role=STUDENT,
     mutating=True)
case("write.post.unlike", "DELETE", "/api/post/like/{{post_id}}", role=STUDENT,
     mutating=True)
case("write.post.favorite", "POST", "/api/post/favorite/{{post_id}}", role=STUDENT,
     mutating=True)
case("write.post.favorite.check", "GET", "/api/post/favorite/check/{{post_id}}",
     role=STUDENT, mutating=True)
case("write.post.unfavorite", "DELETE", "/api/post/favorite/{{post_id}}", role=STUDENT,
     mutating=True)
case("write.post.comment.add", "POST", "/api/post/comment/add", role=STUDENT,
     query={"postId": "{{post_id}}", "content": "Golden 帖子评论"},
     mutating=True,
     derive={"post_comment_id": id_where("/api/post/comment/list/{{post_id}}", STUDENT,
                                         "content", "Golden 帖子评论", expr="data")})
case("write.post.comment.like", "POST", "/api/post/comment/like/{{post_comment_id}}",
     role=STUDENT, mutating=True)
case("write.post.comment.like.check",
     "GET", "/api/post/comment/like/check/{{post_comment_id}}", role=STUDENT,
     mutating=True)
case("write.post.comment.unlike", "DELETE",
     "/api/post/comment/like/{{post_comment_id}}", role=STUDENT, mutating=True)
case("write.post.comment.delete", "DELETE",
     "/api/post/comment/delete/{{post_comment_id}}", role=STUDENT, mutating=True)
case("write.post.delete", "DELETE", "/api/post/delete/{{post_id}}", role=STUDENT,
     mutating=True)

# -- 资源创建（multipart）/ 更新 / 驳回 / 删除
case("write.resource.create", "POST", "/api/resource/create", role=STUDENT,
     form={"title": "Golden 契约资源", "categoryId": "1", "type": "document",
           "description": "契约比对用资源", "tags": '["契约"]'},
     files={"file": ("golden-contract.txt", b"golden contract payload", "text/plain")},
     mutating=True,
     derive={"res_id": id_where("/api/resource/user", STUDENT, "title",
                                "Golden 契约资源", params={"pageSize": 50})})
case("write.resource.update", "PUT", "/api/resource/update", role=STUDENT,
     json={"id": "{{res_id}}", "title": "Golden 契约资源（已更新）", "categoryId": 1,
           "type": "document", "description": "更新后的描述", "tags": '["契约"]'},
     mutating=True)
case("write.resource.createWithoutFile", "POST", "/api/resource/create", role=STUDENT,
     form={"title": "Golden 无文件资源", "categoryId": "1"}, mutating=True)
case("write.resource.createPendingForReject", "POST", "/api/resource/create",
     role=STUDENT,
     form={"title": "Golden 待驳回资源", "categoryId": "1", "type": "document"},
     files={"file": ("golden-reject.txt", b"golden reject payload", "text/plain")},
     mutating=True,
     derive={"reject_id": id_where("/api/resource/user", STUDENT, "title",
                                   "Golden 待驳回资源", params={"pageSize": 50})})
case("admin.resource.audit.reject", "PUT", "/api/admin/resource/audit", role=ADMIN,
     query={"id": "{{reject_id}}", "status": 2, "rejectReason": "Golden 驳回原因"},
     mutating=True)
case("admin.resource.delete.rejected", "DELETE",
     "/api/admin/resource/delete/{{reject_id}}", role=ADMIN, mutating=True)
case("admin.resource.audit.approve", "PUT", "/api/admin/resource/audit", role=ADMIN,
     query={"id": "{{res_id}}", "status": 1}, mutating=True)
case("admin.resource.delete.created", "DELETE", "/api/admin/resource/delete/{{res_id}}",
     role=ADMIN, mutating=True)

# -- 通知
case("write.notification.read", "PUT", "/api/notification/read/2", role=TEACHER,
     mutating=True)
case("write.notification.unreadAfterRead", "GET", "/api/notification/unread",
     role=TEACHER, mutating=True)
case("write.notification.readAll", "PUT", "/api/notification/read-all", role=TEACHER,
     mutating=True)
case("write.notification.delete", "DELETE", "/api/notification/delete/2", role=TEACHER,
     mutating=True)

# -- 用户状态
case("admin.user.status.disable", "PUT", "/api/admin/user/status", role=ADMIN,
     query={"id": 3, "status": 0}, mutating=True)
case("admin.user.status.enable", "PUT", "/api/admin/user/status", role=ADMIN,
     query={"id": 3, "status": 1}, mutating=True)

# -- 注册 / 管理员删除注册用户
case("write.register", "POST", "/api/auth/register",
     json={"username": "golden_user_001", "password": "123456",
           "nickname": "Golden用户", "college": "软件学院", "grade": 2024},
     mutating=True,
     derive={"golden_user_id": id_where("/api/admin/user/list", ADMIN, "username",
                                        "golden_user_001",
                                        params={"keyword": "golden_user_001"})})
case("write.register.duplicate", "POST", "/api/auth/register",
     json={"username": "golden_user_001", "password": "123456"}, mutating=True)
case("write.register.login", "POST", "/api/auth/login",
     json={"username": "golden_user_001", "password": "123456"}, mutating=True)
case("admin.user.delete.registered", "DELETE", "/api/admin/user/delete/{{golden_user_id}}",
     role=ADMIN, mutating=True)

# -- 轮播图 CRUD
case("admin.banner.add", "POST", "/api/admin/banner/add", role=ADMIN,
     json={"title": "Golden 契约轮播", "imageUrl": "/files/golden-banner.png",
           "linkUrl": "/golden", "sort": 99, "status": 1},
     mutating=True,
     derive={"banner_id": id_where("/api/admin/banner/list", ADMIN, "title",
                                   "Golden 契约轮播", expr="data")})
case("admin.banner.update", "PUT", "/api/admin/banner/update", role=ADMIN,
     json={"id": "{{banner_id}}", "title": "Golden 契约轮播（已更新）", "sort": 98},
     mutating=True)
case("admin.banner.status", "PUT", "/api/admin/banner/status", role=ADMIN,
     query={"id": "{{banner_id}}", "status": 0}, mutating=True)
case("admin.banner.delete", "DELETE", "/api/admin/banner/delete/{{banner_id}}",
     role=ADMIN, mutating=True)

# -- 服务卡片 CRUD
case("admin.formcard.add", "POST", "/api/admin/form-card/add", role=ADMIN,
     json={"title": "Golden 契约卡片", "resourceType": "book", "resourceId": 1,
           "contentUrl": "/files/golden-card.pdf", "sortOrder": 99, "status": 1},
     mutating=True,
     derive={"card_id": id_where("/api/admin/form-card/list", ADMIN, "title",
                                 "Golden 契约卡片", expr="data")})
case("admin.formcard.update", "PUT", "/api/admin/form-card/update", role=ADMIN,
     json={"id": "{{card_id}}", "title": "Golden 契约卡片（已更新）", "sortOrder": 98},
     mutating=True)
case("admin.formcard.status", "PUT", "/api/admin/form-card/status", role=ADMIN,
     query={"id": "{{card_id}}", "status": 0}, mutating=True)
case("admin.formcard.delete", "DELETE", "/api/admin/form-card/delete/{{card_id}}",
     role=ADMIN, mutating=True)


def case_names() -> list[str]:
    return [c["name"] for c in CASES]


if __name__ == "__main__":
    print(json.dumps({"count": len(CASES),
                      "mutating": sum(1 for c in CASES if c.get("mutating")),
                      "names": case_names()}, ensure_ascii=False, indent=1))
