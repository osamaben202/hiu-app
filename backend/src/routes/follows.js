/**
 * 关注路由
 */
const express = require('express');
const { query } = require('../models/db');
const { auth } = require('../middleware/auth');
const response = require('../utils/response');

const router = express.Router();

/**
 * POST /api/follows/:userId
 * 关注用户
 */
router.post('/:userId', auth, async (req, res) => {
    try {
        const { userId } = req.params;
        
        if (userId === req.user.id) {
            return response.badRequest(res, '不能关注自己');
        }
        
        const userCheck = await query(
            'SELECT id, nickname FROM users WHERE id = $1 AND is_banned = false',
            [userId]
        );
        
        if (userCheck.rows.length === 0) {
            return response.notFound(res, '用户不存在');
        }
        
        const existingCheck = await query(
            'SELECT id FROM follows WHERE follower_id = $1 AND following_id = $2',
            [req.user.id, userId]
        );
        
        if (existingCheck.rows.length > 0) {
            return response.badRequest(res, '已关注该用户');
        }
        
        await query(
            'INSERT INTO follows (follower_id, following_id) VALUES ($1, $2)',
            [req.user.id, userId]
        );
        
        return response.success(res, { following_id: userId }, '关注成功');
    } catch (error) {
        console.error('Follow error:', error);
        return response.serverError(res, '关注失败');
    }
});

/**
 * DELETE /api/follows/:userId
 * 取消关注
 */
router.delete('/:userId', auth, async (req, res) => {
    try {
        const { userId } = req.params;
        
        const result = await query(
            'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2 RETURNING id',
            [req.user.id, userId]
        );
        
        if (result.rows.length === 0) {
            return response.notFound(res, '未关注该用户');
        }
        
        return response.success(res, null, '已取消关注');
    } catch (error) {
        console.error('Unfollow error:', error);
        return response.serverError(res, '操作失败');
    }
});

/**
 * GET /api/follows/following
 * 获取我的关注列表
 */
router.get('/following', auth, async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;
        
        const countResult = await query(
            'SELECT COUNT(*) FROM follows WHERE follower_id = $1',
            [req.user.id]
        );
        const total = parseInt(countResult.rows[0].count);
        
        const result = await query(`
            SELECT u.id, u.nickname, u.avatar, u.gender, u.signature, u.created_at
            FROM follows f
            JOIN users u ON f.following_id = u.id
            WHERE f.follower_id = $1 AND u.is_banned = false
            ORDER BY f.created_at DESC
            LIMIT $2 OFFSET $3
        `, [req.user.id, limit, offset]);
        
        return response.success(res, {
            list: result.rows,
            total,
            page: parseInt(page),
            limit: parseInt(limit),
        });
    } catch (error) {
        console.error('Get following error:', error);
        return response.serverError(res, '获取失败');
    }
});

/**
 * GET /api/follows/followers
 * 获取我的粉丝列表
 */
router.get('/followers', auth, async (req, res) => {
    try {
        const { page = 1, limit = 20 } = req.query;
        const offset = (page - 1) * limit;
        
        const countResult = await query(
            'SELECT COUNT(*) FROM follows WHERE following_id = $1',
            [req.user.id]
        );
        const total = parseInt(countResult.rows[0].count);
        
        const result = await query(`
            SELECT u.id, u.nickname, u.avatar, u.gender, u.signature, u.created_at
            FROM follows f
            JOIN users u ON f.follower_id = u.id
            WHERE f.following_id = $1 AND u.is_banned = false
            ORDER BY f.created_at DESC
            LIMIT $2 OFFSET $3
        `, [req.user.id, limit, offset]);
        
        return response.success(res, {
            list: result.rows,
            total,
            page: parseInt(page),
            limit: parseInt(limit),
        });
    } catch (error) {
        console.error('Get followers error:', error);
        return response.serverError(res, '获取失败');
    }
});

/**
 * GET /api/follows/:userId/count
 * 获取用户的关注数和粉丝数
 */
router.get('/:userId/count', auth, async (req, res) => {
    try {
        const { userId } = req.params;
        
        const followingCount = await query(
            'SELECT COUNT(*) FROM follows WHERE follower_id = $1',
            [userId]
        );
        
        const followersCount = await query(
            'SELECT COUNT(*) FROM follows WHERE following_id = $1',
            [userId]
        );
        
        const isFollowing = await query(
            'SELECT id FROM follows WHERE follower_id = $1 AND following_id = $2',
            [req.user.id, userId]
        );
        
        return response.success(res, {
            following_count: parseInt(followingCount.rows[0].count),
            followers_count: parseInt(followersCount.rows[0].count),
            is_following: isFollowing.rows.length > 0,
        });
    } catch (error) {
        console.error('Get follow count error:', error);
        return response.serverError(res, '获取失败');
    }
});

module.exports = router;
