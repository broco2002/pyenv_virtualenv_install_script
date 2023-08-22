# pyenv_virtualenv_install_script
Install script for pyenv + virtualenv that automatically creates virtual environments
It's basically a bulk install for virtual Python environments.

Only works on Debian based systems.
Tested on Ubuntu 22.04.

Feel free to adapt it for other platforms and send a pull request if you want.


## Usage
Run the script from a directory and it install prerequisites for pyenv with virtualenv and 
will then scan that directory and all its subdirectories for a file named `.virtenv_version`.
The file should only contain the Python version to be installed, for example `3.10.12`.

If it finds one or multiple `.virtenv_version` files, it then installs the respective Python 
version for each respective file (if they differ) and creates a virtual environment for each 
of the (sub)directories containing a `.virtenv_version` file named `path-to-directory-venv`.

So for example, if you run the script from `/home/user/repos/projectx` and inside `projectx` is
a file `ansible/.virtenv_version` containing the string `3.11.4`, the script will create
a virtual environment called `projectx-ansible-venv` and put a `.python-version` file inside
`/home/user/repos/projectx/ansible`, so every time you change into that directory, the virtual
environment will be automatically activated.
If there also is a `/home/user/repos/projectx/test/.virtenv_version` containing `3.10.12`,
the script would install Python 3.10.12 and create the virtual environment `projectx-test-venv`.
All in one go.

For more information, see the script comments. I also added an example `.virtenv_version` for
reference.

Feel free do adapt it to your needs, update it, whatever, but it comes with absolutely no
warranty.
