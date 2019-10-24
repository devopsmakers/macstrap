# macstrap - This may be destructive
It's boring bootstrapping a new MacBook time and time again - here is what I use to do it.

> Based heavily on some internal tooling in use at Ghost.

## Installs
The following things will be installed and configured wherever possible.

* brew
* oh-my-zsh
* powerlevel10k
* tfenv
* terragrunt
* xterrafile
* kubectl

> ⚠️I override the `open` command to open web pages in incognito with a unique
temporary profile. This allows us to have multiple, isolated logins when using
tools like `aws-vault` to login to the AWS Console.  

## Installation

TL; DR - Just tell me how to install it, I don't care if your break the things...
```
curl -o- https://devopsmakers.github.io/macstrap/install.sh | bash
```
