##########################################################
# File Name		: install.sh
# Author		: wqshao
# Created Time	: 2017年03月12日 星期日 09时45分53秒
# Description	:
##########################################################
#!/bin/bash

PWD=`pwd`
user=$USER
home=$HOME

function install_cmd()
{
	local cmd=$1
	#ubuntu
	echo "sudo apt-get install $cmd ..."
	sudo apt-get install $cmd
}

function which_command()
{
	local cmd=$1

	command -v $cmd >> /dev/null
	if [ $? -ne 0 ]; then
		echo "Install $cmd ..."
		install_cmd $cmd
	fi
}

function install_vim()
{
	local source_file="$home/.vim"
	local config_file="$home/.vimrc"

	which_command vim

	if [ ! -L $source_file ]; then
		ln -s $PWD/vim $source_file
		echo xxxxxxxxxxxxxx
	fi
	if [ ! -L $config_file ]; then
		ln -s $PWD/vim/vimrc $config_file
	fi
}

function install_git()
{
	local config_file="$home/.gitconfig"

	which_command git

	if [ ! -L $config_file ]; then
		ln -s $PWD/git/gitconfig $config_file
	fi
}

function install_tmux()
{
	local config_file="$home/.tmux.conf"

	which_command tmux

	if [ ! -L $config_file ]; then
		ln -s $PWD/tmux/tmux.conf $config_file
	fi
}

function bash_add_config()
{
	local bashrc="$home/.bashrc"
	local bashrc_bak="$home/.bashrc_bak"
	local config_bashrc="$home/.config_bashrc"
	local keyword="Winddoing"

	echo "$bashrc, $config_bashrc"

	if [ ! -f $bashrc_bak ]; then
		echo "$user backup <$bashrc> file to <$bashrc_bak>"
		cp $bashrc $bashrc_bak
	fi

	grep "$keyword" $bashrc >> /dev/null
	if [ $? -eq 0 ]; then
		return 1;
	fi

	cat $config_bashrc >> $bashrc
}

function install_bash()
{
	local config_file="$home/.config_bashrc"
	local config_file_set="$home/.custom_bashrc"

	if [ ! -L $config_file ]; then
		ln -s $PWD/bash/config_bashrc $config_file
	fi
	if [ ! -L $config_file_set ]; then
		ln -s $PWD/bash/custom_bashrc $config_file_set
	fi

	bash_add_config
}

function install_tools()
{
	local source_file="$home/.tools"

	if [ ! -L $source_file ]; then
		ln -s $PWD/tools/ $source_file
	fi
}

function main()
{
	install_bash
	install_tools

	install_vim
	install_git
	install_tmux
}

# start
sudo -l
if [ $? -eq 0 ]; then
	main
fi


