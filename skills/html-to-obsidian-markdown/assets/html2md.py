#!/usr/bin/env python3
"""将 V4L2 课程 HTML 转为 Obsidian 友好的 Markdown。
处理：标题(h1 抑制)、段落(<b>/<code>/<a>)、callout、pre 代码块、表格、自测题、列表、hr。
输出：同名 .md，带 YAML frontmatter 与课程序号标签。"""
import re
import sys
from html.parser import HTMLParser

COURSE_TITLES = {
    "0001": "V4L2 子系统架构总览",
    "0002": "v4l2_subdev 与三组 ops",
    "0003": "probe → async → s_stream 调用链",
    "0004": "DTS ↔ media controller ↔ pipeline 拓扑",
    "0005": "video_device / rkisp_stream / vb2 队列包含链",
    "0006": "图像格式链（格式协商）",
    "0007": "v4l2 控件与 imx415 寄存器",
    "0008": "MIPI CSI-2 与 DPHY 物理数据流",
    "0009": "vb2 buffer 生命周期（帧流）",
    "0010": "mmap / USERPTR / DMABUF 与零拷贝",
    "0011": "IPC 实战零拷贝优化清单",
    "0012": "调试与测量：全生命周期回顾",
    "0013": "内核模块结构与加载顺序",
}

COURSE_ORDER = [
    "v4l2-architecture-overview", "v4l2-subdev-ops", "probe-async-s_stream",
    "dts-media-controller-topology", "video-device-vb2-queue", "image-format-chain",
    "v4l2-controls-imx415", "mipi-csi2-dphy", "vb2-buffer-lifecycle",
    "mm-zerocopy-dmabuf", "ipc-zero-copy-optimization", "debug-measurement-lifecycle",
    "ko-structure-loading-order",
]

INLINE_TAGS = {"b", "strong", "code", "em", "i"}

