#!/bin/bash

#===========================================
#рекурсивний підрахунок файлів за розширенням
#з підрахунком загального розміру
#===========================================

#внесені зміни в скрипт для нової гілки

CONFIG="/etc/count-files.conf"
[ -f "$CONFIG" ] && source "$CONFIG"

#параметри командного рядка
TARGET_DIR=${1:-${TARGET_DIR:-/etc}}
EXTENSION=${2:-${EXTENSION:-"*"}}
HUMAN=false

if [[ "$@" == *"--help"* ]]; then
    echo "Використання: count_files [DIR] [EXT] [--human]"
    echo "DIR   - директорія (за замовчуванням /etc)"
    echo "EXT   - розширення файлів або *"
    echo "--human - показувати розмір у зручному форматі"
    exit 0
fi

if [[ "$@" == *"--human"* ]]; then
    HUMAN=true
fi

echo "Скрипт запущено: $(date)"

#перевірка існування директорії
if [ ! -d "$TARGET_DIR" ]; then
    echo "Помилка: директорія $TARGET_DIR не існує"
    exit 1
fi

#рекурсивний пошук файлі
if [ "$EXTENSION" = "*" ]; then
    FILES=$(find "$TARGET_DIR" -type f 2>/dev/null)
else
    FILES=$(find "$TARGET_DIR" -type f -name "*.$EXTENSION" 2>/dev/null)
fi
    
#підрахунок кількості файлів
if [ -z "$FILES" ]; then
    FILE_COUNT=0
else
    FILE_COUNT=$(echo "$FILES" | wc -l)
fi

#підрахунок загального розміру
TOTAL_SIZE=0
if [ "$FILE_COUNT" -gt 0 ]; then
    while IFS= read -r file; do
        size=$(stat -c %s "$file")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    done <<< "$FILES"
fi

if $HUMAN; then
    TOTAL_SIZE=$(numfmt --to=iec "$TOTAL_SIZE")
fi


#виведення результатів
echo " -------------------------"
echo " Директорія: $TARGET_DIR"
echo " Розширення файлів: .$EXTENSION"
echo " Рекурсивний підрахунок файлів"
echo " -------------------------"
echo " Кількість файлів: $FILE_COUNT"
echo " Загальний розмір: $TOTAL_SIZE"
echo " -------------------------"

#завершення з кодом успіху
exit 0
