#!/bin/bash
# ./fix_toc.sh
# ./rm_dup.sh
latexmk -pdf block-game.tex
makeglossaries block-game
latexmk -pdf block-game.tex
