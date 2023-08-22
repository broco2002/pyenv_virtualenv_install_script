# pyenv_virtualenv_install_script
Install script for pyenv + virtualenv that automatically creates virtual environments

Only works on Debian based systems.
Tested on Ubuntu 22.04.

## Usage
Run the script from a directory and it will scan that directory and all its subdirectories
for a file named .virtenv_version that should only contain the Python version to be installed,
for example `3.10.12`.

It then install the respective Python version for each respective file (if they differ) and
creates a virtual environment for each of the (sub)directories containing a .virtenv_version
file named `path-to-directory-venv`.

So for example, if you run the script from /home/user/repos/projectx and inside projectx is
a file ansible/.virtenv_version containing the string `3.11.4`, the script will create
a virtual environment called "projectx-ansible-venv" and put a .python-version file inside
/home/user/repos/projectx/ansible, so every time you change into that directory, the virtual
environment will be automatically activated.

For more information, see the script comments. I also added an example .virtenv_version for
reference.
