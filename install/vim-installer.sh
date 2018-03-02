#!/bin/bash

[ ! -d ~/.vim/bundle] && mkdir -p ~/.vim/bundle

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

wget "https://raw.githubusercontent.com/klflenk/config/master/vimrc" -O ~/.vimrc

vim +PluginInstall +qall
