# macstrap - This may be destructive
It's boring bootstrapping a new MacBook time and time again - here is what I use to do it.

## Installs
The following things will be installed and configured wherever possible.

* brew
* oh-my-zsh
* powerlevel10k
* tfenv
* terragrunt
* xterrafile
* kubectl

> :warning: I override the `open` command to open web pages in incognito with a unique
temporary profile. This allows us to have multiple, isolated logins when using
tools like `aws-vault` to login to the AWS Console.  
