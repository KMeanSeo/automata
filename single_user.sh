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

# Zsh에서 실행되도록 강제 변경
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

# 기존 `ZSH_THEME` 값이 있는 경우 유지, 없는 경우 `crunch` 적용
sudo -u "$USER" sed -i 's/^ZSH_THEME=.*/ZSH_THEME="crunch"/g' "$HOME/.zshrc"

# 기본 플러그인 목록 추가 (기존 설정이 없는 경우만)
if ! sudo -u "$USER" grep -q '^plugins=' "$HOME/.zshrc"; then
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
else
    sudo -u "$USER" sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$HOME/.zshrc"
fi

echo "Installing Zsh plugins..."
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