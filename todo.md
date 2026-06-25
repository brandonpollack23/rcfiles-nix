- further organize common.nix module
- further organize home nix module (scripts etc that are in let)

- implement my own ssh keyring of keys where upon initialization of public key a commit is made to the flake into an attribute set of its hostname to the public key. other hosts can select which hosts they wish to allow (this can be done from the get go even before the key is committed) to ssh into them. then these are added to authorized keys for ssh by the flake (if present after initial machine setup and its commit updates the other hosts). so flow is -> add host to config -> add that host to allowed ssh accessers to other hosts -> bring up new host -> that hosts user interactive initialization script (which also sets up sops) also adds/commits its public key and pushes -> other hosts pull and update -> when tehy rebuild now there is a public key there and they can add it to known hosts successfully.

- find an way to find location of the flake so i dont have to hard code commands that require it.

- when i create a new host, how can i get hardware-configuration before creating the image?

- make sure the flake is in the path you specify in autoUpgrade.flakePath

- google drive setup

- it looks like we can get at ssh keys from nix, lets make the server accessible by public key from my other devices, and my desktop accessible via laptop

- setup home
  - setup desktop background revolving bing

- nvim lazyvim, how deep do i go?

- ssh pub/priv key setup (and on ncc1701e, can i replace my hard coded public key?)
- setup ds9 ssh, setup ds9 wireguard

- ncc 1701e config (steam, etc)
  - hardware config? how?
  - swap?

- streaming box?
