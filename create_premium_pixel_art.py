from PIL import Image
import os

def create_banner(filename, pixel_data, colors, pixel_size=6):
    height = len(pixel_data)
    width = len(pixel_data[0])
    
    for i, row in enumerate(pixel_data):
        if len(row) != width:
            print(f"ERROR: row {i} has {len(row)} cols, expected {width}")
            return
    
    img = Image.new('RGB', (width * pixel_size, height * pixel_size))
    
    for y, row in enumerate(pixel_data):
        for x, color_idx in enumerate(row):
            if color_idx != 0:
                color = colors.get(color_idx, (255, 255, 255))
                for py in range(pixel_size):
                    for px in range(pixel_size):
                        img.putpixel((x * pixel_size + px, y * pixel_size + py), color)
    
    img.save(filename)
    print(f"已保存: {filename} ({width}x{height} = {width*pixel_size}x{height*pixel_size}px)")

# ==================== 人工智能：未来科技城市 ====================
ai_c = {
    0: (0, 0, 0),
    1: (10, 14, 28),
    2: (18, 25, 45),
    3: (30, 45, 70),
    4: (45, 65, 100),
    5: (65, 95, 145),
    6: (0, 220, 255),
    7: (0, 255, 180),
    8: (255, 80, 140),
    9: (255, 210, 60),
    10: (190, 200, 220),
    11: (90, 100, 130),
    12: (20, 28, 50),
    13: (35, 50, 80),
    14: (0, 160, 220),
    15: (180, 190, 210),
    16: (110, 120, 145),
    17: (255, 140, 40),
    18: (80, 180, 255),
    19: (0, 100, 60),
    20: (255, 255, 255),
    21: (40, 80, 60),
    22: (60, 120, 90),
    23: (30, 60, 100),
}

W = 80
H = 45

ai_data = []
# Rows 0-5: night sky with stars and distant buildings
for r in range(H):
    row = [1] * W
    ai_data.append(row)

# Sky gradient
for x in range(W):
    ai_data[0][x] = 1
    ai_data[1][x] = 1
    ai_data[2][x] = 1
    ai_data[3][x] = 2 if x % 12 != 0 else 9
    ai_data[4][x] = 2
    ai_data[5][x] = 2

# Stars
stars = [(5,1),(15,0),(28,2),(42,1),(55,0),(68,2),(75,1),(10,3),(35,3),(60,3)]
for sx, sy in stars:
    if sx < W and sy < H:
        ai_data[sy][sx] = 9

# Distant buildings silhouette (rows 6-12)
for x in range(W):
    ai_data[6][x] = 3
    ai_data[7][x] = 3
    ai_data[8][x] = 4 if (x % 7 < 4) else 3
    ai_data[9][x] = 4
    ai_data[10][x] = 4
    ai_data[11][x] = 5 if (x % 5 < 3) else 4
    ai_data[12][x] = 5

# Tall building left (cols 5-14, rows 6-30)
for r in range(6, 31):
    for c in range(5, 15):
        ai_data[r][c] = 4
# Windows on left building
for r in range(8, 28, 3):
    for c in range(7, 13, 2):
        if r < H and c < W:
            ai_data[r][c] = 6 if (r + c) % 4 == 0 else 10

# Central AI tower (cols 28-52, rows 6-35) - main focus
for r in range(6, 36):
    for c in range(28, 53):
        ai_data[r][c] = 5

# Tower top antenna
for r in range(3, 8):
    ai_data[r][38] = 6
    ai_data[r][39] = 6
    ai_data[r][40] = 6
    ai_data[r][41] = 6
    ai_data[r][42] = 6

# Tower windows grid
for r in range(9, 33, 2):
    for c in range(30, 51, 3):
        if r < H and c + 1 < W:
            ai_data[r][c] = 6
            ai_data[r][c+1] = 10

# Neural network lines on tower
for r in range(15, 28):
    for c in range(30, 51):
        if (r + c) % 7 == 0 and r < H and c < W:
            ai_data[r][c] = 7

