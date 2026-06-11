# Olist巴西电商平台SQL数据分析项目
## 项目介绍
基于Olist巴西电商平台2016-2018年真实经营数据，使用MySQL+Python完成全链路数据分析，包含运营大盘、订单趋势、用户分层、商品分析、物流时效五大模块，输出可落地业务优化建议。

## 技术栈
- 数据库：MySQL 8.0
- 数据处理：Python + Pandas + SQLAlchemy
- 可视化：Matplotlib
- 分析方法：多表联查、CTE公共表达式、窗口函数、RFM用户价值模型

## 项目运行步骤
1.  安装依赖：
    ```bash
    pip install -r requirements.txt
2.本地安装 MySQL 8.0，创建数据库
sql
CREATE DATABASE olist_ecommerce DEFAULT CHARACTER SET utf8mb4;
3.修改import_olist.py中的数据库密码和 CSV 文件路径，运行脚本导入数据
4.执行sql/core_analysis.sql中的 SQL 语句，生成所有分析结果
5.运行visual_analysis.py生成三张可视化图表

核心分析结论：
1.平台总交易额 1541.98 万元，订单完成率 97.02%，但用户复购率仅 3%
2.信用卡是主流支付方式，贡献 81.34% 营收
3.圣保罗州用户占比 41.94%，贡献超 37% 平台营收
4.家居、美妆、运动是三大核心类目，美妆健康盈利能力最强
5.仅 39.2% 的中高价值用户贡献了 71.77% 的营收，用户分层运营空间巨大

项目结构：
├── sql/ # SQL 建表与分析脚本
├── images/ # 可视化图表
├── data/ # 分析结果 CSV 文件
├── import_olist.py # 数据批量导入脚本
├── visual_analysis.py # 可视化绘图脚本
├── requirements.txt # 依赖包列表
└── README.md