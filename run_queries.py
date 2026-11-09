#!/usr/bin/env python3
"""
codyssey_B6_1 - 전자상거래 DB 실습 실행기

하는 일
  1) (없으면) 실습용 데이터베이스를 만든다.
  2) sql/01_schema.sql      : 테이블 생성
  3) sql/02_sample_data.sql : 샘플 데이터 입력
  4) sql/03_queries.sql     : "-- [Qnn]" 머리줄을 기준으로 쿼리를 하나씩 실행
  5) 결과를 results/ 폴더에 저장
       results/Qnn.txt   쿼리 + 실행 결과 텍스트
       results/Qnn.png   결과 캡처 이미지 (Pillow 와 고정폭 한글 폰트가 있을 때)
       results/RESULTS.md 전체 결과 모음
  6) README.md 의 <!-- RESULTS:START --> ~ <!-- RESULTS:END --> 구간을 최신 결과로 교체

백엔드 프레임워크나 DB 드라이버(psycopg 등) 없이, PostgreSQL 에 포함된 psql 클라이언트만 사용한다.

사용 예
  python run_queries.py
  python run_queries.py --host localhost --port 5432 --user postgres --password postgres --dbname codyssey_shop
  (비밀번호는 환경변수 PGPASSWORD 로 넘겨도 된다)
"""

import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
SQL_DIR = BASE_DIR / "sql"
RESULT_DIR = BASE_DIR / "results"
README_PATH = BASE_DIR / "README.md"

SCHEMA_FILE = SQL_DIR / "01_schema.sql"
DATA_FILE = SQL_DIR / "02_sample_data.sql"
QUERY_FILE = SQL_DIR / "03_queries.sql"

HEADER_RE = re.compile(r"^--\s*\[(Q\d+)]\s*(.+?)\s*\|\s*(.+?)\s*$")
README_START = "<!-- RESULTS:START -->"
README_END = "<!-- RESULTS:END -->"

# 결과 캡처용 고정폭 한글 폰트 후보 (운영체제별)
FONT_CANDIDATES = [
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",       # Linux (Noto Sans Mono CJK KR 포함)
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/nanum/NanumGothicCoding.ttf",
    "C:/Windows/Fonts/D2Coding.ttf",                                # Windows
    "C:/Windows/Fonts/NanumGothicCoding.ttf",
    "/Library/Fonts/D2Coding.ttf",                                  # macOS
    "/Library/Fonts/NanumGothicCoding.ttf",
    os.path.expanduser("~/Library/Fonts/D2Coding.ttf"),
    # 고정폭 폰트가 없을 때의 대안 (글자를 격자에 맞춰 그리므로 표 정렬은 유지됨)
    "C:/Windows/Fonts/malgun.ttf",                                  # Windows 기본 '맑은 고딕'
    "/System/Library/Fonts/AppleSDGothicNeo.ttc",                   # macOS 기본
]
# 고정폭이 아닌 한글 폰트 -> 영문/숫자는 아래 고정폭 폰트로 따로 그린다
PROPORTIONAL_FONTS = {"malgun.ttf", "AppleSDGothicNeo.ttc"}
LATIN_MONO_CANDIDATES = [
    "C:/Windows/Fonts/consola.ttf",                                 # Windows 'Consolas'
    "C:/Windows/Fonts/cour.ttf",                                    # Windows 'Courier New'
    "/System/Library/Fonts/Menlo.ttc",                              # macOS
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",          # Linux
]


# ---------------------------------------------------------------------
# psql 실행
# ---------------------------------------------------------------------
def find_psql():
    """PATH 에서 psql 을 찾고, 없으면 PostgreSQL 기본 설치 폴더(Windows/macOS)를 뒤진다."""
    found = shutil.which("psql")
    if found:
        return found
    patterns = [
        "C:/Program Files/PostgreSQL/*/bin/psql.exe",
        "C:/Program Files (x86)/PostgreSQL/*/bin/psql.exe",
        "/Library/PostgreSQL/*/bin/psql",
        "/Applications/Postgres.app/Contents/Versions/*/bin/psql",
        "/opt/homebrew/opt/postgresql*/bin/psql",
        "/usr/lib/postgresql/*/bin/psql",
    ]
    candidates = []
    for pattern in patterns:
        candidates += glob.glob(pattern)

    def version_key(path):
        m = re.search(r"(\d+)", Path(path).parent.parent.name)
        return int(m.group(1)) if m else 0

    return max(candidates, key=version_key) if candidates else None


