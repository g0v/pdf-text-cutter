#!/bin/bash

input_file=$1
output_file=$2

if [[ -z $output_file ]]; then
    output_file="/tmp/output.$$.png"
    inplace=1
else
    inplace=0
fi

image_width=$(convert ${input_file} -format '%[fx:w]' info:)
image_height=$(convert ${input_file} -format '%[fx:h]' info:)

hline_length=$(perl -e "print( 1+int($image_width  * .1) )")
vline_length=$(perl -e "print( 1+int($image_height * .1) )")

# echo $image_width x $image_height : $hline_length , $vline_length : $(($hline_length * 2 )), $(( $vline_length * 2 ))

convert ${input_file} \
  \( +clone -statistic mode 1x${hline_length} -statistic mode 1x$(( ${hline_length} * 2 ))  -statistic minimum 3x1 \) -compose Minus -composite -negate \
  \( +clone -statistic mode ${vline_length}x1 -statistic mode $(( ${vline_length} * 2 ))x1  -statistic minimum 1x3 \) -compose Minus -composite -negate \
${output_file}

if [[ "$inplace" == "1" ]]; then
    mv $output_file $input_file
fi
