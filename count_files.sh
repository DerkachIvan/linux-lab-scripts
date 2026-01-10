#!/bin/bash

#===========================================
#рекурсивний підрахунок файлів за розширенням
#з підрахунком загального розміру
#===========================================

#параметри командного рядка
TARGET_DIR=${1:-/etc}
EXTENSION=${2:-"*"}

#перевірка існування директорії
if [ ! -d "$TARGET_DIR" ]; then
    echo "Помилка: директорія $TARGET_DIR не існує"
    exit 1
fi

#рекурсивний пошук файлі
FILES=$(find "$TARGET_DIR" -type f -name "*.$EXTENSION" 2>/dev/null)
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

#виведення результатів
echo " -------------------------"
echo " Директорія: $TARGET_DIR"
echo " Розширення файлів: .$EXTENSION"
echo " Рекурсивний підрахунок файлів"
echo " -------------------------"
echo " Кількість файлів: $FILE_COUNT"
echo " Загальний розмір: $TOTAL_SIZE байт"
echo " -------------------------"

#завершення з кодом успіху
exit 0
