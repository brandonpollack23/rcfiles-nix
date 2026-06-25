- implement my own ssh keyring of keys where upon initialization of public key a commit is made to the flake into an attribute set of its hostname to the public key. other hosts can select which hosts they wish to allow (this can be done from the get go even before the key is committed) to ssh into them. then these are added to authorized keys for ssh by the flake (if present after initial machine setup and its commit updates the other hosts). so flow is -> add host to config -> add that host to allowed ssh accessers to other hosts -> bring up new host -> that hosts user interactive initialization script (which also sets up sops) also adds/commits its public key and pushes -> other hosts pull and update -> when tehy rebuild now there is a public key there and they can add it to known hosts successfully.

- find an way to find location of the flake so i dont have to hard code commands that require it.

- setup home
  - clone flake appropriately into brpol
  - setup desktop background revolving bing

- nixos-anywhere for bootstrapping new systems
  - can it do hardware config?
  - can it run my brpol-setup script?
  - can it do darwin?

- google drive setup

- it looks like we can get at ssh keys from nix, lets make the server accessible by public key from my other devices, and my desktop accessible via laptop

- nvim lazyvim, how deep do i go?

- setup ds9
  - ssh from other machines
  - ds9 wireguard

- ncc 1701e config (steam, etc)
  - hardware config? how?
  - swap?

- streaming box?
