
# About

## main/
- My config files for various programs, such as:
    - fish
    - bash
    - alacritty
    - ...

## link.lua

- A simple systemlink / hardlink farming script.
- Inspired by GNU Stow.

Commands:
```markdown
./link backup            -> _Creates_ an isolated _backup_ of current files in root path.
./link link   *dir*        -> __Links__ files from *dir* into root path (requires directory).
./link restore *dir*       -> __Copies__ files back from *dir* into root path (requires directory).
./link remove            -> __Removes__ all files/links declared at target root paths.

```