# AI core glow center of tower
for r in range(18, 25):
    for c in range(36, 45):
        if r < H and c < W:
            dist = abs(r - 21) + abs(c - 40)
            if dist < 5:
                ai_data[r][c] = 8
            elif dist < 7:
                ai_data[r][c] = 6

# Right building (cols 60-74, rows 8-28)
for r in range(8, 29):
    for c in range(60, 75):
        ai_data[r][c] = 4
# Windows on right building
for r in range(10, 27, 3):
    for c in range(62, 73, 2):
        if r < H and c < W:
            ai_data[r][c] = 10 if (r * 3 + c) % 5 != 0 else 18

# Far right building (cols 68-78, rows 12-26)
for r in range(12, 27):
    for c in range(68, min(79, W)):
        ai_data[r][c] = 3

# Left small building (cols 18-25, rows 10-25)
for r in range(10, 26):
    for c in range(18, 26):
        ai_data[r][c] = 3
for r in range(12, 24, 2):
    for c in range(19, 25, 2):
        if r < H and c < W:
            ai_data[r][c] = 9 if (r + c) % 3 == 0 else 11

# Data streams / flowing particles
for r in range(14, 34):
    for c in range(W):
        if r < H:
            if (r * 3 + c * 7) % 23 == 0:
                ai_data[r][c] = 14

# Ground level (rows 35-39)
for r in range(35, 40):
    for c in range(W):
        ai_data[r][c] = 12 if r == 35 else 13

# Road markings
for c in range(0, W, 6):
    for cc in range(c, min(c+3, W)):
        ai_data[37][cc] = 9

# Robot on ground (cols 18-25, rows 37-44)
robot_body = [
    [0,0,0,15,15,0,0,0],
    [0,0,15,6,6,15,0,0],
    [0,0,15,9,9,15,0,0],
    [0,15,15,15,15,15,15,0],
    [0,15,16,15,15,16,15,0],
    [0,15,15,15,15,15,15,0],
    [0,15,15,15,15,15,15,0],
    [0,0,15,0,0,15,0,0],
    [0,0,15,0,0,15,0,0],
]
for ry, brow in enumerate(robot_body):
    for rx, bv in enumerate(brow):
        r, c = 37 + ry, 18 + rx
        if r < H and c < W and bv != 0:
            ai_data[r][c] = bv

# Small robot right (cols 60-65, rows 38-44)
robot2 = [
    [0,15,15,0],
    [15,6,6,15],
    [15,9,9,15],
    [15,15,15,15],
    [0,15,15,0],
    [0,15,15,0],
    [0,15,15,0],
]
for ry, brow in enumerate(robot2):
    for rx, bv in enumerate(brow):
        r, c = 38 + ry, 62 + rx
        if r < H and c < W and bv != 0:
            ai_data[r][c] = bv

# Neon signs on buildings
# "AI" text on central tower
ai_text = [
    [6,6,0,6,6],
    [6,0,6,0,6],
    [6,0,6,0,6],
    [6,0,0,0,6],
    [6,0,6,0,6],
]
for ry, brow in enumerate(ai_text):
    for rx, bv in enumerate(brow):
        r, c = 14 + ry, 37 + rx
        if r < H and c < W and bv != 0:
            ai_data[r][c] = bv

# Ensure all rows are exactly W wide
for i in range(len(ai_data)):
    while len(ai_data[i]) < W:
        ai_data[i].append(1)
    ai_data[i] = ai_data[i][:W]

# ==================== 开源社区：代码协作界面 ====================
oc = {
    0: (0, 0, 0),
    1: (25, 28, 38),
    2: (38, 42, 55),
    3: (52, 58, 72),
    4: (68, 75, 92),
    5: (0, 200, 100),
    6: (220, 60, 60),
    7: (255, 210, 50),
    8: (80, 160, 240),
    9: (200, 210, 230),
    10: (140, 150, 170),
    11: (170, 80, 200),
    12: (0, 210, 210),
    13: (255, 140, 40),
    14: (40, 44, 56),
    15: (80, 220, 120),
    16: (255, 90, 170),
    17: (255, 255, 255),
    18: (30, 34, 46),
    19: (100, 110, 140),
    20: (0, 140, 70),
    21: (150, 200, 255),
}