class Converter(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.stack = []          # 当前段落/行内的 inline 片段
        self.skip_depth = 0
        self.in_pre = False
        self.pre_buf = []
        self.skip_h1 = False
        # callout
        self.callout_depth = 0
        self.callout_type = "note"
        # quiz
        self.quiz_depth = 0
        self.quiz = None
        self.btn_answer = None
        self.btn_text = None
        # table
        self.table = None
        self.table_row = None
        self.table_cell = None
        # list
        self.list_stack = []

    # ---------- output helpers ----------
    def flush_inline(self):
        if self.stack:
            text = "".join(self.stack)
            # 段落内换行折叠为空格
            text = re.sub(r"\s+", " ", text).strip()
            if text:
                self.out.append(text + " ")
            self.stack = []

    def emit(self, s=""):
        if not self.in_pre:
            self.out.append(s)

    def is_ignoring_inline(self):
        return self.table is not None or self.quiz_depth > 0 or self.in_pre

    # ---------- start tags ----------
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        cls = a.get("class", "")
        if tag == "script":
            self.skip_depth += 1
            return
        if tag == "head":
            self.skip_depth += 1
            return
        if self.skip_depth:
            return
        if tag == "h1":
            self.skip_h1 = True
            return
        if tag == "pre":
            self.in_pre = True
            self.pre_buf = []
            return
        if tag == "div" and "callout" in cls:
            self.callout_depth = 1
            self.callout_type = a.get("data-type", "note")
            title = a.get("data-title", "")
            self.flush_inline()
            self.out.append("\n> [!%s] %s\n" % (self.callout_type, title))
            return
        if tag == "div" and "quiz" in cls:
            self.quiz_depth = 1
            self.quiz = {"q": [], "options": [], "correct": a.get("data-correct"),
                         "correct_fb": a.get("data-correct-feedback", ""),
                         "wrong_fb": a.get("data-wrong-feedback", "")}
            self.flush_inline()
            self.out.append("\n### 自测题\n")
            return
        if tag == "div":
            if self.quiz_depth > 0:
                self.quiz_depth += 1
            if self.callout_depth > 0:
                self.callout_depth += 1
            return
        if tag == "button" and self.quiz_depth > 0:
            self.btn_answer = a.get("data-answer")
            self.btn_text = []
            return
        if tag == "table":
            self.table = []
            self.table_row = None
            self.table_cell = None
            self.flush_inline()
            return
        if tag == "tr":
            self.table_row = []
            return
        if tag in ("td", "th"):
            self.table_cell = []
            return
        if tag in ("ul", "ol"):
            self.flush_inline()
            self.list_stack.append((tag, 0))
            self.out.append("\n")
            return
        if tag == "li":
            self.flush_inline()
            t, n = self.list_stack[-1]
            self.list_stack[-1] = (t, n + 1)
            self.out.append(("-" if t == "ul" else f"{n + 1}. ") + " ")
            return
        if tag == "br":
            self.out.append("\n")
            return
        if tag == "hr":
            self.flush_inline()
            self.out.append("\n---\n")
            return
        if tag == "h2" or tag == "h3":
            if self.quiz_depth > 0:
                return
            self.flush_inline()
            self.out.append("\n" + "#" * int(tag[1]) + " ")
            return
        if tag == "p":
            self.flush_inline()
            self.out.append("\n\n")
            return
        if tag in INLINE_TAGS:
            if self.is_ignoring_inline():
                return
            self.stack.append("*" if tag in ("em", "i") else "`" if tag == "code" else "**")
            return
        if tag == "a":
            href = a.get("href", "")
            if href.startswith("http"):
                self.stack.append("[")
                self._link_href = href
            # 本地路径：只保留锚文本，丢弃不可解析的路径
            return

    # ---------- end tags ----------
    def handle_endtag(self, tag):
        if tag == "script":
            self.skip_depth = max(0, self.skip_depth - 1)
            return
        if tag == "head":
            self.skip_depth = max(0, self.skip_depth - 1)
            return
        if self.skip_depth:
            return
        if tag == "h1":
            self.skip_h1 = False
            return
        if tag == "pre" and self.in_pre:
            self.in_pre = False
            code = "".join(self.pre_buf).strip("\n")
            self.out.append("\n```\n" + code + "\n```\n")
            return
        if tag == "div" and self.callout_depth > 0:
            self.callout_depth -= 1
            if self.callout_depth == 0:
                self.out.append("\n")
            return
        if tag == "div" and self.quiz_depth > 0:
            self.quiz_depth -= 1
            if self.quiz_depth == 0:
                self._emit_quiz()
            return
        if tag == "button" and self.btn_text is not None:
            text = "".join(self.btn_text).strip()
            self.quiz["options"].append((text, self.btn_answer))
            self.btn_text = None
            self.btn_answer = None
            return
        if tag == "table":
            self._emit_table()
            self.table = None
            return
        if tag == "tr":
            if self.table_row:
                self.table.append(self.table_row)
                self.table_row = None
            return
        if tag in ("td", "th"):
            self.table_row.append("".join(self.table_cell).strip())
            self.table_cell = None
            return
        if tag in ("ul", "ol"):
            self.flush_inline()
            if self.list_stack:
                self.list_stack.pop()
            self.out.append("\n")
            return
        if tag in ("h2", "h3"):
            if self.quiz_depth > 0:
                return
            self.flush_inline()
            self.out.append("\n")
            return
        if tag == "li":
            self.flush_inline()
            self.out.append("\n")
            return
        if tag == "p":
            self.flush_inline()
            return
        if tag in INLINE_TAGS:
            if self.is_ignoring_inline():
                return
            self.stack.append("*" if tag in ("em", "i") else "`" if tag == "code" else "**")
            return
        if tag == "a":
            if getattr(self, "_link_href", None):
                self.stack.append("](%s)" % self._link_href)
                self._link_href = None
            return

    # ---------- data ----------
    def handle_data(self, data):
        if self.skip_depth or self.skip_h1:
            return
        if self.in_pre:
            self.pre_buf.append(data)
            return
        if self.quiz_depth > 0:
            if self.btn_text is not None:
                self.btn_text.append(data)
            else:
                self.quiz["q"].append(data)
            return
        if self.table is not None:
            if self.table_cell is not None and data.strip():
                self.table_cell.append(data)
            return
        if self.stack:
            self.stack.append(data)
        elif data.strip():
            self.out.append(data)

    # ---------- quiz ----------
    def _emit_quiz(self):
        q = self.quiz
        if not q:
            return
        question = re.sub(r"\s+", " ", "".join(q["q"])).strip()
        self.out.append(question + "\n\n")
        for text, ans in q["options"]:
            mark = " ✅" if ans == q["correct"] else ""
            self.out.append("- [ ] %s%s\n" % (text, mark))
        self.out.append("\n> [!success]- 答案与解析\n")
        self.out.append("> 正确选项：`%s`\n" % q["correct"])
        if q["correct_fb"]:
            self.out.append("> ✅ %s\n" % q["correct_fb"].strip())
        if q["wrong_fb"]:
            self.out.append("> ❌ 选错提示：%s\n" % q["wrong_fb"].strip())
        self.out.append("\n")
        self.quiz = None

    # ---------- table ----------
    def _emit_table(self):
        if not self.table:
            return
        rows = self.table
        ncols = max(len(r) for r in rows)
        # header
        header = [c for c in rows[0]]
        while len(header) < ncols:
            header.append("")
        self.out.append("\n| %s |\n" % " | ".join(c.replace("|", "\\|") for c in header))
        self.out.append("| %s |\n" % " | ".join("---" for _ in range(ncols)))
        for row in rows[1:]:
            cells = [c.replace("|", "\\|") for c in row]
            while len(cells) < ncols:
                cells.append("")
            self.out.append("| %s |\n" % " | ".join(cells))
        self.out.append("\n")

    def get_text(self):
        return "".join(self.out)

def main(path):
    with open(path, encoding="utf-8") as f:
        content = f.read()
    c = Converter()
    c.feed(content)
    body = c.get_text()
    body = re.sub(r"\n{3,}", "\n\n", body).strip()

    base = path.split("/")[-1].replace(".html", "")
    num = int(base.split("-")[0])
    title = COURSE_TITLES.get(base.split("-")[0], base)
    display = f"第 {num} 课 · {title}"
    fm = (
        "---\n"
        "tags: [v4l2, course, learning]\n"
        f"title: {display}\n"
        "---\n\n"
    )
    # 课程导航（上一篇 / 下一篇 / 返回地图）
    nav = []
    if num > 1:
        prev_n = num - 1
        nav.append(f"[[{prev_n:04d}-{COURSE_ORDER[prev_n - 1]}|← 第 {prev_n} 课]]")
    nav.append("[[../_MOC|V4L2 课程地图]]")
    if num < len(COURSE_ORDER):
        next_n = num + 1
        nav.append(f"[[{next_n:04d}-{COURSE_ORDER[next_n - 1]}|第 {next_n} 课 →]]")
    footer = "\n---\n" + " · ".join(nav) + "\n"

    md = fm + "# " + display + "\n\n" + body + "\n" + footer
    out_path = path.replace(".html", ".md")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(md)
    print(f"已转换: {out_path}")

if __name__ == "__main__":
    main(sys.argv[1])
