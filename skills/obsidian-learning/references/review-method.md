# 复习方法

目标：用检索练习与间隔排期把记忆固化成长期存储，而不是靠反复阅读制造"我懂了"
的流畅错觉。

## 检索练习（先回忆，再核对）

1. 复习时先合上资料，尝试回忆答案 / 复述要点。
2. 写下回忆结果（一句话即可，写不出来也算数，不能偷看）。
3. 展开答案 Callout 核对，记录对错与信心（回忆强度）。

Karpicke & Roediger (2008, _Science_) 的实验表明：反复阅读对长期保留帮助有限，
而主动检索练习显著提升一周后的保留率[^retrieval]。

[^retrieval]: Karpicke, J. D. & Roediger, H. L. (2008). The critical importance of retrieval for learning. _Science_, 319(5865), 966–968. <https://doi.org/10.1126/science.1152408>

## 间隔排期

默认间隔（可随表现调整）：

| 复习次数 | 距上次间隔 |
| --- | --- |
| 第 1 次 | 当天或次日 |
| 第 2 次 | +3 天 |
| 第 3 次 | +7 天 |
| 第 4 次 | +21 天 |
| 第 5 次 | +60 天 |

每次复习后：

- 回忆失败或信心低 → 间隔减半，回到更早的阶段。
- 顺利回忆且信心高 → 按表推进或拉长。

Cepeda et al. (2006, _Psychological Bulletin_) 对 254 项研究的元分析确认：
间隔练习优于集中练习，且存在"最有利间隔"——过长会遗忘，过短收益递减[^spacing]。

[^spacing]: Cepeda, N. J., Pashler, H., Vul, E., Wixted, J. T. & Rohrer, D. (2006). Distributed practice in verbal recall tasks: A review and quantitative synthesis. _Psychological Bulletin_, 132(3), 354–380. <https://doi.org/10.1037/0033-2909.132.3.354>

## 在笔记里落地

```yaml
---
type: learning-record
mastery: 2
evidence: "[[practice-003-dma-实验]]"
review_after: 2024-01-18
---
```

- `review_after` 写在 `concept` / `lesson` / `learning-record` 上，取当前日期 + 间隔。
- 复习结果记入 `learning-record`：当场结论、信心、下次日期。
- **只有检索或实践证据支持才提升 `mastery`**；"读过一遍"不改变状态。

## 防遗忘要点

- 一次复习不要贪多：3–5 条概念 / 1 课，够了就停。
- 复习内容交错进行（不同课程的卡片混在一起），比按顺序更能暴露知识缺口。
- 复习中出现的新疑问，单独开 Question 或直接更新对应概念笔记，不塞进复习记录。