class Psql:
    def __init__(self, args):
        self.psql = args.psql or find_psql()
        if not self.psql:
            sys.exit("[오류] psql 을 찾을 수 없습니다. PostgreSQL 을 설치하거나 --psql 로 경로를 지정하세요.")
        print(f"[준비] psql: {self.psql}")
        self.args = args
        self.env = os.environ.copy()
        self.env["PGCLIENTENCODING"] = "UTF8"
        # psql/서버 메시지를 영어로 통일 ("(6 rows)", "ERROR: ...") -> OS 언어와 상관없이 같은 결과
        self.env["LC_ALL"] = "C"
        self.env["LC_MESSAGES"] = "C"
        self.env["LANGUAGE"] = "en"
        self.env["PGOPTIONS"] = "-c lc_messages=C"
        if not args.password:
            # 인자/환경변수로 비밀번호를 안 줬으면 실행할 때 입력받는다
            # (PyCharm 실행 콘솔에서도 동작하도록 input 사용)
            args.password = input(f"PostgreSQL '{args.user}' 계정 비밀번호를 입력하세요: ").strip()
        if args.password:
            self.env["PGPASSWORD"] = args.password

    def _base_cmd(self, dbname):
        return [
            self.psql, "-X",                    # ~/.psqlrc 무시
            "-h", self.args.host, "-p", str(self.args.port),
            "-U", self.args.user, "-d", dbname,
            "-P", "pager=off",
        ]

    def run(self, sql, dbname=None, stop_on_error=False, quiet=False):
        """SQL 문자열을 표준입력으로 넘겨 실행하고 (종료코드, 출력) 을 돌려준다."""
        cmd = self._base_cmd(dbname or self.args.dbname)
        cmd += ["-v", f"ON_ERROR_STOP={1 if stop_on_error else 0}"]
        if quiet:
            cmd.append("-q")
        proc = subprocess.run(
            cmd, input=sql.encode("utf-8"), env=self.env,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        out = decode_output(proc.stdout).replace("psql:<stdin>:", "psql:")
        return proc.returncode, out

    def scalar(self, sql, dbname):
        cmd = self._base_cmd(dbname) + ["-t", "-A", "-c", sql]
        proc = subprocess.run(cmd, env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if proc.returncode != 0:
            sys.exit(f"[오류] DB 접속 실패:\n{decode_output(proc.stderr).strip()}")
        return decode_output(proc.stdout).strip()


def decode_output(data):
    """psql 출력은 데이터(UTF-8)와 Windows 한글 메시지(CP949)가 섞일 수 있어 줄마다 디코딩한다."""
    lines = []
    for raw in (data or b"").replace(b"\r\n", b"\n").split(b"\n"):
        try:
            lines.append(raw.decode("utf-8"))
        except UnicodeDecodeError:
            lines.append(raw.decode("cp949", errors="replace"))
    return "\n".join(lines)


# ---------------------------------------------------------------------
# 쿼리 파일 파싱
# ---------------------------------------------------------------------
def parse_queries(path):
    """03_queries.sql 을 '-- [Qnn] 범주 | 설명' 머리줄 기준으로 나눈다."""
    queries, current = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        m = HEADER_RE.match(line)
        if m:
            current = {"id": m.group(1), "category": m.group(2),
                       "desc": m.group(3), "lines": []}
            queries.append(current)
        elif current is not None:
            current["lines"].append(line)
    for q in queries:
        q["sql"] = "\n".join(q["lines"]).strip()
    return queries


# ---------------------------------------------------------------------
# 결과 캡처 이미지
# ---------------------------------------------------------------------
def find_font(user_font):
    if user_font:
        return user_font if Path(user_font).exists() else None
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return path
    return None


def load_mono_font(path, size):
    from PIL import ImageFont
    if path.endswith(".ttc"):
        # Noto CJK .ttc 안에서 'Mono' + 'KR' 서체를 찾는다
        for idx in range(40):
            try:
                font = ImageFont.truetype(path, size, index=idx)
            except OSError:
                break
            family, _ = font.getname()
            if "Mono" in family and "KR" in family:
                return font
    return ImageFont.truetype(path, size)


def cell_width(ch):
    """psql 처럼 한글 등 전각 문자는 2칸, 나머지는 1칸으로 센다."""
    return 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1


def load_fonts(font_path, size):
    """(영문용 폰트, 한글용 폰트) 를 돌려준다.
    고정폭 한글 폰트(D2Coding, Noto Mono CJK 등)면 둘 다 같은 폰트를 쓰고,
    맑은 고딕처럼 고정폭이 아닌 폰트면 영문/숫자는 시스템 고정폭 폰트로 그린다."""
    wide = load_mono_font(font_path, size)
    if Path(font_path).name not in PROPORTIONAL_FONTS:
        return wide, wide
    for path in LATIN_MONO_CANDIDATES:
        if Path(path).exists():
            try:
                from PIL import ImageFont
                return ImageFont.truetype(path, size), wide
            except OSError:
                continue
    return wide, wide


def draw_grid_text(draw, x, y, text, fonts, cell_w, fill):
    """글자마다 격자 위치에 그려서 psql 표의 세로줄이 어긋나지 않게 한다."""
    latin, wide = fonts
    baseline = y + max(latin.getmetrics()[0], wide.getmetrics()[0])  # 두 폰트의 기준선을 맞춘다
    col = 0
    for ch in text:
        w = cell_width(ch)
        draw.text((x + col * cell_w, baseline), ch, fill=fill,
                  font=wide if w == 2 else latin, anchor="ls")
        col += w


def render_png(text, title, out_path, font_path):
    from PIL import Image, ImageDraw
    fonts = load_fonts(font_path, 15)
    title_fonts = load_fonts(font_path, 17)
    lines = text.rstrip("\n").split("\n")
    pad, line_h = 24, 22
    probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))

    def grid_width(fs):
        # 한 칸 = 영문 고정폭 글자 폭, 단 한글 1자(2칸)가 들어갈 만큼은 확보
        return max(probe.textlength("0", font=fs[0]), probe.textlength("가", font=fs[1]) / 2)

    cell_w = grid_width(fonts)
    title_cell_w = grid_width(title_fonts)
    cols = max(sum(cell_width(c) for c in l) for l in lines)
    title_cols = sum(cell_width(c) for c in title)
    width = max(cols * cell_w, title_cols * title_cell_w)
    img_w = int(width) + pad * 2
    img_h = pad * 2 + 36 + line_h * len(lines)
    img = Image.new("RGB", (img_w, img_h), "#1e1f24")
    draw = ImageDraw.Draw(img)
    draw_grid_text(draw, pad, pad, title, title_fonts, title_cell_w, "#8fd3ff")
    y = pad + 36
    for line in lines:
        if line.startswith("--") or line.startswith("SQL>"):
            color = "#9aa0a6"
        elif "ERROR" in line or "오류" in line:
            color = "#ff7b72"
        else:
            color = "#e6e6e6"
        draw_grid_text(draw, pad, y, line, fonts, cell_w, color)
        y += line_h
    img.save(out_path)


