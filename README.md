# Verify_WRF-Chem
Verify the output from WRF-Chem model

脚本目的：验证WRF-Chem模型气象（风速和温度）和化学（PM2.5浓度）模拟结果
脚本语言：NCL
脚本实现步骤：选取站点——>读取测量数据——>读取模式模拟数据——>绘图（时间序列图+散点图（单个站点和所有站点））——>计算模拟和实测之间的统计量（如相关系数R等）