W = 80
H = 40

os_data = [[2] * W for _ in range(H)]

# Title bar (rows 0-2)
for x in range(W):
    os_data[0][x] = 1
    os_data[1][x] = 1
    os_data[2][x] = 1

# Window buttons
os_data[0][3] = 6; os_data[0][5] = 7; os_data[0][7] = 5

# Title text dots
for x in range(20, 55):
    os_data[1][x] = 10

# Tab bar (rows 3-5)
for x in range(W):
    os_data[3][x] = 2
    os_data[4][x] = 2
    os_data[5][x] = 2

# Tabs
for x in range(3, 22):
    os_data[4][x] = 3
    os_data[5][x] = 3
for x in range(24, 40):
    os_data[4][x] = 4
    os_data[5][x] = 4
for x in range(42, 58):
    os_data[4][x] = 3
    os_data[5][x] = 3

# Tab labels
os_data[4][8] = 9; os_data[4][9] = 9; os_data[4][10] = 9
os_data[4][30] = 9; os_data[4][31] = 9; os_data[4][32] = 9

# Left panel: Git branch graph (cols 0-28)
# Vertical main branch line
for r in range(7, 36):
    os_data[r][8] = 5

# Branch merge points
branch_points = [(10, 5, 14), (14, 12, 18), (18, 5, 22), (22, 14, 14), (26, 5, 18), (30, 12, 14)]
for bp, left, right in branch_points:
    # Left branch
    for c in range(left, 9):
        if c < W:
            os_data[bp][c] = 8
    # Right branch
    for c in range(9, right + 1):
        if c < W:
            os_data[bp][c] = 11 if bp % 4 == 0 else 12

# Merge lines
for bp, left, right in branch_points:
    for c in range(left, right + 1):
        if c < W:
            os_data[bp][c] = 5 if c == 8 else (8 if c < 8 else (11 if bp % 4 == 0 else 12))

# Commit dots on main branch
for r in range(8, 35, 2):
    os_data[r][8] = 15

# Branch labels
os_data[9][3] = 9; os_data[9][4] = 9; os_data[9][5] = 9
os_data[15][18] = 9; os_data[15][19] = 9; os_data[15][20] = 9
os_data[23][3] = 9; os_data[23][4] = 9

# Right panel: Code editor (cols 30-79)
# Editor background
for r in range(7, 36):
    for c in range(30, 80):
        os_data[r][c] = 1

# Line numbers
for r in range(8, 35):
    os_data[r][30] = 10
    os_data[r][31] = 10

# Code lines with syntax highlighting
code_lines = [
    [(33, 11), (35, 9), (37, 8), (42, 5), (45, 9)],
    [(33, 5), (36, 17), (40, 13), (45, 9)],
    [(33, 11), (35, 8), (38, 9), (43, 5), (46, 9)],
    [(33, 8), (36, 17), (40, 13), (44, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 5), (45, 9)],
    [(33, 11), (35, 11), (37, 11), (39, 11), (41, 9)],
    [(33, 5), (36, 8), (40, 9), (44, 13), (47, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 11), (45, 9)],
    [(33, 8), (36, 17), (40, 13), (44, 9)],
    [(33, 11), (35, 11), (37, 9)],
    [(33, 5), (36, 8), (40, 9), (44, 11), (47, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 5), (45, 9)],
    [(33, 11), (35, 11), (37, 11), (39, 9)],
    [(33, 5), (36, 17), (40, 13), (44, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 5), (45, 9)],
    [(33, 11), (35, 11), (37, 9)],
    [(33, 5), (36, 8), (40, 17), (44, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 5), (45, 9)],
    [(33, 8), (36, 17), (40, 13), (44, 9)],
    [(33, 11), (35, 11), (37, 11), (39, 11), (41, 9)],
    [(33, 5), (36, 8), (40, 9), (44, 13), (47, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 5), (45, 9)],
    [(33, 11), (35, 11), (37, 9)],
    [(33, 8), (36, 17), (40, 13), (44, 9)],
    [(33, 11), (35, 9), (37, 8), (42, 11), (45, 9)],
]

