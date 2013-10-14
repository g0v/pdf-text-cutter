pdf-text-cutter
===============

從 pdf 中切字出來的工具。

主要目是用來需要做 OCR 的 PDF。這些工具可以先將 pdf 切成以字為單位的圖檔。再轉給
tesserract 做 OCR。

安裝
----

- imagemagick (需要 convert 與 mogrify 指令)
- parallel
- perl
  - cpanm Moo YAML List::MoreUtils Imager

執行
----

    perl ./cutpdf.pl -o output/dir/ input.pdf

    perl ./cutpdf.pl -o output/dir/ input.png

