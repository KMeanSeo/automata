#!/bin/bash

# 🔹 현재 작업 디렉토리 저장
ORIGINAL_DIR=$(pwd)

echo "🔹 Installing Zsh and required packages..."
sudo apt update && sudo apt install -y zsh git wget unzip fonts-powerline curl

# 🔹 Zsh에서 실행되도록 강제 변경 (현재 셸이 Zsh가 아니면 실행)
if [ -z "$ZSH_VERSION" ]; then
    echo "🔹 Switching to Zsh for proper execution..."
    exec zsh "$0" "$@"
    exit
fi

echo "🔹 Changing default shell to Zsh..."
chsh -s "$(which zsh)"
touch ~/.zshrc

echo "🔹 Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "🔹 Installing Powerlevel10k theme..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

echo "🔹 Installing Zsh plugins..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

echo "🔹 Applying Powerlevel10k settings..."
cp ".p10k.zsh" "$HOME/.p10k.zsh"

echo "🔹 Configuring .zshrc..."
if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
fi

sed -i 's|^export ZSH=.*|export ZSH="$HOME/.oh-my-zsh"|' "$HOME/.zshrc"
sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
sed -i 's|^plugins=(.*)|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$HOME/.zshrc"

# ✅ 초기 설정 마법사가 실행되지 않도록 설정 추가
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME/.zshrc"
echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> "$HOME/.zshrc"

echo "🔹 Cleaning up..."


echo "✅ Zsh setup complete!"

# ==============================================
# 🟢 이제부터는 `useradd`와 관련된 설정 추가 🟢
# ==============================================

echo "🔹 Setting Zsh as the default shell for new users..."
sudo sed -i 's|SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd

# Oh My Zsh & Powerlevel10k 설정을 `/etc/skel/`로 이동 (새 사용자 자동 적용)
SKEL_DIR="/etc/skel"

echo "🔹 Copying current user’s settings to /etc/skel/"
sudo rm -rf "$SKEL_DIR/.oh-my-zsh" "$SKEL_DIR/.zshrc" "$SKEL_DIR/.p10k.zsh"

# 현재 사용자의 Oh-My-Zsh, .zshrc, .p10k.zsh을 /etc/skel/에 저장
sudo cp -r "$HOME/.oh-my-zsh" "$SKEL_DIR/"
sudo cp "$HOME/.zshrc" "$SKEL_DIR/"
sudo cp "$HOME/.p10k.zsh" "$SKEL_DIR/"

# 🔹 기존 사용자에게도 동일한 설정 적용 (설정 파일이 없을 경우 복사)
echo "🔹 Applying settings to existing users..."
for user in $(ls /home); do
    USER_HOME="/home/$user"

    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        sudo cp -r "$SKEL_DIR/.oh-my-zsh" "$USER_HOME/"
        sudo chown -R $user:$user "$USER_HOME/.oh-my-zsh"
    fi

    if [ ! -f "$USER_HOME/.zshrc" ]; then
        sudo cp "$SKEL_DIR/.zshrc" "$USER_HOME/.zshrc"
        sudo chown $user:$user "$USER_HOME/.zshrc"
    fi

    if [ ! -f "$USER_HOME/.p10k.zsh" ]; then
        sudo cp "$SKEL_DIR/.p10k.zsh" "$USER_HOME/.p10k.zsh"
        sudo chown $user:$user "$USER_HOME/.p10k.zsh"
    fi
done

# 🔹 6. 현재 사용자에게도 즉시 적용
echo "🔹 Applying settings to the current user..."
source "$HOME/.zshrc"

# 🔹 7. 기본 쉘을 `zsh`로 변경 (현재 사용자)
echo "✅ Setup complete! New users will have the same Zsh setup."
echo "🚀 System install finished"
echo "🔹 Changing default shell to Zsh for current user..."
chsh -s "$(which zsh)"

# 🔹 8. 설치 완료 후 원래 디렉토리로 돌아감
cd "$ORIGINAL_DIR"

# 🔹 9. Zsh 실행
zsh


