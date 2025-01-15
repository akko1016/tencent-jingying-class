#!/bin/bash

# 进入图片目录
cd assets/images

# 初始化计数器
img_counter=1
gif_counter=1

# 重命名所有 jpg 和 png 文件
for file in *.jpg *.jpeg *.png; do
    # 检查文件是否存在（避免通配符不匹配的情况）
    [ -e "$file" ] || continue
    
    # 获取文件扩展名
    ext="${file##*.}"
    # 创建新文件名
    new_name=$(printf "img_%03d.%s" "$img_counter" "$ext")
    
    # 重命名文件
    mv "$file" "$new_name"
    ((img_counter++))
done

# 重命名所有 gif 文件
for file in *.gif; do
    # 检查文件是否存在
    [ -e "$file" ] || continue
    
    # 创建新文件名
    new_name=$(printf "gif_%03d.gif" "$gif_counter")
    
    # 重命名文件
    mv "$file" "$new_name"
    ((gif_counter++))
done

echo "重命名完成！"