# ---------------------------------------------------------------------
# 메인 흐름
# ---------------------------------------------------------------------
def ensure_database(psql, dbname):
    exists = psql.scalar(f"SELECT 1 FROM pg_database WHERE datname = '{dbname}'", "postgres")
    if exists != "1":
        print(f"[준비] 데이터베이스 '{dbname}' 생성")
        code, out = psql.run(f'CREATE DATABASE "{dbname}" ENCODING \'UTF8\' TEMPLATE template0;',
                             dbname="postgres", stop_on_error=True)
        if code != 0:
            sys.exit(out)


def run_setup_file(psql, path):
    code, out = psql.run(path.read_text(encoding="utf-8"), stop_on_error=True, quiet=True)
    if code != 0:
        sys.exit(f"[오류] {path.name} 실행 실패\n{out}")
    print(f"[완료] {path.name}")


def table_counts(psql):
    sql = """
SELECT 'member' AS table_name, COUNT(*) AS row_count FROM member
UNION ALL SELECT 'category',   COUNT(*) FROM category
UNION ALL SELECT 'product',    COUNT(*) FROM product
UNION ALL SELECT 'orders',     COUNT(*) FROM orders
UNION ALL SELECT 'order_item', COUNT(*) FROM order_item
UNION ALL SELECT 'review',     COUNT(*) FROM review;"""
    _, out = psql.run(sql)
    return out.rstrip()