for i, tokens in enumerate(code_lines):
    r = 8 + i
    if r >= 36:
        break
    for start_c, color in tokens:
        length = 3 + (i % 3)
        for c in range(start_c, min(start_c + length, 79)):
            os_data[r][c] = color

# Contributor avatars at bottom (rows 37-39)
avatar_colors = [6, 8, 11, 5, 13, 12, 16, 15]
for i, ac in enumerate(avatar_colors):
    base_c = 5 + i * 5
    if base_c + 3 < W:
        os_data[37][base_c] = ac
        os_data[37][base_c+1] = ac
        os_data[38][base_c] = ac
        os_data[38][base_c+1] = 17
        os_data[39][base_c] = ac
        os_data[39][base_c+1] = ac

# Bottom status bar
for x in range(W):
    os_data[36][x] = 14
    os_data[37][x] = 14 if x < 3 or x > 76 else os_data[37][x]

# Ensure all rows are exactly W wide
for i in range(len(os_data)):
    while len(os_data[i]) < W:
        os_data[i].append(2)
    os_data[i] = os_data[i][:W]

# ==================== 学校教学：智慧教室 ====================
sc = {
    0: (0, 0, 0),
    1: (210, 235, 255),
    2: (185, 215, 240),
    3: (165, 195, 225),
    4: (45, 115, 65),
    5: (35, 90, 50),
    6: (255, 255, 255),
    7: (200, 200, 220),
    8: (160, 130, 85),
    9: (130, 100, 65),
    10: (255, 215, 110),
    11: (185, 185, 205),
    12: (105, 105, 125),
    13: (65, 65, 85),
    14: (255, 185, 155),
    15: (75, 55, 35),
    16: (90, 140, 200),
    17: (200, 90, 90),
    18: (90, 170, 90),
    19: (255, 225, 160),
    20: (120, 170, 220),
    21: (170, 80, 80),
    22: (80, 150, 80),
    23: (140, 110, 75),
}

W = 80
H = 45

sch_data = [[2] * W for _ in range(H)]

# Ceiling (rows 0-2)
for x in range(W):
    sch_data[0][x] = 1
    sch_data[1][x] = 1
    sch_data[2][x] = 2

# Ceiling lights
for x in range(0, W, 16):
    for lx in range(x + 4, min(x + 12, W)):
        sch_data[1][lx] = 10

# Wall (rows 3-12)
for r in range(3, 13):
    for x in range(W):
        sch_data[r][x] = 2 if r < 5 else 3

# Blackboard (cols 8-72, rows 4-12)
for r in range(4, 13):
    for c in range(8, 73):
        sch_data[r][c] = 4

# Blackboard frame
for r in range(4, 13):
    sch_data[r][8] = 5
    sch_data[r][72] = 5
for c in range(8, 73):
    sch_data[4][c] = 5
    sch_data[12][c] = 5

# Chalk text on blackboard: "E=mc²" and formulas
# "E"
sch_data[6][20] = 6; sch_data[6][21] = 6; sch_data[6][22] = 6
sch_data[7][20] = 6; sch_data[8][20] = 6; sch_data[9][20] = 6
sch_data[7][21] = 6; sch_data[9][21] = 6; sch_data[9][22] = 6

# "="
sch_data[8][24] = 6; sch_data[8][25] = 6; sch_data[8][26] = 6
sch_data[10][24] = 6; sch_data[10][25] = 6; sch_data[10][26] = 6

# "m"
for c in range(28, 35):
    sch_data[9][c] = 6
sch_data[8][28] = 6; sch_data[8][31] = 6; sch_data[8][34] = 6
sch_data[7][28] = 6; sch_data[7][31] = 6; sch_data[7][34] = 6

