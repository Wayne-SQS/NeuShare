"""ORM models mapped 1:1 to the live MySQL schema (see _schema.sql).

JSON columns (tags / image_urls / files) are mapped as Text so the raw JSON string
is read/written verbatim — matching the Java backend, which returns these columns
as String (frontend JSON.parse()s them).
"""
from datetime import datetime
from typing import Optional

from sqlalchemy import BigInteger, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


def _dt():
    return mapped_column(DateTime, default=datetime.now)


class User(Base):
    __tablename__ = "user"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    username: Mapped[str] = mapped_column(String(50), nullable=False)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[Optional[str]] = mapped_column(String(20), default="student")
    nickname: Mapped[Optional[str]] = mapped_column(String(50))
    avatar_url: Mapped[Optional[str]] = mapped_column(String(255))
    college: Mapped[Optional[str]] = mapped_column(String(50))
    grade: Mapped[Optional[int]] = mapped_column(Integer)
    resource_count: Mapped[int] = mapped_column(BigInteger, default=0)
    follower_count: Mapped[int] = mapped_column(BigInteger, default=0)
    following_count: Mapped[int] = mapped_column(BigInteger, default=0)
    total_likes_received: Mapped[int] = mapped_column(BigInteger, default=0)
    status: Mapped[int] = mapped_column(Integer, default=1)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
    update_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Category(Base):
    __tablename__ = "category"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    parent_id: Mapped[int] = mapped_column(BigInteger, default=0)
    sort: Mapped[int] = mapped_column(Integer, default=0)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Banner(Base):
    __tablename__ = "banner"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    title: Mapped[Optional[str]] = mapped_column(String(100))
    image_url: Mapped[str] = mapped_column(String(255), nullable=False)
    link_url: Mapped[Optional[str]] = mapped_column(String(255))
    sort: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[int] = mapped_column(Integer, default=1)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Resource(Base):
    __tablename__ = "resource"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    category_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    type: Mapped[str] = mapped_column(String(20), nullable=False)
    content_url: Mapped[Optional[str]] = mapped_column(String(500))
    description: Mapped[Optional[str]] = mapped_column(Text)
    cover_url: Mapped[Optional[str]] = mapped_column(String(255))
    source: Mapped[Optional[str]] = mapped_column(String(100))
    tags: Mapped[Optional[str]] = mapped_column(Text)  # JSON string
    upload_user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    status: Mapped[int] = mapped_column(Integer, default=0)
    reject_reason: Mapped[Optional[str]] = mapped_column(String(500))
    view_count: Mapped[int] = mapped_column(Integer, default=0)
    like_count: Mapped[int] = mapped_column(Integer, default=0)
    favorite_count: Mapped[int] = mapped_column(Integer, default=0)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
    update_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class ResourceLike(Base):
    __tablename__ = "resource_like"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    resource_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Favorite(Base):
    __tablename__ = "favorite"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    resource_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Comment(Base):
    __tablename__ = "comment"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    resource_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    parent_id: Mapped[int] = mapped_column(BigInteger, default=0)
    deleted: Mapped[int] = mapped_column(Integer, default=0)
    like_count: Mapped[int] = mapped_column(Integer, default=0)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
    update_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class CommentLike(Base):
    __tablename__ = "comment_like"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    comment_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Follow(Base):
    __tablename__ = "follow"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    follower_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    followed_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class FormCard(Base):
    __tablename__ = "form_card"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    resource_type: Mapped[Optional[str]] = mapped_column(String(20), default="book")
    resource_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    content_url: Mapped[Optional[str]] = mapped_column(String(500))
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[int] = mapped_column(Integer, default=1)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
    update_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Notification(Base):
    __tablename__ = "notification"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    type: Mapped[str] = mapped_column(String(20), nullable=False)
    resource_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    from_user_id: Mapped[Optional[int]] = mapped_column(BigInteger)
    title: Mapped[Optional[str]] = mapped_column(String(200))
    content: Mapped[Optional[str]] = mapped_column(String(500))
    is_read: Mapped[int] = mapped_column(Integer, default=0)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class Post(Base):
    __tablename__ = "post"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[Optional[str]] = mapped_column(Text)
    tags: Mapped[Optional[str]] = mapped_column(Text)  # JSON string
    image_urls: Mapped[Optional[str]] = mapped_column(Text)  # JSON string
    files: Mapped[Optional[str]] = mapped_column(Text)  # JSON string
    is_recommended: Mapped[int] = mapped_column(Integer, default=0)
    view_count: Mapped[int] = mapped_column(Integer, default=0)
    like_count: Mapped[int] = mapped_column(Integer, default=0)
    favorite_count: Mapped[int] = mapped_column(Integer, default=0)
    comment_count: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[int] = mapped_column(Integer, default=1)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
    update_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class PostComment(Base):
    __tablename__ = "post_comment"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    post_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    parent_id: Mapped[int] = mapped_column(BigInteger, default=0)
    deleted: Mapped[int] = mapped_column(Integer, default=0)
    like_count: Mapped[int] = mapped_column(Integer, default=0)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
    update_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class PostCommentLike(Base):
    __tablename__ = "post_comment_like"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    comment_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class PostFavorite(Base):
    __tablename__ = "post_favorite"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    post_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)


class PostLike(Base):
    __tablename__ = "post_like"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    post_id: Mapped[int] = mapped_column(BigInteger, nullable=False)
    create_time: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.now)
