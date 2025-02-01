#!/bin/bash

# 🔹 현재 작업 디렉토리 저장
ORIGINAL_DIR=$(pwd)
SKEL_DIR="/etc/skel"

# 🔹 Sudo 비밀번호를 한 번만 입력하도록 설정
echo "🔹 Requesting sudo access... Please enter your password."
sudo -v  # sudo 권한을 미리 요청

# 🔹 sudo 인증이 만료되지 않도록 유지 (백그라운드 실행)
while true; do sudo -v; sleep 300; done &

echo "🔹 Installing Zsh and required packages..."
sudo apt update && sudo apt install -y zsh git wget unzip fonts-powerline curl

# 🔹 Zsh에서 실행되도록 강제 변경
if [ -z "$ZSH_VERSION" ]; then
    echo "🔹 Switching to Zsh for proper execution..."
    exec sudo -u "$USER" zsh "$0" "$@"
    exit
fi

echo "🔹 Changing default shell to Zsh..."
sudo chsh -s "$(which zsh)" "$USER"
touch ~/.zshrc

echo "🔹 Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    yes | sudo -u "$USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "🔹 Installing Powerlevel10k theme..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    sudo -u "$USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

echo "🔹 Installing Zsh plugins..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    sudo -u "$USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    sudo -u "$USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

echo "🔹 Applying Powerlevel10k settings..."
sudo -u "$USER" cp ".p10k.zsh" "$HOME/.p10k.zsh"

echo "🔹 Configuring .zshrc..."
if [ ! -f "$HOME/.zshrc" ]; then
    sudo -u "$USER" touch "$HOME/.zshrc"
fi

# ✅ 기존 `ZSH_THEME` 값이 있는 경우 유지, 없는 경우 `powerlevel10k` 적용
if ! sudo -u "$USER" grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

# ✅ 기본 플러그인 목록 추가 (기존 설정이 없는 경우만)
if ! sudo -u "$USER" grep -q '^plugins=' "$HOME/.zshrc"; then
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

echo "🔹 Cleaning up..."
echo "✅ Zsh setup complete!"

# ==============================================
# 🟢 신규 사용자의 기본 설정 적용 🟢
# ==============================================

echo "🔹 Setting Zsh as the default shell for new users..."
sudo sed -i 's|SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd

echo "🔹 Copying current user’s settings to /etc/skel/"
sudo rm -rf "$SKEL_DIR/.oh-my-zsh" "$SKEL_DIR/.zshrc" "$SKEL_DIR/.p10k.zsh"

# 신규 사용자에게 기본 환경 제공
sudo cp -r "$HOME/.oh-my-zsh" "$SKEL_DIR/"
sudo cp "$HOME/.zshrc" "$SKEL_DIR/"
sudo cp "$HOME/.p10k.zsh" "$SKEL_DIR/"

# ✅ 신규 사용자 `.zshrc`에 기본 플러그인 및 테마 추가
if ! grep -q '^ZSH_THEME=' "$SKEL_DIR/.zshrc"; then
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' | sudo tee -a "$SKEL_DIR/.zshrc" > /dev/null
fi
if ! grep -q '^plugins=' "$SKEL_DIR/.zshrc"; then
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo tee -a "$SKEL_DIR/.zshrc" > /dev/null
fi

# 🔹 기존 사용자에게도 설정 적용 (덮어쓰지 않음)
echo "🔹 Applying settings to existing users..."
for user in $(ls /home); do
    USER_HOME="/home/$user"
    USER_ZSHRC="$USER_HOME/.zshrc"

    if [ -f "$USER_ZSHRC" ]; then
        # ✅ 기존 사용자의 테마 설정 유지, 없으면 추가
        if ! sudo grep -q '^ZSH_THEME=' "$USER_ZSHRC"; then
            echo "🔹 Adding default theme to /home/$user/.zshrc"
            echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' | sudo tee -a "$USER_ZSHRC" > /dev/null
        fi

        # ✅ 기존 사용자의 플러그인 설정 유지, 없으면 추가
        if ! sudo grep -q '^plugins=' "$USER_ZSHRC"; then
            echo "🔹 Adding default plugins to /home/$user/.zshrc"
            echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo tee -a "$USER_ZSHRC" > /dev/null
        fi

        sudo chown $user:$user "$USER_ZSHRC"
    else
        echo "⚠️ Warning: /home/$user/.zshrc not found! Skipping..."
    fi
done

echo "✅ Setup complete!"

# 🔹 7. 기본 쉘을 `zsh`로 변경 (현재 사용자)
echo "✅ Setup complete! New users will have the same Zsh setup."
echo "🚀 System install finished"
echo "🔹 Changing default shell to Zsh for current user..."
chsh -s "$(which zsh)"

zsh