#!/bin/bash
###############################################################################
# Script to prepare the environment for pyenv with virtualenv (Python)        #
#                                                                             #
# Installs pyenv (and its dependencies) with virtualenv if not already        #
# installed and activates virtual Python environments for each (sub)directory #
# of this script that contains a .pyvenv_virtenv_version file with a valid    #
# Python version number (e.g. "3.10.12")                                      #
#                                                                             #
# Virtual environments are activated by pyenv through checking the            #
# .python-version file which will be automatically placed in each matched     #
# directory by this script.                                                   #
# If you delete this file, the virtual environment WILL NO LONGER WORK and    #
# it also won't delete the installation located under ~/.pyenv/versions.      #
# To delete a virtual environment, use 'pyenv virtualenv-delete <name>' AND   #
# remove the .python-version file.                                            #
#                                                                             #
# After running this script, the correct Python version for each              #
# subdirectory should be activated automatically when entering the directory. #
# You can check this by running 'pyenv local' inside a direcotry which        #
# contains a .python-version file.                                            #
# Some shells (e.g. zsh with ohmyzsh) also display the current environment.   #
#                                                                             #
# Happy environmenting!                                                       #
###############################################################################

set -e
# File which contains the Python version number to be installed for a directory
# (and nothing else!)
version_source_file=.virtenv_version

# Get directory the script runs in
BASE_DIR="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"
# find directories containing a .virtenv_version file
rel_base=$(basename "$BASE_DIR")
# Initialize an array to store directory paths
python_folders=()
# Function to traverse directories recursively and find .virtenv_version files
function find_virtenv_directories() {
  local dir="$1"
  local rel_path="${dir#$BASE_DIR}"

  if [ -f "$dir/$version_source_file" ]; then
    python_folders+=("$rel_base$rel_path")
  fi

  for subdir in "$dir"/*; do
    if [ -d "$subdir" ]; then
      find_virtenv_directories "$subdir"
    fi
  done
}

# Start the search from the script directory
find_virtenv_directories "$BASE_DIR"

# Install dependencies for pyenv
echo "Checking dependencies for pyenv..."
packages=("build-essential" "libssl-dev" "zlib1g-dev" "libbz2-dev"
  "libreadline-dev" "libsqlite3-dev" "curl" "llvm" "libncursesw5-dev"
  "xz-utils" "tk-dev" "libxml2-dev" "libxmlsec1-dev" "libffi-dev"
  "liblzma-dev" "libffi-dev")

missing_packages=()

for package in "${packages[@]}"; do
  if ! dpkg -s "$package" &>/dev/null; then
    missing_packages+=("$package")
  fi
done

if [ ${#missing_packages[@]} -eq 0 ]; then
  echo "All required packages are already installed."
else
  echo "Missing dependencies: ${missing_packages[@]}"
  read -p "Do you want to install the missing dependencies? (y/n): " choice
  if [ "$choice" = "y" ]; then
    echo "Installing dependencies for pyenv..."
    sudo apt-get update
    sudo apt-get install -y "${missing_packages[@]}"
    if [ $? -eq 0 ]; then
      echo "Package installation successful."
    else
      echo "Package installation failed."
      exit 1
    fi
  else
    echo "Aborted."
    exit 1
  fi
fi

# Install pyenv if not already installed
echo "Checking pyenv installation..."
if ! command -v pyenv >>/dev/null; then
  echo "penv not installed. Installing pyenv..."
  curl -L https://pyenv.run | bash
fi

USERSHELL=$(echo "$SHELL" | rev | cut -d '/' -f 1 | rev)
RC_FILE="$HOME/."$USERSHELL"rc"

# Check if the settings are already in the current rc-file.
# If not, ask to set them.
if ! grep -q 'export PATH="'$HOME'/.pyenv/bin:$PATH"' "$RC_FILE"; then
  read -p "Should I try adding the required settings to $RC_FILE? (y/n): " choice
  if [ "$choice" = "y" ]; then
    echo "Trying to add pyenv and pyenv virtualenv to $RC_FILE..."
    if test -f "$RC_FILE"; then
      echo '' >>"$RC_FILE" &&
        echo '# pyenv' >>"$RC_FILE" &&
        echo 'export PATH="'$HOME'/.pyenv/bin:$PATH"' >>"$RC_FILE" &&
        echo 'eval "$(pyenv init -)"' >>"$RC_FILE" &&
        echo 'eval "$(pyenv virtualenv-init -)"' >>"$RC_FILE"
      echo "Added pyenv to $RC_FILE"
      # Activate pyenv in current shell
      export PATH="~/.pyenv/bin:$PATH" &&
        eval "$(pyenv init -)" &&
        eval "$(pyenv virtualenv-init -)"
    else
      echo "WARNING: $RC_FILE not found."
      echo "For pyenv with virtenv to work, manually add the following lines to"
      echo "your shell's rc file (~/.bashrc, ~/.zshrc etc.):"
      echo '# pyenv'
      echo 'export PATH="~/.pyenv/bin:$PATH"'
      echo 'eval "$(pyenv init -)"'
      echo 'eval "$(pyenv virtualenv-init -)"'
    fi
  else
    echo "For pyenv with virtenv to work, manually add the following lines to"
    echo "your shell's rc file (~/.bashrc, ~/.zshrc etc.):"
    echo '# pyenv'
    echo 'export PATH="~/.pyenv/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
    echo 'eval "$(pyenv virtualenv-init -)"'
  fi
else
  echo "pyenv already present in $RC_FILE"
fi

# Activate pyenv and direnv and install python version for each subdirectory
for i in "${python_folders[@]}"; do
  # Determine the Python version from .python-version file
  python_version_file="$BASE_DIR/../$i/$version_source_file"

  if [ -f "$python_version_file" ]; then
    python_version=$(head -n 1 "$python_version_file")
    # Create virtual environment for the current subdirectory
    ci="${i//\//-}"
    venv_name="$ci-venv"

    # Check if the virtual environment is already installed
    if pyenv versions | grep -q "$venv_name"; then
      echo "Virtual environment $venv_name for $i is already installed."
    else
      # Check if the Python version is already present and if not, install it
      if ! pyenv versions | grep -q "$python_version" ; then
        echo "Installing Python version $python_version for '$i' ..."
        pyenv install $python_version
        if [ $? -eq 0 ]; then
          echo "Python $python_version installed."
        else
          echo "ERROR: Something went wrong."
          echo "Check if the version format in $i/$version_source_file is correct."
          echo "Aborting."
          exit 1
        fi
      fi
      echo "Creating virtual environment $venv_name for $i"
      pyenv virtualenv $python_version "$venv_name"
      if [ $? -eq 0 ]; then
        echo "Virtual environment successfully created."
      else
        echo "ERROR: Error creating virtual environment. Aborting."
        exit 1
      fi

    fi

    echo "$venv_name" >"$BASE_DIR/../$i/.python-version"

  else
    echo "ERROR: $python_version_file not found"
    exit 1
  fi
done

echo "Setup completed!"
