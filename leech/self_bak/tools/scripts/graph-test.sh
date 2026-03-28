#!/usr/bin/env bash
# graph-test.sh — Generate graphs + run tests + display preview
# Usage: graph-test.sh [graph_type] [output_file]

set -euo pipefail

GRAPH_TYPE="${1:-senoide}"
OUTPUT_DIR="${2:-.}"
TIMESTAMP=$(date +%s)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  GRAPH GENERATOR + AUTO TEST${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# STAGE 1: Generate graph
echo -e "${YELLOW}[1/3]${NC} Gerando gráfico ($GRAPH_TYPE)..."

if [ "$GRAPH_TYPE" = "senoide" ]; then
    python3 << 'EOFPYTHON'
import math

width = 800
height = 400
padding = 50

x_min, x_max = 0, 4 * math.pi
y_min, y_max = -1.2, 1.2

def scale_x(x):
    return padding + (x - x_min) / (x_max - x_min) * (width - 2 * padding)

def scale_y(y):
    return height - padding - (y - y_min) / (y_max - y_min) * (height - 2 * padding)

points_sin = []
points_cos = []
step = 0.05
x = 0
while x <= 4 * math.pi:
    y_sin = math.sin(x)
    y_cos = math.cos(x)
    points_sin.append((scale_x(x), scale_y(y_sin)))
    points_cos.append((scale_x(x), scale_y(y_cos)))
    x += step

svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{width}" height="{height}" xmlns="http://www.w3.org/2000/svg" style="background: white;">
  <defs>
    <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
      <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#e0e0e0" stroke-width="0.5"/>
    </pattern>
  </defs>
  <rect width="{width}" height="{height}" fill="url(#grid)" />
  <line x1="{scale_x(0)}" y1="{padding}" x2="{scale_x(0)}" y2="{height - padding}" stroke="black" stroke-width="1"/>
  <line x1="{padding}" y1="{scale_y(0)}" x2="{width - padding}" y2="{scale_y(0)}" stroke="black" stroke-width="1"/>
  <polyline points="{''.join([f'{x},{y} ' for x, y in points_sin])}" fill="none" stroke="#e74c3c" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <polyline points="{''.join([f'{x},{y} ' for x, y in points_cos])}" fill="none" stroke="#3498db" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="{width/2}" y="30" text-anchor="middle" font-size="18" font-weight="bold" fill="black">Senoide vs Cosseno</text>
  <rect x="10" y="50" width="150" height="70" fill="white" stroke="#ccc" stroke-width="1" rx="3"/>
  <line x1="20" y1="65" x2="50" y2="65" stroke="#e74c3c" stroke-width="2.5"/>
  <text x="60" y="70" font-size="12" fill="black">sin(x)</text>
  <line x1="20" y1="90" x2="50" y2="90" stroke="#3498db" stroke-width="2.5"/>
  <text x="60" y="95" font-size="12" fill="black">cos(x)</text>
  <text x="{scale_x(0)}" y="{height - 20}" text-anchor="middle" font-size="11" fill="black">0</text>
  <text x="{scale_x(math.pi)}" y="{height - 20}" text-anchor="middle" font-size="11" fill="black">π</text>
  <text x="{scale_x(2*math.pi)}" y="{height - 20}" text-anchor="middle" font-size="11" fill="black">2π</text>
  <text x="{scale_x(3*math.pi)}" y="{height - 20}" text-anchor="middle" font-size="11" fill="black">3π</text>
  <text x="{scale_x(4*math.pi)}" y="{height - 20}" text-anchor="middle" font-size="11" fill="black">4π</text>
  <text x="{padding - 20}" y="{scale_y(1) + 5}" text-anchor="end" font-size="11" fill="black">1</text>
  <text x="{padding - 20}" y="{scale_y(0) + 5}" text-anchor="end" font-size="11" fill="black">0</text>
  <text x="{padding - 20}" y="{scale_y(-1) + 5}" text-anchor="end" font-size="11" fill="black">-1</text>
</svg>
'''

with open('/workspace/senoide.svg', 'w') as f:
    f.write(svg)
EOFPYTHON
    SVG_FILE="/workspace/senoide.svg"
    echo -e "${GREEN}✓ SVG gerado${NC}"
else
    echo -e "${RED}✗ Tipo de gráfico desconhecido: $GRAPH_TYPE${NC}"
    exit 1
fi

# STAGE 2: Run tests
echo -e "\n${YELLOW}[2/3]${NC} Executando testes..."

python3 << 'EOFTEST'
import xml.etree.ElementTree as ET
import os

svg_file = '/workspace/senoide.svg'
test_results = []

# TEST 1: File exists
try:
    assert os.path.exists(svg_file)
    test_results.append(("Arquivo existe", True))
except:
    test_results.append(("Arquivo existe", False))

# TEST 2: Valid XML
try:
    tree = ET.parse(svg_file)
    root = tree.getroot()
    test_results.append(("XML bem formado", True))
except:
    test_results.append(("XML bem formado", False))

# TEST 3: Has polylines
try:
    polylines = root.findall('.//{http://www.w3.org/2000/svg}polyline')
    assert len(polylines) == 2
    test_results.append(("2 polylines (sin/cos)", True))
except:
    test_results.append(("2 polylines (sin/cos)", False))

# TEST 4: Has axes
try:
    lines = root.findall('.//{http://www.w3.org/2000/svg}line')
    assert len(lines) >= 2
    test_results.append(("Eixos presentes", True))
except:
    test_results.append(("Eixos presentes", False))

# TEST 5: Has labels
try:
    texts = root.findall('.//{http://www.w3.org/2000/svg}text')
    assert len(texts) >= 5
    test_results.append(("Labels presentes", True))
except:
    test_results.append(("Labels presentes", False))

# Print results
passed = sum(1 for _, result in test_results if result)
total = len(test_results)

for test_name, result in test_results:
    status = "✓" if result else "✗"
    print(f"{status} {test_name}")

print(f"\nResultado: {passed}/{total} testes passaram")
exit(0 if passed == total else 1)
EOFTEST

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os testes passaram${NC}"
else
    echo -e "${RED}✗ Alguns testes falharam${NC}"
    exit 1
fi

# STAGE 3: ASCII preview
echo -e "\n${YELLOW}[3/3]${NC} Preview em ASCII..."
python3 << 'EOFPREVIEW'
import math

print("\n" + "┏" + "━" * 78 + "┓")
print("┃" + " PREVIEW: SENOIDE (ASCII ART) ".center(78) + "┃")
print("┗" + "━" * 78 + "┛\n")

width = 78
height = 16
amplitude = (height - 1) / 2

canvas = [[" " for _ in range(width)] for _ in range(height)]

# Draw sine
for x in range(width):
    angle = (x / width) * 4 * math.pi
    y_value = math.sin(angle)
    y = int(amplitude - (y_value * amplitude))
    y = max(0, min(height - 1, y))
    canvas[y][x] = "█"

# Center line
center_y = height // 2
for x in range(width):
    if canvas[center_y][x] == " ":
        canvas[center_y][x] = "·"

# Display
for row in canvas:
    print("║ " + "".join(row) + " ║")

print("\n║ " + "x: 0 → 4π (2 ciclos)".ljust(76) + " ║")
print("║ " + "y: -1 → +1".ljust(76) + " ║")
print("┗" + "━" * 78 + "┛\n")
EOFPREVIEW

# FINAL STATUS
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ COMPLETO${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "Arquivo: ${BLUE}$SVG_FILE${NC}"
echo -e "Tamanho: $(du -h $SVG_FILE | cut -f1)"
echo ""