def update_readme(markdown):
    if not README_PATH.exists():
        return False
    text = README_PATH.read_text(encoding="utf-8")
    if README_START not in text or README_END not in text:
        return False
    head, rest = text.split(README_START, 1)
    _, tail = rest.split(README_END, 1)
    README_PATH.write_text(f"{head}{README_START}\n{markdown}\n{README_END}{tail}", encoding="utf-8")
    return True


def main():
    parser = argparse.ArgumentParser(description="전자상거래 DB 실습 SQL 실행 및 결과 저장")
    parser.add_argument("--host", default=os.environ.get("PGHOST", "localhost"))
    parser.add_argument("--port", default=os.environ.get("PGPORT", "5432"))
    parser.add_argument("--user", default=os.environ.get("PGUSER", "postgres"))
    parser.add_argument("--password", default=os.environ.get("PGPASSWORD"))
    parser.add_argument("--dbname", default=os.environ.get("PGDATABASE", "codyssey_shop"))
    parser.add_argument("--psql", help="psql 실행 파일 경로 (PATH 에 없을 때)")
    parser.add_argument("--font", help="결과 캡처에 쓸 고정폭 한글 폰트(.ttf/.ttc) 경로")
    parser.add_argument("--no-image", action="store_true", help="PNG 캡처를 만들지 않음")
    parser.add_argument("--no-readme", action="store_true", help="README.md 결과 구간을 갱신하지 않음")
    args = parser.parse_args()

    psql = Psql(args)
    ensure_database(psql, args.dbname)

    # 1~2) 스키마 + 샘플 데이터 (매번 초기 상태로 다시 만든다)
    run_setup_file(psql, SCHEMA_FILE)
    run_setup_file(psql, DATA_FILE)

    # 3) 이미지 캡처 준비
    font_path = None
    if not args.no_image:
        try:
            import PIL  # noqa: F401
            font_path = find_font(args.font)
            if not font_path:
                print("[안내] 고정폭 한글 폰트를 찾지 못해 PNG 캡처는 건너뜁니다. (--font 로 지정 가능)")
        except ImportError:
            print("[안내] Pillow 가 없어 PNG 캡처는 건너뜁니다. (pip install pillow)")

    RESULT_DIR.mkdir(exist_ok=True)
    for old in RESULT_DIR.glob("Q*.*"):
        old.unlink()

    # 4) 행 수 확인
    counts = table_counts(psql)
    (RESULT_DIR / "00_table_counts.txt").write_text(counts + "\n", encoding="utf-8")
    if font_path:
        render_png(counts, "[Q00] 샘플 데이터 행 수 확인", RESULT_DIR / "00_table_counts.png", font_path)

    md = ["### 샘플 데이터 행 수", "", "```text", counts, "```", ""]

    # 5) 쿼리 실행
    queries = parse_queries(QUERY_FILE)
    for q in queries:
        _, out = psql.run(q["sql"])
        out = out.rstrip()
        title = f"[{q['id']}] {q['category']} | {q['desc']}"
        body = f"{q['sql']}\n\n-- 실행 결과 --------------------------------\n{out}"
        (RESULT_DIR / f"{q['id']}.txt").write_text(f"-- {title}\n\n{body}\n", encoding="utf-8")
        if font_path:
            render_png(body, title, RESULT_DIR / f"{q['id']}.png", font_path)

        md += [f"### {q['id']}. {q['desc']}", "",
               f"- 범주: **{q['category']}**",
               f"- 쿼리/결과 파일: `results/{q['id']}.txt`"
               + (f", 캡처: `results/{q['id']}.png`" if font_path else ""), "",
               "```sql", q["sql"], "```", "", "실행 결과", "", "```text", out, "```", ""]
        print(f"[실행] {q['id']} {q['category']} - {q['desc']}")

    markdown = "\n".join(md).rstrip()
    (RESULT_DIR / "RESULTS.md").write_text("# 쿼리 실행 결과\n\n" + markdown + "\n", encoding="utf-8")
    print(f"[저장] {RESULT_DIR}")

    if not args.no_readme and update_readme(markdown):
        print("[저장] README.md 실행 결과 구간 갱신")


if __name__ == "__main__":
    main()
