# HIU 语音房 App

一款以语音房为核心的社交直播App，支持多人语音聊天、1对1私密社交、虚拟礼物打赏等功能。面向海外市场，计划上架 Google Play。

## 📁 项目结构

```
PoppoApp/
├── backend/              # Node.js + Express 后端
│   ├── src/
│   │   ├── config/      # 配置文件
│   │   ├── middleware/   # 中间件 (JWT认证等)
│   │   ├── models/      # 数据库模型
│   │   ├── routes/      # API路由
│   │   ├── services/     # 业务服务
│   │   ├── socket/       # Socket.IO处理器
│   │   ├── utils/        # 工具函数
│   │   └── app.js        # 入口文件
│   ├── scripts/          # 数据库初始化脚本
│   ├── docs/             # 数据库Schema
│   ├── package.json
│   └── README.md
│
├── frontend/            # Flutter 前端
│   ├── lib/
│   │   └── src/
│   │       ├── models/   # 数据模型
│   │       ├── pages/    # 页面
│   │       ├── providers/ # 状态管理
│   │       ├── services/  # API服务
│   │       └── main.dart  # 入口文件
│   ├── pubspec.yaml
│   └── android/         # Android配置
│
├── admin/               # 管理员后台 (Web)
│   └── index.html       # 单页应用
│
└── docs/                # 文档
    └── schema.sql       # 数据库Schema
```

## 🚀 快速开始

### 1. 数据库设置

```bash
# 启动 PostgreSQL
docker run -d --name postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=hiu_app -p 5432:5432 postgres

# 初始化数据库
cd backend
npm install
cp .env.example .env
npm run init-db
```

### 2. 启动后端

```bash
cd backend
npm start
# 服务运行在 http://localhost:3000
```

### 3. 启动 Flutter App

```bash
cd frontend
flutter pub get
flutter run
```

### 4. 打开管理后台

直接在浏览器打开 `admin/index.html`

## 🔐 测试账号

| 账号 | 密码 | 角色 | 说明 |
|------|------|------|------|
| A100001 | admin123 | 管理员 | 最高权限 |
| AG001 | agent123 | 代理 | 分配密码: dist123 |
| H100001 | host123 | 主播(女) | 1000钻石 |
| U100001 | user123 | 用户(男) | 5000金币 |

## ✨ 功能特性

### 核心功能
- ✅ 自动注册，生成账号密码
- ✅ 邮箱绑定
- ✅ 语音房创建/加入/上麦下麦
- ✅ 8人麦位布局
- ✅ 文字聊天
- ✅ 礼物打赏 (金币→钻石)
- ✅ 1对1私聊
- ✅ 异性聊天收费
- ✅ 视频通话 (MVP可用)
- ✅ 代理金币分发
- ✅ 钻石提现申请

### 管理员功能
- ✅ 用户管理 (禁用/启用)
- ✅ 代理管理 (创建/分配金币)
- ✅ 提现审核
- ✅ 汇率设置
- ✅ 房间管理
- ✅ 礼物管理

## 📱 技术栈

| 模块 | 技术 |
|------|------|
| 前端 | Flutter |
| 后端 | Node.js + Express |
| 数据库 | PostgreSQL |
| 实时通信 | Socket.IO |
| 语音/视频 | Agora SDK |
| 状态管理 | Provider |

## 📦 API 文档

### 认证模块 `/api/auth`
- `POST /register` - 自动注册
- `POST /login` - 登录
- `POST /refresh` - 刷新Token
- `POST /bind-email` - 绑定邮箱
- `GET /me` - 获取当前用户

### 用户模块 `/api/users`
- `GET /profile` - 获取个人资料
- `PUT /profile` - 更新个人资料
- `PUT /pricing` - 设置聊天定价
- `PUT /gender/:userId` - 修改性别
- `PUT /ban/:userId` - 禁用/启用用户

### 房间模块 `/api/rooms`
- `GET /` - 获取房间列表
- `POST /` - 创建房间
- `POST /:roomId/join` - 加入房间
- `POST /:roomId/leave` - 离开房间
- `POST /:roomId/seat/:index/join` - 上麦
- `POST /:roomId/seat/:index/leave` - 下麦
- `POST /:roomId/seat/:index/kick` - 踢人下麦

### 礼物模块 `/api/gifts`
- `GET /` - 获取礼物列表
- `POST /:giftId/send` - 发送礼物

### 金币模块 `/api/coins`
- `GET /balance` - 获取金币余额
- `POST /distribute` - 代理分发金币
- `POST /admin/allocate` - 管理员分配金币

### 钻石模块 `/api/diamonds`
- `GET /balance` - 获取钻石余额
- `POST /withdraw` - 申请提现
- `PUT /withdraw/:id/approve` - 审核通过
- `PUT /withdraw/:id/reject` - 审核拒绝

### 1对1聊天 `/api/chat`
- `GET /conversations` - 获取会话列表
- `GET /messages/:userId` - 获取聊天记录
- `POST /send` - 发送消息

### 视频通话 `/api/video`
- `POST /call` - 发起通话
- `PUT /call/:id/accept` - 接听
- `PUT /call/:id/end` - 结束通话

## 🔌 Socket.IO 事件

### 客户端 → 服务器
- `join_room` - 加入房间
- `leave_room` - 离开房间
- `chat_message` - 发送消息
- `seat_update` - 麦位更新
- `gift_sent` - 发送礼物

### 服务器 → 客户端
- `user_joined` - 用户加入
- `user_left` - 用户离开
- `chat_message` - 新消息
- `seat_update` - 麦位更新
- `gift_received` - 收到礼物
- `user_kicked` - 被踢

## 📝 开发说明

### 环境变量配置

```env
# 数据库
DB_HOST=localhost
DB_PORT=5432
DB_NAME=hiu_app
DB_USER=postgres
DB_PASSWORD=postgres

# JWT
JWT_SECRET=your-secret-key

# 声网 (可选)
AGORA_APP_ID=your-agora-app-id
AGORA_APP_CERTIFICATE=your-agora-certificate
```

### 数据库迁移

```bash
# 初始化
npm run init-db

# 或手动执行
psql -h localhost -U postgres -d hiu_app -f ../docs/schema.sql
```

## 📄 License

MIT License
