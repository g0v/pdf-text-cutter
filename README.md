pdf-text-cutter
===============

從 pdf 中切字出來的工具。

主要目是用來需要做 OCR 的 PDF。這些工具可以先將 pdf 切成以字為單位的圖檔。再轉給
tesserract 做 OCR。

安裝
----

- parallel
- perl
  - cpanm Moo YAML List::MoreUtils Imager
- xpdf
  - 需要 pdftoppm 指令

執行
----

    perl ./cutpdf.pl -o output/dir/ input.pdf