# "c²"
sch_data[8][37] = 6; sch_data[9][37] = 6; sch_data[10][37] = 6
sch_data[8][38] = 6; sch_data[9][38] = 6
sch_data[7][40] = 6; sch_data[7][41] = 6

# Triangle diagram on right side of board
for i in range(5):
    sch_data[6][55+i] = 6
    sch_data[6][65-i] = 6
    sch_data[7+i][55+i] = 6
    sch_data[7+i][65-i] = 6
sch_data[11][55] = 6; sch_data[11][65] = 6
for c in range(55, 66):
    sch_data[11][c] = 6

# Dots on triangle vertices
sch_data[5][60] = 7

# Teacher desk (rows 14-17)
for r in range(14, 18):
    for c in range(30, 52):
        sch_data[r][c] = 8
for c in range(30, 52):
    sch_data[17][c] = 9

# Laptop on desk
for r in range(14, 16):
    for c in range(38, 46):
        sch_data[r][c] = 12
sch_data[14][40] = 6; sch_data[14][41] = 6; sch_data[14][42] = 6

# Teacher figure (cols 48-55, rows 11-17)
# Head
sch_data[11][50] = 15; sch_data[11][51] = 15; sch_data[11][52] = 15
sch_data[12][50] = 14; sch_data[12][51] = 14; sch_data[12][52] = 14
# Eyes
sch_data[12][50] = 13; sch_data[12][52] = 13
# Body
for r in range(13, 17):
    for c in range(49, 54):
        sch_data[r][c] = 16
# Arm pointing to board
sch_data[13][54] = 16; sch_data[13][55] = 14; sch_data[13][56] = 14

# Student desks area (rows 19-42)
# Row 1 of students
for r in range(19, 42):
    for x in range(W):
        if sch_data[r][x] == 2:
            sch_data[r][x] = 3

# Student desk rows
desk_rows = [20, 25, 30, 35, 40]
student_shirts = [16, 17, 18, 20, 21, 22]

for dr_idx, dr in enumerate(desk_rows):
    if dr + 2 >= H:
        break
    # Desk
    for c in range(5, 75, 14):
        for dc in range(c, min(c + 8, W)):
            sch_data[dr][dc] = 11
        # Chair back
        sch_data[dr-1][c+3] = 8 if dr > 0 else 8
        sch_data[dr-1][c+4] = 8

    # Students behind desks
    for c in range(8, 75, 14):
        student_r = dr + 2
        if student_r < H - 2:
            # Head
            sch_data[student_r][c+1] = 15
            sch_data[student_r][c+2] = 15
            sch_data[student_r][c+3] = 15
            # Face
            sch_data[student_r+1][c+1] = 14
            sch_data[student_r+1][c+2] = 14
            sch_data[student_r+1][c+3] = 14
            # Shirt
            shirt_color = student_shirts[(dr_idx + c) % len(student_shirts)]
            for sc2 in range(c, min(c + 5, W)):
                if student_r + 2 < H:
                    sch_data[student_r+2][sc2] = shirt_color

# Floor (last 2 rows)
for x in range(W):
    sch_data[H-2][x] = 19
    sch_data[H-1][x] = 19

# Floor lines
for c in range(0, W, 10):
    for r in range(H-2, H):
        if c < W:
            sch_data[r][c] = 23

# Ensure all rows are exactly W wide
for i in range(len(sch_data)):
    while len(sch_data[i]) < W:
        sch_data[i].append(2)
    sch_data[i] = sch_data[i][:W]

# ==================== Save ====================
output_dir = r"E:\桌面\像素图"

create_banner(
    os.path.join(output_dir, "人工智能_未来城市.png"),
    ai_data, ai_c, pixel_size=8
)

create_banner(
    os.path.join(output_dir, "开源社区_协作网络.png"),
    os_data, oc, pixel_size=8
)

create_banner(
    os.path.join(output_dir, "学校教学_智慧教室.png"),
    sch_data, sc, pixel_size=8
)

print("\n精品横幅像素图已全部生成！")