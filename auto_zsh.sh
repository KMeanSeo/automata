#!/bin/bash

# 현재 작업 디렉토리 저장
ORIGINAL_DIR=$(pwd)

# Sudo 비밀번호를 한 번만 입력하도록 설정
echo "Requesting sudo access... Please enter your password."
sudo -v  # sudo 권한을 미리 요청

# sudo 인증이 만료되지 않도록 유지 (백그라운드 실행)
while true; do sudo -v; sleep 300; done &

echo "Installing Zsh and required packages..."
sudo apt update && sudo apt install -y zsh git wget unzip fonts-powerline curl

# 기본 Zsh 환경을 /etc/skel/에 저장하여 새 사용자 생성 시 자동 적용
echo "Setting up default Zsh environment for new users..."
sudo mkdir -p /etc/skel/.oh-my-zsh/custom/plugins

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" > /dev/null 2>&1
fi

sudo cp -r $HOME/.oh-my-zsh /etc/skel/

if [ ! -f "/etc/skel/.zshrc" ]; then
    sudo cp /etc/skel/.oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
fi

sudo sed -i 's/^ZSH_THEME=.*/ZSH_THEME="crunch"/g' /etc/skel/.zshrc

if ! grep -q '^plugins=' "/etc/skel/.zshrc"; then
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo tee -a "/etc/skel/.zshrc" > /dev/null
else
    sudo sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "/etc/skel/.zshrc"
fi

if [ ! -d "/etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions "/etc/skel/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
if [ ! -d "/etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting "/etc/skel/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

# 새 사용자를 추가할 때 자동 적용
echo "Setting default shell to Zsh for new users..."
sudo usermod -s $(which zsh) root
echo "export SHELL=$(which zsh)" | sudo tee -a /etc/skel/.bashrc > /dev/null
echo "exec $(which zsh)" | sudo tee -a /etc/skel/.bash_profile > /dev/null

# 현재 사용자 적용
if [ -z "$ZSH_VERSION" ]; then
    echo "Switching to Zsh for proper execution..."
    export ZSH_SETUP_DONE=1
    exec sudo -u "$USER" zsh "$0" "$@"
    exit
fi

# Zsh로 전환된 후에도 중복 실행 방지
if [ "$ZSH_SETUP_DONE" = "1" ]; then
    echo "Now running Zsh! Continuing setup..."
fi

echo "Changing default shell to Zsh..."
sudo chsh -s "$(which zsh)" "$USER"

echo "Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    yes | sudo -u "$USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Configuring .zshrc..."
if [ ! -f "$HOME/.zshrc" ]; then
    sudo -u "$USER" cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
fi

sudo -u "$USER" sed -i 's/^ZSH_THEME=.*/ZSH_THEME="crunch"/g' "$HOME/.zshrc"

if ! sudo -u "$USER" grep -q '^plugins=' "$HOME/.zshrc"; then
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
else
    sudo -u "$USER" sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$HOME/.zshrc"
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    sudo -u "$USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    sudo -u "$USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

echo "Applying Zsh settings..."
sudo -u "$USER" zsh -c "source ~/.zshrc"

echo "Cleaning up..."

exec zsh
