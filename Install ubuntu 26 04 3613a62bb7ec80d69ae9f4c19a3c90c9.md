# Install ubuntu 26.04

- install Chrome, Chromium, Postman
- Image editor: Drawing (slow)
- warp:
download and install: [https://www.warp.dev](https://www.warp.dev/)
- cursor [https://cursor.com/download](https://cursor.com/download)
- gotiengviet
    
    `sudo apt-get install language-pack-vi`
    
    Log off (user) > settings > keyboard > add language
    
- vim (full package; Ubuntu default is vim-tiny)
    
    ```bash
    sudo apt update
    sudo apt install -y vim
    vim --version
    which vim   # should be /usr/bin/vim, not /usr/bin/vim.tiny
    ```
    
- zsh
    
    ```ruby
    sudo apt install zsh -y
    zsh --version
    
    # Set Zsh as Your Default Shell 
    chsh -s $(which zsh)
    
    # check
    echo $SHELL
    ```
    
- install Rbenv and Ruby
    - Install Base Dependencies
        
        ```jsx
        sudo apt install -y \
          git curl wget build-essential autoconf bison rustc libssl-dev \
          libyaml-dev zlib1g-dev libffi-dev libgmp-dev \
          libreadline-dev libncurses5-dev libncursesw5-dev \
          libxml2-dev libxslt1-dev libcurl4-openssl-dev \
          software-properties-common pkg-config \
          imagemagick libvips \
          sqlite3 libsqlite3-dev \
          postgresql postgresql-contrib libpq-dev \
          redis-server \
          unzip xz-utils tk-dev
        ```
        
    - Install rbenv
        
        ```jsx
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv
        
        git clone https://github.com/rbenv/ruby-build.git \
          ~/.rbenv/plugins/ruby-build
        
        echo 'export RBENV_ROOT="$HOME/.rbenv"' >> ~/.zshrc
        echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> ~/.zshrc
        echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
        
        exec $SHELL
        rbenv --version
        ```
        
    - Install Ruby
        
        ```ruby
        rbenv install -l
        rbenv install 3.3.6
        rbenv global 3.3.6
        ruby -v
        which ruby
        ```
        
- Install Node.js
    
    ```jsx
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
    node -v
    npm -v
    ```
    
- start postgresql
    
    ```ruby
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    
    # List databases and users
    psql -d postgres -c "\l"
    psql -d postgres -c "\du"
    ```
    
- Azure CLI
    
    ```ruby
    sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Microsoft key if not already added
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor \
      | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
    
    # Add Azure CLI repo using Ubuntu 24.04 (noble)
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
      | sudo tee /etc/apt/sources.list.d/azure-cli.list
    
    # Update package lists
    sudo apt-get update
    
    # Install Azure CLI
    sudo apt-get install -y azure-cli
    
    # Verify
    az --version
    ```
    
- install Azure/kubelogin/kubelogin
    
    ```bash
    wget [https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip](https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip)
    sudo apt install -y unzip
    unzip kubelogin-linux-amd64.zip
    sudo mv bin/linux_amd64/kubelogin /usr/local/bin/
    sudo chmod +x /usr/local/bin/kubelogin
    kubelogin --version
    ```
    
- Azure terminal login:
    
    ```bash
    	az login
    	# use Another account > Sign-in Options > Sign in to an Organization > enter domain (microsofti3systems.onmicrosoft.com) > login quanganh.ho@10kn.io account > success
    	# back to terminal > select subscription [1]
    	az account list --output table
    ```
    
- install kubectl
    
    ```bash
    	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    	chmod +x ./kubectl
    	sudo mv ./kubectl /usr/local/bin/kubectl
    	# export PATH=$PATH:/usr/local/bin to ~/.zshrc
    	sudo apt update
    	kubectl version --client
    	
    # List AKS Clusters:
    az aks list -o table
    
    # Download kubeconfig
    az aks get-credentials \
      -g STG-CLOMO \
      -n stg-clomo-06
    
    # Convert kubeconfig for Azure Login
    kubelogin convert-kubeconfig -l azurecli
    
    ### PASTE .azure and .kube from other machine to gel full access
    
    # get pods and Access
    	kubectl get ns
    	kubectl get pods -A
    	kubectl exec -n dev5 --context stg-clomo-06 dev5panel-applications-api-7554b84d89-s6wrt -- /bin/sh
    
    # restart kubernetes pod
    	kubectl rollout restart deploy dev5clomo-panel dev5clomo-mdm dev5clomo-bg dev5clomo-bg-no-session-low-priority dev5clomo-bg-no-session-mid-priority --context stg-clomo-03 -n dev5
    ```
    
- install notion: (use web version is better)
    1. worked:
    sudo apt purge notion
    sudo snap install notion-snap-reborn
- gh CLI
    
    ```ruby
    sudo apt install gh -y
    gh --version
    gh auth login
    ? What account do you want to log into? GitHub.com
    ? What is your preferred protocol for Git operations on this host? HTTPS
    ? Authenticate Git with your GitHub credentials? Yes
    ? How would you like to authenticate GitHub CLI? Login with a web browser
    ```
    
- mysql 8.4
    
    <aside>
    💡
    
     MySQL 5.7 packages are no longer in the Ubuntu repositories for newer versions (like 24.04), and even adding older repositories may not always work.
    
    </aside>
    
    ```bash
    sudo apt install mysql-server
    sudo systemctl status mysql
    sudo systemctl stop
    
    # create root user
    ALTER USER 'root'@'localhost'
    IDENTIFIED WITH caching_sha2_password BY '';
    
    # change pass for root user
    sudo mysql
    CREATE USER 'rails'@'localhost' IDENTIFIED BY 'password';
    GRANT ALL PRIVILEGES ON *.* TO 'rails'@'localhost';
    FLUSH PRIVILEGES;
    # access again:
    mysql -urails -ppassword
    ```
    

- install **MongoDB** (to run rspec with `use_mongoid: true`)
    
    ```ruby
    # MongoDB repo does not support noble on their server yet.
    # Add JAMMY Repo Instead
    echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
    https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    **sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list**
    
    # MongoDB Installation
    sudo apt update
    sudo apt install -y mongodb-org
    
    # Start the MongoDB Service
    sudo systemctl daemon-reload
    sudo systemctl enable mongod
    sudo systemctl start mongod
    sudo systemctl status mongod
    ```
    
- Tableplus for Ubuntu 24.04 X86_64
    - Cannot install as official way by run command from [homepage](https://tableplus.com/download/linux)
    - Download AppImage [TablePlus-x64.AppImage](https://tableplus.com/release/linux/x64/TablePlus-x64.AppImage)
    - download tableplus icon app: [https://tableplus.com/resources/favicons/apple-icon-60x60.png](https://tableplus.com/resources/favicons/apple-icon-60x60.png)
    - add a desktop launcher
        
        ```ruby
        mv TablePlus-x64.AppImage ~/Documents/Systems/install-packs/
        mv ~/Downloads/apple-icon-60x60.png ~/Documents/Systems/install-packs/
        
        vi ~/.local/share/applications/tableplus.desktop
        # content for the desktop file
        [Desktop Entry]
        Name=TablePlus
        Exec=/home/anhho/Documents/Systems/install-packs/TablePlus-x64.AppImage
        Icon=/home/anhho/Documents/Systems/install-packs/apple-icon-60x60.png
        Type=Application
        Categories=Development;
        Terminal=false
        
        # Make sure it’s executable and Refresh desktop entries
        chmod +x ~/Documents/Systems/install-packs/TablePlus-x64.AppImage
        chmod +x ~/.local/share/applications/tableplus.desktop
        update-desktop-database ~/.local/share/applications/
        ```
        
- install stern to check Kubernetes log
    
    ```ruby
    # Install kubectl krew
    (
      set -x; cd "$(mktemp -d)" &&
      OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
      ARCH="$(uname -m)" &&
      # translate architecture names
      if [[ "$ARCH" == "x86_64" ]]; then ARCH="amd64"; fi
      if [[ "$ARCH" == "aarch64" ]]; then ARCH="arm64"; fi
      KREW="krew-${OS}_${ARCH}" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
      tar zxvf "${KREW}.tar.gz" &&
      ./"${KREW}" install krew
    )
    
    # Add krew to your PATH
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    
    kubectl krew
    kubectl krew install stern
    kubectl stern --version
    # check log
    kubectl stern 'dev5clomo-mdm-*' -n dev5 -c clomo --max-log-requests 200
    ```
    
- add ssh files and clone projects
    
    ```ruby
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/*
    git clone git@github.com:i3systems-com/clomo.git
    git clone git@github.com:i3systems-com/panel-front.git
    ```
    

Ask AI Agent to run apps on local machine:

```
i just clone this project to local machine 
i want to run it on local machine without docker (native run on ubuntu machine for local only)
i checkout to local-develop branch new
i want to run run all each service local (not apply the change to repo just change to make services can run and keep it local)
 eg steps:
cd Panel
rbenv install 2.7.6
gem install bundler 1.17.3
bundle install
(if some gem failed to bundle can fix it or upgrade it local)
when finish try to run rails c 
mysql already installed: mysql -uroot
then try to rspec command for a spec file

move to continue with other services with same steps..
```

- Useful Rails Native Gem Fixes
    - Nokogiri
        
        `sudo apt install libxml2-dev libxslt1-dev -y`
        
    - pg gem
        
        `sudo apt install libpq-dev -y`