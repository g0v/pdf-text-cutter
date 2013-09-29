#!/bin/zsh

input_file=$1
output_file=$2

line_length=100

image_width=$(convert ${input_file} -format '%[fx:w]' info:)
image_height=$(convert ${input_file} -format '%[fx:h]' info:)

hline_length=$(perl -e "print( 1+int($image_width * .1) )")
vline_length=$(perl -e "print( 1+int($image_height *.1) )")

echo $image_width x $image_height : $hline_length , $vline_length

convert ${input_file} \
  \( +clone -statistic mode 1x${hline_length} \) -compose Minus -composite -negate \
  \( +clone -statistic mode ${vline_length}x1 \) -compose Minus -composite -negate \
${output_file}
