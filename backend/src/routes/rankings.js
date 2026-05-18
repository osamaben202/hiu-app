/**
 * 排行榜路由
 */
const express = require('express');
const { query } = require('../models/db');
const { auth } = require('../middleware/auth');
const response = require('../utils/response');

const router = express.Router();

/**
 * GET /api/rankings/charm
 * 魅力榜（收到礼物价值排名）
 */
router.get('/charm', auth, async (req, res) => {
    try {
        const { period = 'all', limit = 20 } = req.query;
        
        let dateFilter = '';
        if (period === 'day') {
            dateFilter = "AND gr.created_at >= CURRENT_DATE";
        } else if (period === 'week') {
            dateFilter = "AND gr.created_at >= CURRENT_DATE - INTERVAL '7 days'";
        } else if (period === 'month') {
            dateFilter = "AND gr.created_at >= CURRENT_DATE - INTERVAL '30 days'";
        }
        
        const result = await query(`
            SELECT 
                u.id,
                u.nickname,
                u.avatar,
                u.gender,
                COALESCE(SUM(gr.total_diamonds), 0) as charm_score,
                COUNT(gr.id) as gift_count
            FROM users u
            LEFT JOIN gift_records gr ON u.id = gr.receiver_id ${dateFilter}
            WHERE u.is_banned = false
            GROUP BY u.id
            ORDER BY charm_score DESC
            LIMIT $1
        `, [parseInt(limit)]);
        
        const rankedList = result.rows.map((row, index) => ({
            rank: index + 1,
            ...row,
        }));
        
        return response.success(res, rankedList);
    } catch (error) {
        console.error('Get charm ranking error:', error);
        return response.serverError(res, '获取失败');
    }
});

/**
 * GET /api/rankings/contribution
 * 贡献榜（送出礼物价值排名）
 */
router.get('/contribution', auth, async (req, res) => {
    try {
        const { period = 'all', limit = 20 } = req.query;
        
        let dateFilter = '';
        if (period === 'day') {
            dateFilter = "AND gr.created_at >= CURRENT_DATE";
        } else if (period === 'week') {
            dateFilter = "AND gr.created_at >= CURRENT_DATE - INTERVAL '7 days'";
        } else if (period === 'month') {
            dateFilter = "AND gr.created_at >= CURRENT_DATE - INTERVAL '30 days'";
        }
        
        const result = await query(`
            SELECT 
                u.id,
                u.nickname,
                u.avatar,
                u.gender,
                COALESCE(SUM(gr.total_coins), 0) as contribution_score,
                COUNT(gr.id) as gift_count
            FROM users u
            LEFT JOIN gift_records gr ON u.id = gr.sender_id ${dateFilter}
            WHERE u.is_banned = false
            GROUP BY u.id
            ORDER BY contribution_score DESC
            LIMIT $1
        `, [parseInt(limit)]);
        
        const rankedList = result.rows.map((row, index) => ({
            rank: index + 1,
            ...row,
        }));
        
        return response.success(res, rankedList);
    } catch (error) {
        console.error('Get contribution ranking error:', error);
        return response.serverError(res, '获取失败');
    }
});

/**
 * GET /api/rankings/room
 * 热门房间榜
 */
router.get('/room', auth, async (req, res) => {
    try {
        const { limit = 10 } = req.query;
        
        const result = await query(`
            SELECT 
                r.id,
                r.name,
                r.cover,
                r.description,
                r.current_count,
                r.max_seats,
                u.nickname as owner_nickname,
                u.avatar as owner_avatar,
                COALESCE(SUM(gr.total_diamonds), 0) as total_gifts
            FROM rooms r
            LEFT JOIN users u ON r.owner_id = u.id
            LEFT JOIN gift_records gr ON r.id = gr.room_id
            WHERE r.status = 'active'
            GROUP BY r.id, u.nickname, u.avatar
            ORDER BY r.current_count DESC, total_gifts DESC
            LIMIT $1
        `, [parseInt(limit)]);
        
        return response.success(res, result.rows);
    } catch (error) {
        console.error('Get room ranking error:', error);
        return response.serverError(res, '获取失败');
    }
});

module.exports = router;
