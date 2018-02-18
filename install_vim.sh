#!/bin/sh
# install_vim.sh
# suitable for apk pkg
# - adds pathogen for all users
# - makes comments readable
# - adds my preferred indentation defaults
VIM_INDENT=4
VIMRC=/etc/vim/vimrc

PKGS="vim"
BUILD_PKGS="curl ca-certificates git"

echo "INFO $0: installing $PKGS pathogen"
apk --no-cache add --update $PKGS $BUILD_PKGS \
&& mkdir -p /etc/vim/autoload /etc/vim/bundle \
&& curl -LSso /etc/vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

if [[ ! -r /etc/vim/autoload/pathogen.vim ]]; then
    echo "ERROR: $0: failed to get pathogen (vim plugin manager)"
fi

# ... we want modelines dammit ...
sed -i 's/^\(set nomodeline\)/" \1/' $VIMRC

cat << EOF >> $VIMRC
" added by $0 $(date +'%Y-%m-%d %H:%M:%S')
set rtp+=/etc/vim
execute pathogen#infect()
hi Comment ctermfg=6
set tabstop=$VIM_INDENT
set shiftwidth=$VIM_INDENT
set shiftround
set expandtab
set smartindent
set pastetoggle=<F1>
autocmd FileType make setlocal noexpandtab
autocmd FileType go setlocal noexpandtab
EOF

[[ -d /etc/skel ]] && cp $VIMRC /etc/skel/.vimrc

apk --no-cache --purge del $BUILD_PKGS
rm -rf /var/cache/apk/*

exit 0

